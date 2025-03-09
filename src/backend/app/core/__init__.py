"""
Core module for the Amira Wellness application.

This module imports and re-exports essential components from the core submodules,
providing a clean API for the rest of the application to access core services like
configuration, security, encryption, logging, exception handling, and event management.
"""

# Import configuration settings
from .config import settings

# Import logging utilities
from .logging import setup_logging, get_logger

# Import security utilities
from .security import (
    verify_password, get_password_hash, validate_password,
    create_access_token, create_refresh_token, decode_token, is_token_valid,
    SecurityError, InvalidTokenError, TokenExpiredError, PasswordValidationError,
    TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH
)

# Import encryption services
from .encryption import (
    EncryptionManager, EncryptionError, DecryptionError, KMSError
)

# Import application exceptions
from .exceptions import (
    AmiraException, ValidationException, AuthenticationException,
    PermissionDeniedException, ResourceNotFoundException, ResourceExistsException,
    BusinessException, SystemException, ExternalServiceException,
    EncryptionException, RateLimitExceededException
)

# Import event system
from .events import (
    EventType, Event, publish_event, subscribe, unsubscribe, get_subscribers, event_bus
)

# Define what's exported when using "from app.core import *"
__all__ = [
    # Configuration
    "settings",
    
    # Logging
    "setup_logging", "get_logger",
    
    # Security
    "verify_password", "get_password_hash", "validate_password",
    "create_access_token", "create_refresh_token", "decode_token", "is_token_valid",
    "SecurityError", "InvalidTokenError", "TokenExpiredError", "PasswordValidationError",
    "TOKEN_TYPE_ACCESS", "TOKEN_TYPE_REFRESH",
    
    # Encryption
    "EncryptionManager", "EncryptionError", "DecryptionError", "KMSError",
    
    # Exceptions
    "AmiraException", "ValidationException", "AuthenticationException",
    "PermissionDeniedException", "ResourceNotFoundException", "ResourceExistsException",
    "BusinessException", "SystemException", "ExternalServiceException",
    "EncryptionException", "RateLimitExceededException",
    
    # Events
    "EventType", "Event", "publish_event", "subscribe", "unsubscribe", 
    "get_subscribers", "event_bus"
]