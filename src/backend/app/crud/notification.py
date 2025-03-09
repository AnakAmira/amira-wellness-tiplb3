from datetime import datetime
import uuid
from typing import List, Optional, Tuple

from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import Session  # sqlalchemy 2.0+

from .base import CRUDBase
from ..models.notification import Notification, NotificationPreference, NotificationType
from ..schemas.notification import NotificationCreate, NotificationUpdate, NotificationPreferencesCreate, NotificationPreferencesUpdate
from ..core.logging import get_logger

# Initialize logger
logger = get_logger(__name__)

class CRUDNotification(CRUDBase[Notification, NotificationCreate, NotificationUpdate]):
    """
    CRUD operations for notifications
    """
    
    def __init__(self):
        """
        Initialize the notification CRUD operations
        """
        super().__init__(Notification)
        self.logger = logger
    
    def create_for_user(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        notification_type: NotificationType, 
        title: str, 
        content: str,
        scheduled_for: Optional[datetime] = None,
        related_entity_type: Optional[str] = None,
        related_entity_id: Optional[str] = None
    ) -> Notification:
        """
        Create a notification for a specific user
        
        Args:
            db: Database session
            user_id: User ID
            notification_type: Type of notification
            title: Notification title
            content: Notification content
            scheduled_for: When to send the notification (None for immediate)
            related_entity_type: Type of related entity (e.g., 'achievement')
            related_entity_id: ID of related entity
            
        Returns:
            The created notification
        """
        notification_data = {
            "user_id": user_id,
            "notification_type": notification_type,
            "title": title,
            "content": content,
            "is_read": False,
            "is_sent": False,
            "scheduled_for": scheduled_for,
            "related_entity_type": related_entity_type,
            "related_entity_id": related_entity_id
        }
        
        notification_in = NotificationCreate(**notification_data)
        notification = self.create(db, obj_in=notification_in)
        
        self.logger.info(
            f"Created notification for user {user_id}, type {notification_type}, title: {title}"
        )
        
        return notification
    
    def get_by_user(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        unread_only: bool = False,
        skip: int = 0, 
        limit: int = 100
    ) -> Tuple[List[Notification], int]:
        """
        Get notifications for a specific user with optional filtering
        
        Args:
            db: Database session
            user_id: User ID
            unread_only: Only return unread notifications
            skip: Number of records to skip for pagination
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (notifications, total_count)
        """
        # Base query filtering by user_id
        query = select(Notification).where(Notification.user_id == user_id)
        
        # Add unread filter if requested
        if unread_only:
            query = query.where(Notification.is_read == False)
            
        # Get total count before pagination
        count_query = select(func.count()).select_from(query.subquery())
        total = db.execute(count_query).scalar_one()
        
        # Apply pagination
        query = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit)
        
        # Execute query
        notifications = db.execute(query).scalars().all()
        
        return list(notifications), total
    
    def get_due_notifications(self, db: Session, limit: int = 100) -> List[Notification]:
        """
        Get notifications that are due for delivery
        
        Args:
            db: Database session
            limit: Maximum number of notifications to return
            
        Returns:
            List of due notifications
        """
        now = datetime.utcnow()
        
        # Query for notifications that are not sent and either have no scheduled time
        # or are scheduled for a time in the past
        query = select(Notification).where(
            and_(
                Notification.is_sent == False,
                or_(
                    Notification.scheduled_for == None,
                    Notification.scheduled_for <= now
                )
            )
        ).limit(limit)
        
        notifications = db.execute(query).scalars().all()
        return list(notifications)
    
    def mark_as_read(self, db: Session, notification_id: uuid.UUID) -> Notification:
        """
        Mark a notification as read
        
        Args:
            db: Database session
            notification_id: Notification ID
            
        Returns:
            The updated notification
        """
        notification = self.get(db, notification_id)
        if notification:
            notification.mark_as_read()
            db.commit()
            self.logger.debug(f"Marked notification {notification_id} as read")
        return notification
    
    def mark_as_sent(self, db: Session, notification_id: uuid.UUID) -> Notification:
        """
        Mark a notification as sent
        
        Args:
            db: Database session
            notification_id: Notification ID
            
        Returns:
            The updated notification
        """
        notification = self.get(db, notification_id)
        if notification:
            notification.mark_as_sent()
            db.commit()
            self.logger.debug(f"Marked notification {notification_id} as sent")
        return notification
    
    def mark_all_as_read(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Mark all notifications for a user as read
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Number of notifications marked as read
        """
        # Get all unread notifications for the user
        query = select(Notification).where(
            and_(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        )
        notifications = db.execute(query).scalars().all()
        
        # Mark each as read
        count = 0
        for notification in notifications:
            notification.mark_as_read()
            count += 1
        
        db.commit()
        self.logger.info(f"Marked {count} notifications as read for user {user_id}")
        return count
    
    def count_unread(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Count unread notifications for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Count of unread notifications
        """
        query = select(func.count()).select_from(Notification).where(
            and_(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        )
        count = db.execute(query).scalar_one()
        return count
    
    def delete_for_user(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Delete all notifications for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Number of notifications deleted
        """
        from sqlalchemy import delete
        
        stmt = delete(Notification).where(Notification.user_id == user_id)
        result = db.execute(stmt)
        db.commit()
        
        count = result.rowcount
        self.logger.info(f"Deleted {count} notifications for user {user_id}")
        return count


class CRUDNotificationPreference(CRUDBase[NotificationPreference, NotificationPreferencesCreate, NotificationPreferencesUpdate]):
    """
    CRUD operations for notification preferences
    """
    
    def __init__(self):
        """
        Initialize the notification preference CRUD operations
        """
        super().__init__(NotificationPreference)
        self.logger = logger
    
    def get_by_user(self, db: Session, user_id: uuid.UUID) -> Optional[NotificationPreference]:
        """
        Get notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User's notification preferences or None if not found
        """
        query = select(NotificationPreference).where(NotificationPreference.user_id == user_id)
        result = db.execute(query).scalars().first()
        return result
    
    def create_for_user(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        preferences_data: NotificationPreferencesCreate
    ) -> NotificationPreference:
        """
        Create notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Notification preferences data
            
        Returns:
            The created notification preferences
        """
        # Check if preferences already exist
        existing = self.get_by_user(db, user_id)
        if existing:
            self.logger.debug(f"Notification preferences already exist for user {user_id}")
            return existing
        
        # Create a new preferences object with the user_id
        preferences_data_dict = preferences_data.model_dump()
        preferences_data_dict["user_id"] = user_id
        
        preferences_in = NotificationPreferencesCreate(**preferences_data_dict)
        preferences = self.create(db, obj_in=preferences_in)
        
        self.logger.info(f"Created notification preferences for user {user_id}")
        return preferences
    
    def update_for_user(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        preferences_data: NotificationPreferencesUpdate
    ) -> NotificationPreference:
        """
        Update notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Updated notification preferences data
            
        Returns:
            The updated notification preferences
        """
        # Get existing preferences
        preferences = self.get_by_user(db, user_id)
        
        # Create if not exist
        if not preferences:
            self.logger.debug(f"Creating new notification preferences for user {user_id}")
            preferences_create = NotificationPreferencesCreate(user_id=user_id, **preferences_data.model_dump(exclude_unset=True))
            return self.create(db, obj_in=preferences_create)
        
        # Update existing preferences
        updated_preferences = self.update(db, db_obj=preferences, obj_in=preferences_data)
        self.logger.info(f"Updated notification preferences for user {user_id}")
        
        return updated_preferences
    
    def is_enabled_for_user(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        notification_type: NotificationType
    ) -> bool:
        """
        Check if a notification type is enabled for a user
        
        Args:
            db: Database session
            user_id: User ID
            notification_type: Type of notification to check
            
        Returns:
            True if the notification type is enabled, False otherwise
        """
        preferences = self.get_by_user(db, user_id)
        
        # If preferences don't exist, use defaults (all enabled except wellness tips)
        if not preferences:
            # Most notification types are enabled by default
            default_enabled = notification_type not in [NotificationType.WELLNESS_TIP, NotificationType.APP_UPDATE]
            return default_enabled
            
        # Check if the specific notification type is enabled
        return preferences.is_enabled(notification_type)
    
    def delete_for_user(self, db: Session, user_id: uuid.UUID) -> bool:
        """
        Delete notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            True if preferences were deleted, False if not found
        """
        preferences = self.get_by_user(db, user_id)
        if not preferences:
            return False
        
        self.delete(db, id_or_obj=preferences)
        self.logger.info(f"Deleted notification preferences for user {user_id}")
        return True


# Create singleton instances
notification = CRUDNotification()
notification_preference = CRUDNotificationPreference()