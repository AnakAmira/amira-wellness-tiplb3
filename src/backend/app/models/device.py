import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum, UUID
from sqlalchemy.orm import relationship

from .base import BaseModel


class DevicePlatform(enum.Enum):
    """Enumeration of supported device platforms"""
    IOS = "IOS"
    ANDROID = "ANDROID"
    WEB = "WEB"


class Device(BaseModel):
    """SQLAlchemy model representing a user device in the Amira Wellness application"""
    
    # Foreign key relationship to user
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Device identification
    device_id = Column(String(255), nullable=False, unique=True, index=True)
    device_name = Column(String(255), nullable=True)
    platform = Column(Enum(DevicePlatform), nullable=False, index=True)
    
    # Push notification information
    push_token = Column(String(255), nullable=True)
    
    # Device metadata
    app_version = Column(String(50), nullable=True)
    os_version = Column(String(50), nullable=True)
    ip_address = Column(String(50), nullable=True)
    last_active_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    
    # Relationships
    user = relationship("User", back_populates="devices")
    
    def update_activity(self, ip_address=None):
        """
        Updates the last activity timestamp and IP address
        
        Args:
            ip_address (str, optional): The IP address to record. Defaults to None.
        """
        self.last_active_at = datetime.utcnow()
        if ip_address:
            self.ip_address = ip_address
        self.is_active = True
    
    def update_push_token(self, push_token):
        """
        Updates the push notification token
        
        Args:
            push_token (str): The new push notification token
        """
        self.push_token = push_token
        self.update_activity()
    
    def deactivate(self):
        """
        Deactivates the device and clears push token
        """
        self.is_active = False
        self.push_token = None