"""
Core exceptions module for the Amira Wellness application.

This module defines a hierarchy of application-specific exceptions with standardized
error handling, including error codes, messages, and HTTP status code mapping.
It ensures uniform error responses across the application.

The exception hierarchy is organized by error category:
- AmiraException: Base class for all application exceptions
- ValidationException: For data validation errors
- AuthenticationException: For authentication errors
- PermissionDeniedException: For authorization errors
- ResourceNotFoundException: For resource not found errors
- ResourceExistsException: For resource already exists errors
- BusinessException: For business logic errors
- SystemException: For internal system errors
- ExternalServiceException: For external service errors
- EncryptionException: For encryption and decryption errors
- RateLimitExceededException: For rate limit exceeded errors
"""

import traceback
from typing import Dict, Optional, Any, List, Union

from fastapi import HTTPException, status  # fastapi 0.104+

from ..constants.error_codes import ErrorCategory, ErrorSeverity, ERROR_CODES
from .logging import get_logger

# Initialize logger
logger = get_logger(__name__)


def get_error_details(error_code: str) -> Dict:
    """
    Retrieves error details from the ERROR_CODES dictionary for the given error code.

    Args:
        error_code: The error code to look up

    Returns:
        A dictionary containing the error details (message, category, severity)
    """
    if error_code in ERROR_CODES:
        return ERROR_CODES[error_code]
    
    # If error code not found, log a warning and return a default error
    logger.warning(f"Unknown error code: {error_code}")
    return {
        "message": f"Unknown error: {error_code}",
        "category": ErrorCategory.SYSTEM,
        "severity": ErrorSeverity.HIGH
    }


def get_status_code_for_category(category: ErrorCategory) -> int:
    """
    Maps error categories to appropriate HTTP status codes.

    Args:
        category: The error category

    Returns:
        The corresponding HTTP status code
    """
    status_map = {
        ErrorCategory.AUTHENTICATION: status.HTTP_401_UNAUTHORIZED,
        ErrorCategory.AUTHORIZATION: status.HTTP_403_FORBIDDEN,
        ErrorCategory.VALIDATION: status.HTTP_422_UNPROCESSABLE_ENTITY,
        ErrorCategory.RESOURCE: status.HTTP_404_NOT_FOUND,
        ErrorCategory.BUSINESS: status.HTTP_400_BAD_REQUEST,
        ErrorCategory.SYSTEM: status.HTTP_500_INTERNAL_SERVER_ERROR,
        ErrorCategory.EXTERNAL: status.HTTP_502_BAD_GATEWAY,
        ErrorCategory.ENCRYPTION: status.HTTP_500_INTERNAL_SERVER_ERROR
    }
    
    return status_map.get(category, status.HTTP_500_INTERNAL_SERVER_ERROR)


