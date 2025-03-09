"""
Core security module for the Amira Wellness application.

This module provides authentication, password handling, and token management
functionality to support the privacy-first approach of the application.
"""

import datetime
from datetime import timedelta
from typing import Dict, Optional, Union
import uuid

import jwt  # PyJWT v2.8+
from jwt import JWTError
from passlib.context import CryptContext  # passlib v1.7+

from .config import settings
from .logging import logger
from ..utils.security import generate_secure_random_string, is_secure_password

# Configure the password context to use Argon2id algorithm
pwd_context = CryptContext(schemes=['argon2'], deprecated='auto')

# Constants
REFRESH_TOKEN_LENGTH = 64
TOKEN_TYPE_ACCESS = 'access'
TOKEN_TYPE_REFRESH = 'refresh'


class SecurityError(Exception):
    """Base exception class for security-related errors."""
    
    def __init__(self, message: str):
        """Initialize the SecurityError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message


class InvalidTokenError(SecurityError):
    """Exception raised when a token is invalid."""
    
    def __init__(self, message: str):
        """Initialize the InvalidTokenError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class TokenExpiredError(SecurityError):
    """Exception raised when a token has expired."""
    
    def __init__(self, message: str):
        """Initialize the TokenExpiredError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class PasswordValidationError(SecurityError):
    """Exception raised when a password fails validation."""
    
    def __init__(self, message: str):
        """Initialize the PasswordValidationError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain password against a hashed password.
    
    Args:
        plain_password: The plain text password to verify
        hashed_password: The hashed password to check against
        
    Returns:
        True if the password matches, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Generates a secure hash of a password using Argon2.
    
    Args:
        password: The password to hash
        
    Returns:
        Hashed password
    """
    return pwd_context.hash(password)


def validate_password(password: str) -> bool:
    """Validates that a password meets security requirements.
    
    Args:
        password: The password to validate
        
    Returns:
        True if the password is valid, False otherwise
    """
    return is_secure_password(password)


def create_access_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    """Creates a JWT access token for a user.
    
    Args:
        subject: The subject of the token (usually user ID)
        expires_delta: Optional custom expiration time
        
    Returns:
        JWT access token
    """
    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Calculate expiration time
    expire = datetime.datetime.utcnow() + expires_delta
    
    # Create token payload
    to_encode = {
        "sub": str(subject),
        "type": TOKEN_TYPE_ACCESS,
        "exp": expire,
        "iat": datetime.datetime.utcnow()
    }
    
    # Encode the token
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    logger.debug(f"Access token created for subject: {subject}")
    return encoded_jwt


def create_refresh_token(subject: str, token_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """Creates a JWT refresh token for a user.
    
    Args:
        subject: The subject of the token (usually user ID)
        token_id: Unique identifier for the refresh token
        expires_delta: Optional custom expiration time
        
    Returns:
        JWT refresh token
    """
    if expires_delta is None:
        expires_delta = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    # Calculate expiration time
    expire = datetime.datetime.utcnow() + expires_delta
    
    # Create token payload
    to_encode = {
        "sub": str(subject),
        "type": TOKEN_TYPE_REFRESH,
        "jti": token_id,  # JWT ID - unique identifier for the token
        "exp": expire,
        "iat": datetime.datetime.utcnow()
    }
    
    # Encode the token
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    logger.debug(f"Refresh token created for subject: {subject}, token_id: {token_id}")
    return encoded_jwt


def decode_token(token: str) -> Dict:
    """Decodes and validates a JWT token.
    
    Args:
        token: JWT token to decode
        
    Returns:
        Decoded token payload
        
    Raises:
        InvalidTokenError: If the token is invalid
        TokenExpiredError: If the token has expired
    """
    try:
        # Decode the token
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        # Check if token has expired
        if "exp" in payload and datetime.datetime.fromtimestamp(payload["exp"]) < datetime.datetime.utcnow():
            logger.warning(f"Token expired: {payload.get('sub', 'unknown')}")
            raise TokenExpiredError("Token has expired")
        
        return payload
    except JWTError as e:
        logger.warning(f"Invalid token: {str(e)}")
        raise InvalidTokenError(f"Could not validate token: {str(e)}")


def is_token_valid(token: str) -> bool:
    """Checks if a token is valid (not expired and properly formatted).
    
    Args:
        token: JWT token to validate
        
    Returns:
        True if the token is valid, False otherwise
    """
    try:
        decode_token(token)
        return True
    except (InvalidTokenError, TokenExpiredError):
        return False


def generate_token_id() -> str:
    """Generates a unique identifier for refresh tokens.
    
    Returns:
        Unique token identifier
    """
    return str(uuid.uuid4())


def get_token_expiration(token_type: str) -> int:
    """Calculates token expiration time in seconds.
    
    Args:
        token_type: Type of token (access or refresh)
        
    Returns:
        Token expiration time in seconds
        
    Raises:
        ValueError: If token type is invalid
    """
    if token_type == TOKEN_TYPE_ACCESS:
        return settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    elif token_type == TOKEN_TYPE_REFRESH:
        return settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60
    else:
        raise ValueError(f"Invalid token type: {token_type}")