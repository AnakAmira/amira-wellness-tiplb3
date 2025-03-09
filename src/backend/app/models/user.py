from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.orm import relationship

from .base import BaseModel
from ..constants.languages import LanguageCode, DEFAULT_LANGUAGE


class User(BaseModel):
    """
    SQLAlchemy model representing a user account in the Amira Wellness application.
    Stores core user information, authentication data, and preferences while
    maintaining privacy by default.
    """
    # Basic user information
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    email_verified = Column(Boolean, default=False, nullable=False)
    last_login = Column(DateTime, nullable=True)
    
    # Account management
    account_status = Column(String(50), nullable=False, default='active', index=True)  # active, inactive, suspended, deleted
    
    # Security and encryption
    encryption_key_salt = Column(String(255), nullable=True)  # Salt for deriving encryption keys
    
    # User preferences
    subscription_tier = Column(String(50), nullable=False, default='free')  # free, premium
    language_preference = Column(Enum(LanguageCode), nullable=False, default=DEFAULT_LANGUAGE)
    
    # Relationships
    devices = relationship("Device", back_populates="user", cascade="all, delete-orphan")
    journals = relationship("Journal", back_populates="user", cascade="all, delete-orphan")
    emotional_checkins = relationship("EmotionalState", back_populates="user", cascade="all, delete-orphan")
    tool_favorites = relationship("ToolFavorite", back_populates="user", cascade="all, delete-orphan")
    achievements = relationship("Achievement", back_populates="user", cascade="all, delete-orphan")
    streaks = relationship("Streak", back_populates="user", cascade="all, delete-orphan")
    
    def is_active(self) -> bool:
        """
        Checks if the user account is active.
        
        Returns:
            bool: True if the account is active, False otherwise
        """
        return self.account_status == 'active'
    
    def is_premium(self) -> bool:
        """
        Checks if the user has a premium subscription.
        
        Returns:
            bool: True if the user has a premium subscription, False otherwise
        """
        return self.subscription_tier == 'premium'
    
    def set_password(self, password_hash: str) -> None:
        """
        Sets the user's password hash (does not store plain passwords).
        
        Args:
            password_hash (str): The hashed password to store
        """
        self.password_hash = password_hash
    
    def update_last_login(self) -> None:
        """
        Updates the last login timestamp to the current time.
        """
        from datetime import datetime
        self.last_login = datetime.utcnow()

    # Table-level constraints are defined using __table_args__
    __table_args__ = (
        # Check constraint to limit account_status values
        {"check_constraint": "account_status IN ('active', 'inactive', 'suspended', 'deleted')"},
        # Check constraint to limit subscription_tier values
        {"check_constraint": "subscription_tier IN ('free', 'premium')"},
    )