"""
Error Codes Module

This module defines standardized error codes, categories, and severity levels for the Amira Wellness 
application. It provides a centralized repository of error definitions to ensure consistent error 
handling and reporting across the application.

These codes are used throughout the application to categorize exceptions, generate appropriate
error responses, and facilitate logging and monitoring.

Error codes follow a naming convention:
- Prefix indicates the category (AUTH, PERM, VAL, RES, BUS, SYS, EXT, ENC)
- Suffix describes the specific error condition
"""

import enum  # standard library


class ErrorCategory(enum.Enum):
    """Enumeration of error categories for classification of exceptions."""
    AUTHENTICATION = "authentication"
    AUTHORIZATION = "authorization"
    VALIDATION = "validation"
    RESOURCE = "resource"
    BUSINESS = "business"
    SYSTEM = "system"
    EXTERNAL = "external"
    ENCRYPTION = "encryption"


class ErrorSeverity(enum.Enum):
    """Enumeration of error severity levels for prioritizing errors."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


# Comprehensive dictionary of error codes with their descriptions,
# categories, and default messages
ERROR_CODES = {
    # Authentication errors
    "AUTH_INVALID_CREDENTIALS": {
        "message": "Invalid username or password",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "AUTH_EXPIRED_TOKEN": {
        "message": "Authentication token has expired",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "AUTH_INVALID_TOKEN": {
        "message": "Invalid authentication token",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "AUTH_MISSING_TOKEN": {
        "message": "Authentication token is required",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "AUTH_ACCOUNT_LOCKED": {
        "message": "Account has been locked due to multiple failed attempts",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.HIGH
    },
    "AUTH_EMAIL_NOT_VERIFIED": {
        "message": "Email address has not been verified",
        "category": ErrorCategory.AUTHENTICATION,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # Authorization errors
    "PERM_INSUFFICIENT_PRIVILEGES": {
        "message": "Insufficient privileges to perform this action",
        "category": ErrorCategory.AUTHORIZATION,
        "severity": ErrorSeverity.HIGH
    },
    "PERM_ACTION_FORBIDDEN": {
        "message": "This action is forbidden",
        "category": ErrorCategory.AUTHORIZATION,
        "severity": ErrorSeverity.HIGH
    },
    "PERM_RESOURCE_ACCESS_DENIED": {
        "message": "Access to this resource is denied",
        "category": ErrorCategory.AUTHORIZATION,
        "severity": ErrorSeverity.HIGH
    },
    
    # Validation errors
    "VAL_INVALID_INPUT": {
        "message": "Invalid input data",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "VAL_REQUIRED_FIELD": {
        "message": "Required field is missing",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "VAL_INVALID_FORMAT": {
        "message": "Field format is invalid",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "VAL_INVALID_LENGTH": {
        "message": "Field length is invalid",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "VAL_INVALID_RANGE": {
        "message": "Value is outside of allowed range",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    "VAL_DUPLICATE_ENTRY": {
        "message": "Entry already exists",
        "category": ErrorCategory.VALIDATION,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # Resource errors
    "RES_NOT_FOUND": {
        "message": "Resource not found",
        "category": ErrorCategory.RESOURCE,
        "severity": ErrorSeverity.MEDIUM
    },
    "RES_ALREADY_EXISTS": {
        "message": "Resource already exists",
        "category": ErrorCategory.RESOURCE,
        "severity": ErrorSeverity.MEDIUM
    },
    "RES_CONFLICT": {
        "message": "Resource conflict",
        "category": ErrorCategory.RESOURCE,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # Business logic errors
    "BUS_INVALID_OPERATION": {
        "message": "Invalid operation",
        "category": ErrorCategory.BUSINESS,
        "severity": ErrorSeverity.MEDIUM
    },
    "BUS_OPERATION_FAILED": {
        "message": "Operation failed",
        "category": ErrorCategory.BUSINESS,
        "severity": ErrorSeverity.MEDIUM
    },
    "BUS_PRECONDITION_FAILED": {
        "message": "Precondition for operation failed",
        "category": ErrorCategory.BUSINESS,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # System errors
    "SYS_INTERNAL_ERROR": {
        "message": "Internal system error",
        "category": ErrorCategory.SYSTEM,
        "severity": ErrorSeverity.HIGH
    },
    "SYS_SERVICE_UNAVAILABLE": {
        "message": "Service temporarily unavailable",
        "category": ErrorCategory.SYSTEM,
        "severity": ErrorSeverity.HIGH
    },
    "SYS_TIMEOUT": {
        "message": "Operation timed out",
        "category": ErrorCategory.SYSTEM,
        "severity": ErrorSeverity.MEDIUM
    },
    "SYS_RATE_LIMIT_EXCEEDED": {
        "message": "Rate limit exceeded",
        "category": ErrorCategory.SYSTEM,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # External service errors
    "EXT_SERVICE_ERROR": {
        "message": "External service error",
        "category": ErrorCategory.EXTERNAL,
        "severity": ErrorSeverity.HIGH
    },
    "EXT_SERVICE_UNAVAILABLE": {
        "message": "External service unavailable",
        "category": ErrorCategory.EXTERNAL,
        "severity": ErrorSeverity.HIGH
    },
    "EXT_INVALID_RESPONSE": {
        "message": "Invalid response from external service",
        "category": ErrorCategory.EXTERNAL,
        "severity": ErrorSeverity.MEDIUM
    },
    
    # Encryption errors
    "ENC_KEY_GENERATION_FAILED": {
        "message": "Failed to generate encryption key",
        "category": ErrorCategory.ENCRYPTION,
        "severity": ErrorSeverity.HIGH
    },
    "ENC_ENCRYPTION_FAILED": {
        "message": "Encryption operation failed",
        "category": ErrorCategory.ENCRYPTION,
        "severity": ErrorSeverity.HIGH
    },
    "ENC_DECRYPTION_FAILED": {
        "message": "Decryption operation failed",
        "category": ErrorCategory.ENCRYPTION,
        "severity": ErrorSeverity.HIGH
    },
    "ENC_INVALID_KEY": {
        "message": "Invalid encryption key",
        "category": ErrorCategory.ENCRYPTION,
        "severity": ErrorSeverity.HIGH
    },
    "ENC_DATA_INTEGRITY": {
        "message": "Encrypted data integrity check failed",
        "category": ErrorCategory.ENCRYPTION,
        "severity": ErrorSeverity.CRITICAL
    }
}