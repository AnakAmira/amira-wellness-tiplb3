from typing import List, Optional
from datetime import datetime
import uuid

from pydantic import Field, validator

from .common import BaseSchema, IDSchema, TimestampSchema, PaginatedResponse
from ..models.notification import NotificationType


class NotificationBase(BaseSchema):
    """
    Base schema for notification data with common fields
    """
    notification_type: NotificationType = Field(
        description="Type of notification"
    )
    title: str = Field(
        description="Notification title"
    )
    content: str = Field(
        description="Notification content"
    )
    is_read: bool = Field(
        default=False,
        description="Whether the notification has been read"
    )
    read_at: Optional[datetime] = Field(
        default=None,
        description="Timestamp when the notification was read"
    )
    is_sent: bool = Field(
        default=False,
        description="Whether the notification has been sent"
    )
    sent_at: Optional[datetime] = Field(
        default=None,
        description="Timestamp when the notification was sent"
    )
    scheduled_for: Optional[datetime] = Field(
        default=None,
        description="Timestamp when the notification is scheduled to be sent"
    )
    related_entity_type: Optional[str] = Field(
        default=None,
        description="Type of entity related to this notification (e.g., achievement, voice_journal)"
    )
    related_entity_id: Optional[str] = Field(
        default=None,
        description="ID of the entity related to this notification"
    )


class NotificationCreate(NotificationBase):
    """
    Schema for creating a new notification
    """
    user_id: uuid.UUID = Field(
        description="ID of the user to receive the notification"
    )


class Notification(NotificationBase, IDSchema, TimestampSchema):
    """
    Schema for notification response with all fields
    """
    user_id: uuid.UUID = Field(
        description="ID of the user who received the notification"
    )


class NotificationUpdate(BaseSchema):
    """
    Schema for updating notification status
    """
    is_read: Optional[bool] = Field(
        default=None,
        description="Whether the notification has been read"
    )


class NotificationList(PaginatedResponse[Notification]):
    """
    Paginated list of notifications
    """
    pass


class NotificationPreferencesBase(BaseSchema):
    """
    Base schema for notification preferences
    """
    daily_reminders: bool = Field(
        default=True,
        description="Receive daily reminders"
    )
    streak_reminders: bool = Field(
        default=True,
        description="Receive streak reminders"
    )
    achievements: bool = Field(
        default=True,
        description="Receive achievement notifications"
    )
    affirmations: bool = Field(
        default=True,
        description="Receive daily affirmations"
    )
    wellness_tips: bool = Field(
        default=True,
        description="Receive wellness tips"
    )
    app_updates: bool = Field(
        default=True,
        description="Receive app update notifications"
    )


class NotificationPreferences(NotificationPreferencesBase, IDSchema, TimestampSchema):
    """
    Schema for notification preferences response
    """
    user_id: uuid.UUID = Field(
        description="ID of the user these preferences belong to"
    )


class NotificationPreferencesCreate(NotificationPreferencesBase):
    """
    Schema for creating notification preferences
    """
    user_id: uuid.UUID = Field(
        description="ID of the user these preferences belong to"
    )


class NotificationPreferencesUpdate(BaseSchema):
    """
    Schema for updating notification preferences
    """
    daily_reminders: Optional[bool] = Field(
        default=None,
        description="Receive daily reminders"
    )
    streak_reminders: Optional[bool] = Field(
        default=None,
        description="Receive streak reminders"
    )
    achievements: Optional[bool] = Field(
        default=None,
        description="Receive achievement notifications"
    )
    affirmations: Optional[bool] = Field(
        default=None,
        description="Receive daily affirmations"
    )
    wellness_tips: Optional[bool] = Field(
        default=None,
        description="Receive wellness tips"
    )
    app_updates: Optional[bool] = Field(
        default=None,
        description="Receive app update notifications"
    )
    
    @validator('*', pre=True)
    @classmethod
    def validate_at_least_one_field(cls, values):
        """
        Validates that at least one preference field is provided
        
        Args:
            cls: Class reference
            values: Dictionary of field values
            
        Returns:
            Validated values
        """
        # Check if any values are provided (not None)
        has_values = any(value is not None for value in values.values())
        
        if not has_values:
            raise ValueError("At least one notification preference must be provided")
        
        return values