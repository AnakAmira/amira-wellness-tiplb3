import enum
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship

from .base import BaseModel

# Define notification types as an enum
NotificationType = enum.Enum('NotificationType', [
    'DAILY_REMINDER',
    'STREAK_REMINDER',
    'ACHIEVEMENT',
    'AFFIRMATION',
    'WELLNESS_TIP',
    'APP_UPDATE'
])

class Notification(BaseModel):
    """
    SQLAlchemy model representing a notification in the Amira Wellness application.
    Stores notification details, delivery status, and related entity references.
    """
    # Foreign key to user
    user_id = Column(ForeignKey('users.id'), nullable=False)
    
    # Notification type and content
    notification_type = Column(Enum(NotificationType), nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(String(1024), nullable=False)
    
    # Read status
    is_read = Column(Boolean, default=False, nullable=False)
    read_at = Column(DateTime, nullable=True)
    
    # Delivery status
    is_sent = Column(Boolean, default=False, nullable=False)
    sent_at = Column(DateTime, nullable=True)
    
    # Scheduling
    scheduled_for = Column(DateTime, nullable=True)
    
    # Related entity (for contextual notifications)
    related_entity_type = Column(String(255), nullable=True)
    related_entity_id = Column(String(255), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="notifications")
    
    def mark_as_read(self):
        """
        Marks the notification as read.
        """
        self.is_read = True
        self.read_at = datetime.utcnow()
    
    def mark_as_sent(self):
        """
        Marks the notification as sent.
        """
        self.is_sent = True
        self.sent_at = datetime.utcnow()
    
    def is_due(self):
        """
        Checks if the notification is due for delivery.
        
        Returns:
            bool: True if the notification should be sent now, False otherwise
        """
        return not self.is_sent and (self.scheduled_for is None or self.scheduled_for <= datetime.utcnow())
    
    def is_scheduled(self):
        """
        Checks if the notification is scheduled for future delivery.
        
        Returns:
            bool: True if scheduled_for is in the future, False otherwise
        """
        return self.scheduled_for is not None and self.scheduled_for > datetime.utcnow()


class NotificationPreference(BaseModel):
    """
    SQLAlchemy model representing user notification preferences.
    Allows users to control which types of notifications they receive.
    """
    # Foreign key to user
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    
    # Notification preferences by type
    daily_reminders = Column(Boolean, default=True, nullable=False)
    streak_reminders = Column(Boolean, default=True, nullable=False)
    achievements = Column(Boolean, default=True, nullable=False)
    affirmations = Column(Boolean, default=True, nullable=False)
    wellness_tips = Column(Boolean, default=True, nullable=False)
    app_updates = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="notification_preferences")
    
    def is_enabled(self, notification_type):
        """
        Checks if a specific notification type is enabled.
        
        Args:
            notification_type (NotificationType): The notification type to check
            
        Returns:
            bool: True if the notification type is enabled, False otherwise
        """
        type_to_preference = {
            NotificationType.DAILY_REMINDER: self.daily_reminders,
            NotificationType.STREAK_REMINDER: self.streak_reminders,
            NotificationType.ACHIEVEMENT: self.achievements,
            NotificationType.AFFIRMATION: self.affirmations,
            NotificationType.WELLNESS_TIP: self.wellness_tips,
            NotificationType.APP_UPDATE: self.app_updates
        }
        
        return type_to_preference.get(notification_type, False)