class AmiraException(Exception):
    """
    Base exception class for all application-specific exceptions.
    
    This class provides standardized error handling with consistent error codes,
    messages, and HTTP status code mapping to ensure uniform error responses
    across the application.
    """

    def __init__(
        self,
        error_code: str,
        message: Optional[str] = None,
        details: Optional[Dict] = None,
        original_exception: Optional[Exception] = None
    ):
        """
        Initialize the exception with error code and optional details.

        Args:
            error_code: Unique identifier for the error
            message: Human-readable error message (if None, uses default from ERROR_CODES)
            details: Additional contextual information about the error
            original_exception: The underlying exception that caused this error
        """
        # Get error details from the error codes dictionary
        error_details = get_error_details(error_code)
        
        # Use provided message or default from error details
        message = message or error_details["message"]
        
        # Initialize the base Exception class
        super().__init__(message)
        
        # Set exception properties
        self.error_code = error_code
        self.message = message
        self.category = error_details["category"]
        self.severity = error_details["severity"]
        self.details = details or {}
        self.original_exception = original_exception
        
        # Log the exception with appropriate severity level
        self._log_exception()

    def _log_exception(self):
        """
        Logs the exception with appropriate severity level.
        """
        log_context = {
            "error_code": self.error_code,
            "category": str(self.category),
            "details": self.details
        }
        
        if self.original_exception:
            log_context["original_exception"] = str(self.original_exception)
        
        # Choose logging level based on error severity
        if self.severity == ErrorSeverity.CRITICAL:
            logger.critical(f"{self.error_code}: {self.message}", extra=log_context)
        elif self.severity == ErrorSeverity.HIGH:
            logger.error(f"{self.error_code}: {self.message}", extra=log_context)
        elif self.severity == ErrorSeverity.MEDIUM:
            logger.warning(f"{self.error_code}: {self.message}", extra=log_context)
        else:  # LOW
            logger.info(f"{self.error_code}: {self.message}", extra=log_context)

    def to_dict(self) -> Dict:
        """
        Converts the exception to a dictionary for API responses.

        Returns:
            A dictionary representation of the exception
        """
        result = {
            "error_code": self.error_code,
            "message": self.message,
            "category": str(self.category.value)
        }
        
        if self.details:
            result["details"] = self.details
            
        return result

    def to_http_exception(self) -> HTTPException:
        """
        Converts the exception to a FastAPI HTTPException.

        Returns:
            An HTTPException with the appropriate status code and details
        """
        status_code = get_status_code_for_category(self.category)
        return HTTPException(
            status_code=status_code,
            detail=self.to_dict()
        )
        
    def __str__(self) -> str:
        """
        Returns a string representation of the exception.

        Returns:
            Formatted string with error details
        """
        result = f"[{self.error_code}] {self.category.value}: {self.message}"
        if self.details:
            result += f" - Details: {self.details}"
        return result


class ValidationException(AmiraException):
    """
    Exception raised for data validation errors.
    """

    def __init__(
        self,
        message: str,
        validation_errors: List[Dict],
        error_code: Optional[str] = None
    ):
        """
        Initialize validation exception with error details.

        Args:
            message: Human-readable error message
            validation_errors: List of validation errors with field and error information
            error_code: Error code (defaults to VAL_INVALID_INPUT)
        """
        error_code = error_code or "VAL_INVALID_INPUT"
        self.validation_errors = validation_errors
        details = {"validation_errors": validation_errors}
        super().__init__(error_code, message, details)


class AuthenticationException(AmiraException):
    """
    Exception raised for authentication errors.
    """

    def __init__(
        self,
        error_code: str,
        message: Optional[str] = None,
        details: Optional[Dict] = None
    ):
        """
        Initialize authentication exception.

        Args:
            error_code: Authentication-specific error code
            message: Human-readable error message
            details: Additional contextual information about the error
        """
        super().__init__(error_code, message, details)


class PermissionDeniedException(AmiraException):
    """
    Exception raised for authorization errors.
    """

    def __init__(
        self,
        message: Optional[str] = None,
        details: Optional[Dict] = None,
        error_code: str = "PERM_INSUFFICIENT_PRIVILEGES"
    ):
        """
        Initialize permission denied exception.

        Args:
            message: Human-readable error message
            details: Additional contextual information about the error
            error_code: Error code (defaults to PERM_INSUFFICIENT_PRIVILEGES)
        """
        super().__init__(error_code, message, details)


class ResourceNotFoundException(AmiraException):
    """
    Exception raised when a requested resource is not found.
    """

    def __init__(
        self,
        resource_type: str,
        resource_id: Any,
        message: Optional[str] = None
    ):
        """
        Initialize resource not found exception.

        Args:
            resource_type: Type of resource that was not found (e.g., "user", "journal")
            resource_id: Identifier of the resource
            message: Human-readable error message
        """
        self.resource_type = resource_type
        self.resource_id = resource_id
        
        # Generate default message if not provided
        if not message:
            message = f"{resource_type.capitalize()} with id '{resource_id}' not found"
            
        details = {
            "resource_type": resource_type,
            "resource_id": str(resource_id)
        }
        
        super().__init__("RES_NOT_FOUND", message, details)


