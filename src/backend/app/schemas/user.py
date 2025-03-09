"""
Pydantic schemas for user data validation, serialization, and deserialization in the Amira Wellness application.
Defines request and response models for user creation, updates, and retrieval.
"""

from typing import Optional, Dict, Any
from datetime import datetime
import uuid

from pydantic import BaseModel, Field, EmailStr, validator, model_validator  # pydantic v2.4+

from .common import BaseSchema, IDSchema, TimestampSchema
from ..constants.languages import LanguageCode, DEFAULT_LANGUAGE
from ..utils.validators import validate_email, validate_password


class UserBase(BaseSchema):
    """Base schema for user data with common fields."""
    email: EmailStr = Field(description="User's email address")
    language_preference: Optional[LanguageCode] = Field(
        default=None, 
        description="User's preferred language"
    )
    
    @validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validates that the email is properly formatted."""
        if not validate_email(v):
            raise ValueError("Invalid email format")
        return v
        
    @model_validator(mode='before')
    @classmethod
    def set_default_language(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        """Sets default language if not provided."""
        if not isinstance(values, dict):
            return values
        if 'language_preference' not in values or values['language_preference'] is None:
            values['language_preference'] = DEFAULT_LANGUAGE
        return values


class UserCreate(UserBase):
    """Schema for creating a new user."""
    password: str = Field(description="User's password")
    password_confirm: str = Field(description="Confirmation of user's password")
    
    @validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validates that the password meets security requirements."""
        if not validate_password(v):
            raise ValueError(
                "Password must be at least 10 characters long and include uppercase, "
                "lowercase, number, and special character"
            )
        return v
    
    @validator('password_confirm')
    @classmethod
    def validate_passwords_match(cls, v: str, values: Dict[str, Any]) -> str:
        """Validates that password and password_confirm match."""
        if 'password' in values and v != values['password']:
            raise ValueError("Passwords do not match")
        return v


class UserUpdate(BaseSchema):
    """Schema for updating an existing user."""
    language_preference: Optional[LanguageCode] = Field(
        default=None, 
        description="User's preferred language"
    )
    subscription_tier: Optional[str] = Field(
        default=None, 
        description="User's subscription tier (free or premium)"
    )
    
    @validator('subscription_tier')
    @classmethod
    def validate_subscription_tier(cls, v: Optional[str]) -> Optional[str]:
        """Validates that the subscription tier is valid."""
        if v is not None and v not in ['free', 'premium']:
            raise ValueError("Subscription tier must be either 'free' or 'premium'")
        return v


class UserPasswordUpdate(BaseSchema):
    """Schema for updating a user's password."""
    current_password: str = Field(description="User's current password")
    new_password: str = Field(description="User's new password")
    new_password_confirm: str = Field(description="Confirmation of user's new password")
    
    @validator('new_password')
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        """Validates that the new password meets security requirements."""
        if not validate_password(v):
            raise ValueError(
                "Password must be at least 10 characters long and include uppercase, "
                "lowercase, number, and special character"
            )
        return v
    
    @validator('new_password_confirm')
    @classmethod
    def validate_passwords_match(cls, v: str, values: Dict[str, Any]) -> str:
        """Validates that new_password and new_password_confirm match."""
        if 'new_password' in values and v != values['new_password']:
            raise ValueError("New passwords do not match")
        return v
    
    @model_validator(mode='after')
    @classmethod
    def validate_different_password(cls, model: 'UserPasswordUpdate') -> 'UserPasswordUpdate':
        """Validates that the new password is different from the current password."""
        if model.current_password == model.new_password:
            raise ValueError("New password must be different from current password")
        return model


class UserInDB(UserBase, IDSchema, TimestampSchema):
    """Schema for user data as stored in the database."""
    password_hash: str = Field(description="Hashed user password")
    email_verified: bool = Field(default=False, description="Whether user's email is verified")
    last_login: Optional[datetime] = Field(default=None, description="Last login timestamp")
    account_status: str = Field(default="active", description="User account status")
    encryption_key_salt: Optional[str] = Field(default=None, description="Salt for encryption key derivation")
    subscription_tier: str = Field(default="free", description="User's subscription tier")


class UserResponse(UserBase, IDSchema, TimestampSchema):
    """Schema for user data returned in API responses."""
    email_verified: bool = Field(default=False, description="Whether user's email is verified")
    last_login: Optional[datetime] = Field(default=None, description="Last login timestamp")
    account_status: str = Field(default="active", description="User account status")
    subscription_tier: str = Field(default="free", description="User's subscription tier")
    is_active: bool = Field(description="Whether the user account is active")
    is_premium: bool = Field(description="Whether the user has a premium subscription")
    
    @model_validator(mode='before')
    @classmethod
    def compute_status_flags(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        """Computes derived status flags for the user."""
        if not isinstance(values, dict):
            return values
        values['is_active'] = values.get('account_status') == 'active'
        values['is_premium'] = values.get('subscription_tier') == 'premium'
        return values


class UserProfileResponse(UserResponse):
    """Schema for detailed user profile data returned in API responses."""
    # Additional profile fields would be added here in future extensions
    pass