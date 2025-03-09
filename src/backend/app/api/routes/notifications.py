"""
FastAPI router for notification endpoints in the Amira Wellness application.
Provides API routes for retrieving, managing, and updating user notifications and notification preferences.
Implements endpoints for marking notifications as read, retrieving unread notification counts, and managing notification settings.
"""
import typing
import uuid

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, Body
from sqlalchemy.orm import Session  # sqlalchemy 2.0+
from fastapi_limiter import RateLimiter  # fastapi-limiter 0.1.5+

# Internal imports
from ..deps import get_db, get_current_user, get_client_rate_limit_key
from ..models.user import User
from ..schemas.notification import Notification, NotificationUpdate, NotificationList, NotificationPreferences, NotificationPreferencesUpdate
from ..services import notification as notification_service
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException, PermissionDeniedException

# Initialize logger
logger = get_logger(__name__)

# Define API router for notifications
router = APIRouter(prefix='/notifications', tags=['notifications'])


@router.get('/', response_model=NotificationList)
@typing.no_type_check  # Remove type checking for this line
async def get_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    unread_only: typing.Optional[bool] = Query(default=False, description="Filter to only unread notifications"),
    skip: int = Query(default=0, ge=0, description="Skip records for pagination"),
    limit: int = Query(default=100, le=100, description="Limit records per page"),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=100, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> NotificationList:
    """
    Get notifications for the current user with optional filtering
    """
    logger.info(f"Getting notifications for user {current_user.id}, unread_only={unread_only}, skip={skip}, limit={limit}")
    notifications, total = notification_service.get_user_notifications(
        db=db,
        user_id=current_user.id,
        unread_only=unread_only,
        skip=skip,
        limit=limit
    )
    return NotificationList(items=notifications, total=total, page=skip // limit + 1, page_size=limit)


@router.get('/{notification_id}', response_model=Notification)
@typing.no_type_check  # Remove type checking for this line
async def get_notification(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    notification_id: uuid.UUID = Path(description="Notification ID"),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=100, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> Notification:
    """
    Get a specific notification by ID
    """
    logger.info(f"Getting notification {notification_id} for user {current_user.id}")
    notification_obj = notification_service.get_notification(db=db, notification_id=notification_id)

    if not notification_obj:
        raise ResourceNotFoundException(resource_type="notification", resource_id=notification_id)

    if notification_obj.user_id != current_user.id:
        raise PermissionDeniedException(message="You do not have permission to access this notification")

    return notification_obj


@router.patch('/{notification_id}', response_model=Notification)
@typing.no_type_check  # Remove type checking for this line
async def update_notification(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    notification_id: uuid.UUID = Path(description="Notification ID"),
    notification_update: NotificationUpdate = Body(description="Update notification data"),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=100, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> Notification:
    """
    Update a notification (mark as read)
    """
    logger.info(f"Updating notification {notification_id} for user {current_user.id}")
    notification_obj = notification_service.get_notification(db=db, notification_id=notification_id)

    if not notification_obj:
        raise ResourceNotFoundException(resource_type="notification", resource_id=notification_id)

    if notification_obj.user_id != current_user.id:
        raise PermissionDeniedException(message="You do not have permission to update this notification")

    if notification_update.is_read is True:
        updated_notification = notification_service.mark_notification_as_read(db=db, notification_id=notification_id)
        return updated_notification
    
    # If no update is requested, return the original notification
    return notification_obj


@router.post('/mark-all-read', response_model=dict)
@typing.no_type_check  # Remove type checking for this line
async def mark_all_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=50, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> dict:
    """
    Mark all notifications for the current user as read
    """
    logger.info(f"Marking all notifications as read for user {current_user.id}")
    count = notification_service.mark_all_as_read(db=db, user_id=current_user.id)
    return {"message": f"Marked {count} notifications as read"}


@router.get('/unread/count', response_model=dict)
@typing.no_type_check  # Remove type checking for this line
async def count_unread(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=100, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> dict:
    """
    Count unread notifications for the current user
    """
    logger.info(f"Counting unread notifications for user {current_user.id}")
    count = notification_service.count_unread_notifications(db=db, user_id=current_user.id)
    return {"unread_count": count}


@router.get('/preferences', response_model=NotificationPreferences)
@typing.no_type_check  # Remove type checking for this line
async def get_notification_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=100, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> NotificationPreferences:
    """
    Get notification preferences for the current user
    """
    logger.info(f"Getting notification preferences for user {current_user.id}")
    preferences = notification_service.get_notification_preferences(db=db, user_id=current_user.id)
    return preferences


@router.patch('/preferences', response_model=NotificationPreferences)
@typing.no_type_check  # Remove type checking for this line
async def update_notification_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    preferences: NotificationPreferencesUpdate = Body(description="Updated notification preferences"),
    rate_limiter: RateLimiter = Depends(RateLimiter(times=50, seconds=60, key_func=get_client_rate_limit_key))  # fastapi-limiter 0.1.5+
) -> NotificationPreferences:
    """
    Update notification preferences for the current user
    """
    logger.info(f"Updating notification preferences for user {current_user.id}")
    preferences_data = preferences.model_dump(exclude_unset=True)
    updated_preferences = notification_service.update_notification_preferences(
        db=db,
        user_id=current_user.id,
        preferences_data=preferences_data
    )
    return updated_preferences