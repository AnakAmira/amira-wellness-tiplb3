"""
Pydantic schemas for authentication-related data validation, serialization, and deserialization in the Amira Wellness application.
Defines request and response models for user authentication, token management, and password operations.
"""

from typing import Optional, Dict, Any
from datetime import datetime
import uuid

from pydantic import BaseModel, Field, EmailStr, validator, model_validator  # pydantic v2.4+

from .common import BaseSchema, TokenResponse
from .user import UserResponse
from ..utils.validators import validate_password
from ..core.security import TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH


class LoginRequest(BaseSchema):
    """Schema for user login request data."""
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseSchema):
    """Schema for token refresh request data."""
    refresh_token: str
    
    @validator('refresh_token')
    @classmethod
    def validate_refresh_token(cls, v: str) -> str:
        """Validates that the refresh token is not empty."""
        if not v or not v.strip():
            raise ValueError("Refresh token is required")
        return v


class LogoutRequest(BaseSchema):
    """Schema for logout request data."""
    refresh_token: Optional[str] = None


class PasswordResetRequest(BaseSchema):
    """Schema for password reset request data."""
    email: EmailStr


class PasswordResetConfirmRequest(BaseSchema):
    """Schema for confirming password reset with token."""
    token: str
    new_password: str
    new_password_confirm: str
    
    @validator('token')
    @classmethod
    def validate_token(cls, v: str) -> str:
        """Validates that the token is not empty."""
        if not v or not v.strip():
            raise ValueError("Token is required")
        return v
    
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
    def validate_passwords_match(cls, v: str, values: dict) -> str:
        """Validates that new_password and new_password_confirm match."""
        if 'new_password' in values and v != values['new_password']:
            raise ValueError("Passwords do not match")
        return v


class VerifyEmailRequest(BaseSchema):
    """Schema for email verification validation."""
    token: str
    
    @validator('token')
    @classmethod
    def validate_token(cls, v: str) -> str:
        """Validates that the token is not empty."""
        if not v or not v.strip():
            raise ValueError("Token is required")
        return v


class TokenData(BaseSchema):
    """Schema for decoded JWT token data."""
    sub: str
    type: str
    jti: Optional[str] = None
    exp: datetime
    iat: datetime
    
    @validator('type')
    @classmethod
    def validate_token_type(cls, v: str) -> str:
        """Validates that the token type is valid."""
        if v not in [TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH]:
            raise ValueError(f"Invalid token type: {v}")
        return v


class TokenBlacklist(BaseSchema):
    """Schema for blacklisted tokens."""
    token_id: str
    expiration: datetime
    reason: Optional[str] = None


class DeviceRegistrationRequest(BaseSchema):
    """Schema for device registration request data."""
    device_id: str
    device_name: str
    platform: str
    push_token: Optional[str] = None
    app_version: Optional[str] = None
    os_version: Optional[str] = None
    
    @validator('device_id')
    @classmethod
    def validate_device_id(cls, v: str) -> str:
        """Validates that the device_id is not empty."""
        if not v or not v.strip():
            raise ValueError("Device ID is required")
        return v
    
    @validator('platform')
    @classmethod
    def validate_platform(cls, v: str) -> str:
        """Validates that the platform is valid."""
        valid_platforms = ['ios', 'android', 'web']
        if v.lower() not in valid_platforms:
            raise ValueError(f"Platform must be one of: {', '.join(valid_platforms)}")
        return v.lower()


class AuthResponse(BaseSchema):
    """Schema for authentication response with tokens and user data."""
    tokens: TokenResponse
    user: UserResponse