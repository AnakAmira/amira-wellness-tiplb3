import json
import uuid
from datetime import datetime

import pytest  # pytest 7.0+

from ..conftest import app_client, auth_headers, premium_auth_headers
from ..fixtures.users import regular_user
from ..fixtures.database import test_db
from ...app.models.notification import NotificationType, Notification, NotificationPreference
from ...app.services.notification import notification_service

# API endpoint prefix
NOTIFICATIONS_PREFIX = '/notifications'

@pytest.mark.integration
def test_get_notifications_empty(app_client, auth_headers):
    """Test retrieving notifications when user has no notifications."""
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 0
    assert data["total"] == 0

@pytest.mark.integration
def test_get_notifications(app_client, auth_headers, test_db, regular_user):
    """Test retrieving notifications when user has notifications."""
    # Create a few test notifications
    notification1 = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Test Notification 1",
        content="This is a test notification 1"
    )
    
    notification2 = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.STREAK_REMINDER,
        title="Test Notification 2",
        content="This is a test notification 2"
    )
    
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 2
    assert data["total"] == 2
    
    # Verify notification fields
    assert data["items"][0]["title"] in ["Test Notification 1", "Test Notification 2"]
    assert data["items"][1]["title"] in ["Test Notification 1", "Test Notification 2"]
    assert "id" in data["items"][0]
    assert "created_at" in data["items"][0]
    assert "notification_type" in data["items"][0]
    assert "is_read" in data["items"][0]

@pytest.mark.integration
def test_get_notifications_pagination(app_client, auth_headers, test_db, regular_user):
    """Test notification pagination."""
    # Create several notifications for testing pagination
    for i in range(5):
        notification_service.create_notification(
            db=test_db,
            user_id=regular_user.id,
            notification_type=NotificationType.DAILY_REMINDER,
            title=f"Notification {i+1}",
            content=f"Content {i+1}"
        )
    
    # Get first page (2 items)
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}?limit=2&skip=0", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 2
    assert data["total"] == 5
    first_page_ids = [item["id"] for item in data["items"]]
    
    # Get second page (2 items)
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}?limit=2&skip=2", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 2
    second_page_ids = [item["id"] for item in data["items"]]
    
    # Ensure no overlap between pages
    assert not set(first_page_ids).intersection(set(second_page_ids))

@pytest.mark.integration
def test_get_notifications_unread_only(app_client, auth_headers, test_db, regular_user):
    """Test retrieving only unread notifications."""
    # Create read and unread notifications
    notification1 = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Read Notification",
        content="This is a read notification"
    )
    
    notification2 = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.STREAK_REMINDER,
        title="Unread Notification",
        content="This is an unread notification"
    )
    
    # Mark one notification as read
    notification_service.mark_notification_as_read(
        db=test_db,
        notification_id=notification1.id
    )
    
    # Get unread notifications only
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}?unread_only=true", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 1
    assert data["total"] == 1
    assert data["items"][0]["is_read"] == False
    assert data["items"][0]["title"] == "Unread Notification"

@pytest.mark.integration
def test_get_notification_by_id(app_client, auth_headers, test_db, regular_user):
    """Test retrieving a specific notification by ID."""
    # Create a test notification
    notification = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Test Notification",
        content="This is a test notification"
    )
    
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}/{notification.id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(notification.id)
    assert data["title"] == "Test Notification"
    assert data["content"] == "This is a test notification"
    assert data["notification_type"] == NotificationType.DAILY_REMINDER.name

@pytest.mark.integration
def test_get_notification_not_found(app_client, auth_headers):
    """Test retrieving a non-existent notification."""
    random_uuid = str(uuid.uuid4())
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}/{random_uuid}", headers=auth_headers)
    assert response.status_code == 404
    data = response.json()
    assert "detail" in data  # Error details should be in the response

@pytest.mark.integration
def test_get_notification_unauthorized(app_client, auth_headers, premium_auth_headers, test_db, regular_user):
    """Test retrieving another user's notification."""
    # Create a notification for the regular user
    notification = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Test Notification",
        content="This is a test notification"
    )
    
    # Try to access it with a different user's credentials
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}/{notification.id}", headers=premium_auth_headers)
    assert response.status_code == 403
    data = response.json()
    assert "detail" in data  # Permission denied error details

