import typing
from datetime import datetime
import json
import requests
import firebase_admin
from firebase_admin import credentials, messaging
import apns2
from apns2.client import APNsClient
from apns2.payload import Payload
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from ...core.logging import get_logger
from ...crud.notification import notification
from ...crud.device import device
from ...models.device import DevicePlatform
from ...models.notification import Notification, NotificationType
from ...core.config import settings
from ...db.session import get_db

# Initialize logger
logger = get_logger(__name__)

# Global variables
fcm_initialized = False
apns_client = None

def initialize_fcm() -> bool:
    """
    Initialize Firebase Cloud Messaging for Android push notifications
    
    Returns:
        bool: True if initialization successful, False otherwise
    """
    global fcm_initialized
    
    # Return True if already initialized
    if fcm_initialized:
        return True
    
    try:
        # Initialize Firebase Admin SDK
        firebase_admin.initialize_app(credentials.Certificate(settings.FCM_API_KEY))
        fcm_initialized = True
        logger.info("Firebase Cloud Messaging initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Cloud Messaging: {str(e)}")
        return False

def initialize_apns() -> bool:
    """
    Initialize Apple Push Notification Service for iOS push notifications
    
    Returns:
        bool: True if initialization successful, False otherwise
    """
    global apns_client
    
    # Return True if already initialized
    if apns_client is not None:
        return True
    
    try:
        # Initialize APNS client
        apns_client = APNsClient(
            credential=settings.APNS_KEY_FILE,
            use_sandbox=settings.ENVIRONMENT != "production",
            key_id=settings.APNS_KEY_ID,
            team_id=settings.APNS_TEAM_ID
        )
        logger.info("Apple Push Notification Service initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Apple Push Notification Service: {str(e)}")
        return False

@retry(
    stop=stop_after_attempt(3), 
    wait=wait_exponential(multiplier=1, min=1, max=10), 
    retry=retry_if_exception_type(requests.RequestException)
)
def send_fcm_notification(device_tokens: typing.List[str], title: str, body: str, data: dict) -> dict:
    """
    Send push notification to Android devices using Firebase Cloud Messaging
    
    Args:
        device_tokens: List of FCM device tokens
        title: Notification title
        body: Notification body
        data: Additional data payload
        
    Returns:
        dict: Result of the notification delivery attempt
    """
    if not initialize_fcm():
        logger.error("Failed to send FCM notification: Firebase not initialized")
        return {"success": 0, "failure": len(device_tokens)}
    
    try:
        # Create a multicast message
        message = messaging.MulticastMessage(
            tokens=device_tokens,
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data
        )
        
        # Send the message
        response = messaging.send_multicast(message)
        
        logger.info(f"FCM notification sent: {response.success_count} success, {response.failure_count} failure")
        
        return {
            "success": response.success_count,
            "failure": response.failure_count
        }
    except Exception as e:
        logger.error(f"Error sending FCM notification: {str(e)}")
        return {"success": 0, "failure": len(device_tokens)}

@retry(
    stop=stop_after_attempt(3), 
    wait=wait_exponential(multiplier=1, min=1, max=10), 
    retry=retry_if_exception_type(Exception)
)
def send_apns_notification(device_tokens: typing.List[str], title: str, body: str, data: dict) -> dict:
    """
    Send push notification to iOS devices using Apple Push Notification Service
    
    Args:
        device_tokens: List of APNS device tokens
        title: Notification title
        body: Notification body
        data: Additional data payload
        
    Returns:
        dict: Result of the notification delivery attempt
    """
    if not initialize_apns():
        logger.error("Failed to send APNS notification: APNS client not initialized")
        return {"success": 0, "failure": len(device_tokens)}
    
    try:
        # Create the payload
        payload = Payload(
            alert={
                "title": title,
                "body": body
            },
            custom=data
        )
        
        # Track successes and failures
        success_count = 0
        failure_count = 0
        
        # Send to each device token
        for token in device_tokens:
            try:
                # Send notification
                apns_client.send_notification(
                    token,
                    payload,
                    topic=settings.APNS_BUNDLE_ID
                )
                success_count += 1
            except Exception as e:
                logger.warning(f"Failed to send APNS notification to token {token}: {str(e)}")
                failure_count += 1
        
        logger.info(f"APNS notification sent: {success_count} success, {failure_count} failure")
        
        return {
            "success": success_count,
            "failure": failure_count
        }
    except Exception as e:
        logger.error(f"Error sending APNS notification: {str(e)}")
        return {"success": 0, "failure": len(device_tokens)}

