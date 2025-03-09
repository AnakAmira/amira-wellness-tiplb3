from typing import List, Optional, Dict, Any, Union
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.device import Device, DevicePlatform
from ..core.logging import get_logger

# Initialize logger
logger = get_logger(__name__)

# Maximum number of devices per user
MAX_DEVICES_PER_USER = 5


class CRUDDevice(CRUDBase):
    """CRUD operations for Device model"""

    def __init__(self):
        """Initialize the CRUD operations for Device model"""
        super().__init__(Device)

    def get_by_device_id(self, db: Session, device_id: str) -> Optional[Device]:
        """
        Get a device by its unique device identifier
        
        Args:
            db: Database session
            device_id: Unique identifier for the device
            
        Returns:
            The device if found, None otherwise
        """
        query = select(Device).where(Device.device_id == device_id)
        return db.execute(query).scalars().first()

    def get_user_devices(self, db: Session, user_id: uuid.UUID, active_only: bool = True) -> List[Device]:
        """
        Get all devices for a specific user
        
        Args:
            db: Database session
            user_id: ID of the user to get devices for
            active_only: If True, only return active devices
            
        Returns:
            List of user's devices
        """
        query = select(Device).where(Device.user_id == user_id)
        if active_only:
            query = query.where(Device.is_active == True)
        return list(db.execute(query).scalars().all())

    def get_devices_by_platform(
        self, db: Session, user_id: uuid.UUID, platform: DevicePlatform, active_only: bool = True
    ) -> List[Device]:
        """
        Get devices filtered by platform
        
        Args:
            db: Database session
            user_id: ID of the user to get devices for
            platform: Device platform to filter by
            active_only: If True, only return active devices
            
        Returns:
            List of devices for the specified platform
        """
        query = select(Device).where(
            Device.user_id == user_id,
            Device.platform == platform
        )
        if active_only:
            query = query.where(Device.is_active == True)
        return list(db.execute(query).scalars().all())

    def get_devices_with_push_token(
        self, db: Session, user_id: uuid.UUID, active_only: bool = True
    ) -> List[Device]:
        """
        Get devices that have a push notification token
        
        Args:
            db: Database session
            user_id: ID of the user to get devices for
            active_only: If True, only return active devices
            
        Returns:
            List of devices with push tokens
        """
        query = select(Device).where(
            Device.user_id == user_id,
            Device.push_token.is_not(None)
        )
        if active_only:
            query = query.where(Device.is_active == True)
        return list(db.execute(query).scalars().all())

    def register_device(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        device_id: str, 
        device_name: str, 
        platform: DevicePlatform, 
        push_token: Optional[str] = None,
        app_version: str = "",
        os_version: str = "",
        ip_address: str = ""
    ) -> Device:
        """
        Register a new device or update an existing one
        
        Args:
            db: Database session
            user_id: ID of the user the device belongs to
            device_id: Unique identifier for the device
            device_name: Human-readable name for the device
            platform: Device platform (iOS, Android, etc.)
            push_token: Push notification token (optional)
            app_version: Version of the application
            os_version: Version of the operating system
            ip_address: IP address of the device
            
        Returns:
            The registered or updated device
        """
        # Check if device already exists
        existing_device = self.get_by_device_id(db, device_id)
        
        if existing_device:
            # Update existing device
            existing_device.user_id = user_id
            existing_device.device_name = device_name
            existing_device.platform = platform
            existing_device.push_token = push_token
            existing_device.app_version = app_version
            existing_device.os_version = os_version
            existing_device.update_activity(ip_address)
            
            db.add(existing_device)
            db.commit()
            db.refresh(existing_device)
            
            logger.info(f"Updated existing device: {device_id} for user: {user_id}")
            return existing_device
        
        # Check if user has reached device limit
        active_devices_count = self.count_user_active_devices(db, user_id)
        
        if active_devices_count >= MAX_DEVICES_PER_USER:
            # Deactivate oldest device
            logger.info(f"User {user_id} has reached the device limit. Deactivating oldest device.")
            
            # Get user's devices ordered by last active timestamp
            query = select(Device).where(
                Device.user_id == user_id,
                Device.is_active == True
            ).order_by(Device.last_active_at.nulls_last())
            
            oldest_device = db.execute(query).scalars().first()
            
            if oldest_device:
                oldest_device.deactivate()
                db.add(oldest_device)
                db.commit()
                logger.info(f"Deactivated oldest device {oldest_device.device_id} for user {user_id}")
        
        # Create new device
        device = Device(
            user_id=user_id,
            device_id=device_id,
            device_name=device_name,
            platform=platform,
            push_token=push_token,
            app_version=app_version,
            os_version=os_version,
            ip_address=ip_address,
            is_active=True
        )
        
        device.update_activity(ip_address)
        
        db.add(device)
        db.commit()
        db.refresh(device)
        
        logger.info(f"Registered new device: {device_id} for user: {user_id}")
        return device

    def update_device_activity(self, db: Session, device_id: str, ip_address: str) -> Optional[Device]:
        """
        Update the last activity timestamp for a device
        
        Args:
            db: Database session
            device_id: Unique identifier for the device
            ip_address: IP address of the device
            
        Returns:
            The updated device if found, None otherwise
        """
        device = self.get_by_device_id(db, device_id)
        
        if device:
            device.update_activity(ip_address)
            
            db.add(device)
            db.commit()
            db.refresh(device)
            
            logger.debug(f"Updated activity for device: {device_id}")
            return device
        
        return None

    def update_push_token(self, db: Session, device_id: str, push_token: str) -> Optional[Device]:
        """
        Update the push notification token for a device
        
        Args:
            db: Database session
            device_id: Unique identifier for the device
            push_token: New push notification token
            
        Returns:
            The updated device if found, None otherwise
        """
        device = self.get_by_device_id(db, device_id)
        
        if device:
            device.update_push_token(push_token)
            
            db.add(device)
            db.commit()
            db.refresh(device)
            
            logger.info(f"Updated push token for device: {device_id}")
            return device
        
        return None

    def deactivate_device(self, db: Session, device_id: str) -> Optional[Device]:
        """
        Deactivate a device
        
        Args:
            db: Database session
            device_id: Unique identifier for the device
            
        Returns:
            The deactivated device if found, None otherwise
        """
        device = self.get_by_device_id(db, device_id)
        
        if device:
            device.deactivate()
            
            db.add(device)
            db.commit()
            db.refresh(device)
            
            logger.info(f"Deactivated device: {device_id}")
            return device
        
        return None

    def deactivate_user_devices(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Deactivate all devices for a user
        
        Args:
            db: Database session
            user_id: ID of the user to deactivate devices for
            
        Returns:
            Number of devices deactivated
        """
        devices = self.get_user_devices(db, user_id, active_only=True)
        
        deactivated_count = 0
        for device in devices:
            device.deactivate()
            db.add(device)
            deactivated_count += 1
        
        if deactivated_count > 0:
            db.commit()
            logger.info(f"Deactivated {deactivated_count} devices for user: {user_id}")
        
        return deactivated_count

    def count_user_active_devices(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Count the number of active devices for a user
        
        Args:
            db: Database session
            user_id: ID of the user to count devices for
            
        Returns:
            Count of active devices
        """
        from sqlalchemy import func
        query = select(func.count()).select_from(Device).where(
            Device.user_id == user_id,
            Device.is_active == True
        )
        
        count = db.execute(query).scalar_one()
        return count


# Create a CRUD device instance
device = CRUDDevice()