@pytest.mark.integration
def test_mark_notification_as_read(app_client, auth_headers, test_db, regular_user):
    """Test marking a notification as read."""
    # Create an unread notification
    notification = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Test Notification",
        content="This is a test notification"
    )
    assert notification.is_read == False
    
    # Mark it as read
    update_data = {"is_read": True}
    response = app_client.patch(
        f"{NOTIFICATIONS_PREFIX}/{notification.id}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["is_read"] == True
    assert data["read_at"] is not None
    
    # Verify in database
    updated_notification = notification_service.get_notification(
        db=test_db,
        notification_id=notification.id
    )
    assert updated_notification.is_read == True
    assert updated_notification.read_at is not None

@pytest.mark.integration
def test_mark_all_as_read(app_client, auth_headers, test_db, regular_user):
    """Test marking all notifications as read."""
    # Create several unread notifications
    for i in range(3):
        notification_service.create_notification(
            db=test_db,
            user_id=regular_user.id,
            notification_type=NotificationType.DAILY_REMINDER,
            title=f"Notification {i+1}",
            content=f"Content {i+1}"
        )
    
    # Mark all as read
    response = app_client.post(
        f"{NOTIFICATIONS_PREFIX}/mark-all-read",
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "count" in data
    
    # Verify all are marked as read
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}?unread_only=true", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 0
    assert data["total"] == 0

@pytest.mark.integration
def test_count_unread_notifications(app_client, auth_headers, test_db, regular_user):
    """Test counting unread notifications."""
    # Create a mix of read and unread notifications
    notification1 = notification_service.create_notification(
        db=test_db,
        user_id=regular_user.id,
        notification_type=NotificationType.DAILY_REMINDER,
        title="Read Notification",
        content="This is a read notification"
    )
    
    for i in range(2):
        notification_service.create_notification(
            db=test_db,
            user_id=regular_user.id,
            notification_type=NotificationType.STREAK_REMINDER,
            title=f"Unread Notification {i+1}",
            content=f"This is unread notification {i+1}"
        )
    
    # Mark one notification as read
    notification_service.mark_notification_as_read(
        db=test_db,
        notification_id=notification1.id
    )
    
    # Get unread count
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}/unread/count", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 2

@pytest.mark.integration
def test_get_notification_preferences(app_client, auth_headers, test_db, regular_user):
    """Test retrieving notification preferences."""
    # Ensure notification preferences exist for regular_user
    preferences = notification_service.get_notification_preferences(
        db=test_db,
        user_id=regular_user.id
    )
    
    response = app_client.get(f"{NOTIFICATIONS_PREFIX}/preferences", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    
    # Check all preference fields exist
    assert "daily_reminders" in data
    assert "streak_reminders" in data
    assert "achievements" in data
    assert "affirmations" in data
    assert "wellness_tips" in data
    assert "app_updates" in data
    
    # Check user_id in response matches regular_user.id
    assert data["user_id"] == str(regular_user.id)

@pytest.mark.integration
def test_update_notification_preferences(app_client, auth_headers, test_db, regular_user):
    """Test updating notification preferences."""
    # Ensure notification preferences exist for regular_user
    preferences = notification_service.get_notification_preferences(
        db=test_db,
        user_id=regular_user.id
    )
    
    # Update all preferences to the opposite of their current values
    update_data = {
        "daily_reminders": not preferences.daily_reminders,
        "streak_reminders": not preferences.streak_reminders,
        "achievements": not preferences.achievements,
        "affirmations": not preferences.affirmations,
        "wellness_tips": not preferences.wellness_tips,
        "app_updates": not preferences.app_updates
    }
    
    response = app_client.patch(
        f"{NOTIFICATIONS_PREFIX}/preferences",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    
    # Verify all values were updated
    for key, value in update_data.items():
        assert data[key] == value
    
    # Verify in database
    updated_preferences = notification_service.get_notification_preferences(
        db=test_db,
        user_id=regular_user.id
    )
    for key, value in update_data.items():
        assert getattr(updated_preferences, key) == value

@pytest.mark.integration
def test_update_notification_preferences_partial(app_client, auth_headers, test_db, regular_user):
    """Test partial update of notification preferences."""
    # Get current notification preferences
    preferences = notification_service.get_notification_preferences(
        db=test_db,
        user_id=regular_user.id
    )
    
    # Update only one preference
    update_data = {
        "daily_reminders": not preferences.daily_reminders
    }
    
    response = app_client.patch(
        f"{NOTIFICATIONS_PREFIX}/preferences",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    
    # Verify the updated field changed
    assert data["daily_reminders"] == update_data["daily_reminders"]
    
    # Verify other fields retained their original values
    assert data["streak_reminders"] == preferences.streak_reminders
    assert data["achievements"] == preferences.achievements
    assert data["affirmations"] == preferences.affirmations
    assert data["wellness_tips"] == preferences.wellness_tips
    assert data["app_updates"] == preferences.app_updates

@pytest.mark.integration
def test_update_notification_preferences_invalid(app_client, auth_headers):
    """Test updating notification preferences with invalid data."""
    # Empty update should be invalid
    update_data = {}
    
    response = app_client.patch(
        f"{NOTIFICATIONS_PREFIX}/preferences",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data  # Error details about requiring at least one field