def send_push_notification(user_id: typing.UUID, title: str, body: str, data: dict) -> dict:
    """
    Send push notification to user devices based on platform
    
    Args:
        user_id: User ID to send notification to
        title: Notification title
        body: Notification body
        data: Additional data payload
        
    Returns:
        dict: Combined result of notification delivery attempts
    """
    db = next(get_db())
    
    # Get all devices with push tokens for the user
    user_devices = device.get_devices_with_push_token(db, user_id)
    
    if not user_devices:
        logger.info(f"No devices with push tokens found for user {user_id}")
        return {"android": {"success": 0, "failure": 0}, "ios": {"success": 0, "failure": 0}}
    
    # Group device tokens by platform
    android_tokens = []
    ios_tokens = []
    
    for user_device in user_devices:
        if user_device.platform == DevicePlatform.ANDROID and user_device.push_token:
            android_tokens.append(user_device.push_token)
        elif user_device.platform == DevicePlatform.IOS and user_device.push_token:
            ios_tokens.append(user_device.push_token)
    
    # Initialize result counters
    results = {
        "android": {"success": 0, "failure": 0},
        "ios": {"success": 0, "failure": 0}
    }
    
    # Send to Android devices
    if android_tokens:
        android_result = send_fcm_notification(android_tokens, title, body, data)
        results["android"] = android_result
    
    # Send to iOS devices
    if ios_tokens:
        ios_result = send_apns_notification(ios_tokens, title, body, data)
        results["ios"] = ios_result
    
    # Log the combined results
    total_success = results["android"]["success"] + results["ios"]["success"]
    total_failure = results["android"]["failure"] + results["ios"]["failure"]
    logger.info(f"Push notification results for user {user_id}: {total_success} success, {total_failure} failure")
    
    return results

def process_notification(notification_obj: Notification) -> bool:
    """
    Process a single notification for delivery
    
    Args:
        notification_obj: Notification object to process
        
    Returns:
        bool: True if notification was processed successfully, False otherwise
    """
    try:
        # Extract notification details
        user_id = notification_obj.user_id
        title = notification_obj.title
        content = notification_obj.content
        notification_type = notification_obj.notification_type
        
        # Prepare notification data dictionary with notification_id and type
        notification_data = {
            "notification_id": str(notification_obj.id),
            "notification_type": notification_type.name
        }
        
        # Try to send push notification to user's devices
        send_push_notification(user_id, title, content, notification_data)
        
        # Mark notification as sent regardless of push delivery result
        # (notification is considered delivered even if devices couldn't receive it)
        db = next(get_db())
        notification.mark_as_sent(db, notification_obj.id)
        
        logger.info(f"Processed notification {notification_obj.id} for user {user_id}")
        return True
    except Exception as e:
        logger.error(f"Error processing notification {notification_obj.id}: {str(e)}")
        return False

def process_notifications(batch_size: int = None) -> dict:
    """
    Process and deliver pending notifications in batches
    
    Args:
        batch_size: Maximum number of notifications to process
        
    Returns:
        dict: Processing results including counts of processed, successful, and failed notifications
    """
    # Use default batch size from settings if not specified
    if batch_size is None:
        batch_size = settings.NOTIFICATION_BATCH_SIZE
    
    db = next(get_db())
    
    # Retrieve due notifications up to batch_size limit
    notifications_to_process = notification.get_due_notifications(db, limit=batch_size)
    
    logger.info(f"Processing {len(notifications_to_process)} notifications")
    
    # Initialize counters for processed, successful, and failed notifications
    processed_count = 0
    success_count = 0
    failed_count = 0
    
    # For each notification, call process_notification
    for notification_obj in notifications_to_process:
        processed_count += 1
        
        # Process the notification and update counters based on result
        if process_notification(notification_obj):
            success_count += 1
        else:
            failed_count += 1
    
    logger.info(f"Notification processing complete: {processed_count} processed, {success_count} successful, {failed_count} failed")
    
    # Return result dictionary with notification processing statistics
    return {
        "processed": processed_count,
        "successful": success_count,
        "failed": failed_count
    }