class ResourceExistsException(AmiraException):
    """
    Exception raised when attempting to create a resource that already exists.
    """

    def __init__(
        self,
        resource_type: str,
        resource_id: Any,
        message: Optional[str] = None
    ):
        """
        Initialize resource exists exception.

        Args:
            resource_type: Type of resource that already exists (e.g., "user", "journal")
            resource_id: Identifier of the resource
            message: Human-readable error message
        """
        self.resource_type = resource_type
        self.resource_id = resource_id
        
        # Generate default message if not provided
        if not message:
            message = f"{resource_type.capitalize()} with id '{resource_id}' already exists"
            
        details = {
            "resource_type": resource_type,
            "resource_id": str(resource_id)
        }
        
        super().__init__("RES_ALREADY_EXISTS", message, details)


class BusinessException(AmiraException):
    """
    Exception raised for business logic errors.
    """

    def __init__(
        self,
        error_code: str,
        message: Optional[str] = None,
        details: Optional[Dict] = None
    ):
        """
        Initialize business exception.

        Args:
            error_code: Business-specific error code
            message: Human-readable error message
            details: Additional contextual information about the error
        """
        super().__init__(error_code, message, details)


class SystemException(AmiraException):
    """
    Exception raised for internal system errors.
    """

    def __init__(
        self,
        message: Optional[str] = None,
        details: Optional[Dict] = None,
        original_exception: Optional[Exception] = None,
        error_code: str = "SYS_INTERNAL_ERROR"
    ):
        """
        Initialize system exception.

        Args:
            message: Human-readable error message
            details: Additional contextual information about the error
            original_exception: The underlying exception that caused this error
            error_code: Error code (defaults to SYS_INTERNAL_ERROR)
        """
        details = details or {}
        
        # Add traceback information if original exception is provided
        if original_exception:
            tb_str = "".join(traceback.format_exception(
                type(original_exception),
                original_exception,
                original_exception.__traceback__
            ))
            details["traceback"] = tb_str
            
        super().__init__(error_code, message, details, original_exception)


class ExternalServiceException(AmiraException):
    """
    Exception raised for errors in external service interactions.
    """

    def __init__(
        self,
        service_name: str,
        message: Optional[str] = None,
        details: Optional[Dict] = None,
        original_exception: Optional[Exception] = None,
        error_code: str = "EXT_SERVICE_ERROR"
    ):
        """
        Initialize external service exception.

        Args:
            service_name: Name of the external service
            message: Human-readable error message
            details: Additional contextual information about the error
            original_exception: The underlying exception that caused this error
            error_code: Error code (defaults to EXT_SERVICE_ERROR)
        """
        self.service_name = service_name
        
        details = details or {}
        details["service_name"] = service_name
        
        super().__init__(error_code, message, details, original_exception)


class EncryptionException(AmiraException):
    """
    Exception raised for encryption and decryption errors.
    """

    def __init__(
        self,
        error_code: str,
        message: Optional[str] = None,
        details: Optional[Dict] = None,
        original_exception: Optional[Exception] = None
    ):
        """
        Initialize encryption exception.

        Args:
            error_code: Encryption-specific error code
            message: Human-readable error message
            details: Additional contextual information about the error
            original_exception: The underlying exception that caused this error
        """
        super().__init__(error_code, message, details, original_exception)


class RateLimitExceededException(AmiraException):
    """
    Exception raised when a rate limit is exceeded.
    """

    def __init__(
        self,
        retry_after: int,
        message: Optional[str] = None
    ):
        """
        Initialize rate limit exceeded exception.

        Args:
            retry_after: Time in seconds after which the client can retry
            message: Human-readable error message
        """
        self.retry_after = retry_after
        
        # Use default message if not provided
        message = message or f"Rate limit exceeded. Please retry after {retry_after} seconds."
        
        details = {"retry_after": retry_after}
        
        super().__init__("SYS_RATE_LIMIT_EXCEEDED", message, details)

    def to_http_exception(self) -> HTTPException:
        """
        Converts to HTTPException with retry-after header.

        Returns:
            An HTTPException with the appropriate status code, details, and headers
        """
        http_exception = super().to_http_exception()
        # Add retry-after header
        http_exception.headers = {"Retry-After": str(self.retry_after)}
        return http_exception