"""
API error handling utilities for the Amira Wellness application.

This module provides standardized error handling for the API, including consistent
error responses, validation error formatting, and exception handler registration.
It implements a layered error handling approach to ensure all errors are properly
captured, logged, and returned with appropriate status codes and details.
"""

from typing import Dict, List, Any, Optional, Union, Type

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError

from ..core.logging import get_logger
from ..core.exceptions import AmiraException, ValidationException
from ..constants.error_codes import ErrorCategory, ERROR_CODES
from ..schemas.common import ErrorResponse

# Initialize logger
logger = get_logger(__name__)


def format_validation_errors(exc: Union[RequestValidationError, ValidationError]) -> List[Dict[str, Any]]:
    """
    Formats validation errors from Pydantic or FastAPI into a standardized structure.
    
    Args:
        exc: The validation exception containing error details
        
    Returns:
        List of formatted validation errors with location, field, and message
    """
    formatted_errors = []
    
    # Extract errors from the exception
    errors = exc.errors() if hasattr(exc, "errors") else []
    
    for error in errors:
        # Create a new formatted error entry
        formatted_error = {
            "location": ".".join(str(loc) for loc in error.get("loc", [])),
            "field": error.get("loc", [""])[-1] if error.get("loc") else "",
            "message": error.get("msg", "Validation error")
        }
        
        # Add additional context if available
        if "ctx" in error:
            formatted_error["context"] = error["ctx"]
            
        # Add type information
        if "type" in error:
            formatted_error["type"] = error["type"]
            
        formatted_errors.append(formatted_error)
        
    return formatted_errors


def get_error_code_for_validation(validation_errors: List[Dict[str, Any]]) -> str:
    """
    Determines the appropriate error code for validation errors based on the error type.
    
    Args:
        validation_errors: List of formatted validation errors
        
    Returns:
        Error code that best describes the validation error
    """
    # Default error code
    error_code = "VAL_INVALID_INPUT"
    
    # If no validation errors, return default
    if not validation_errors:
        return error_code
    
    # Check the first error to determine a more specific code
    first_error = validation_errors[0]
    
    # Check the error type or message to determine a more specific error code
    error_type = first_error.get("type", "")
    error_msg = first_error.get("message", "").lower()
    
    # Missing required fields
    if "missing" in error_msg or "required" in error_msg or error_type == "missing":
        return "VAL_REQUIRED_FIELD"
    
    # Invalid format (regex, email, etc.)
    if "pattern" in error_msg or "format" in error_msg or "invalid" in error_msg:
        return "VAL_INVALID_FORMAT"
    
    # Invalid length
    if "length" in error_msg or "too short" in error_msg or "too long" in error_msg:
        return "VAL_INVALID_LENGTH"
    
    # Value outside allowed range
    if "greater than" in error_msg or "less than" in error_msg or "range" in error_msg:
        return "VAL_INVALID_RANGE"
    
    # Duplicate entry
    if "duplicate" in error_msg or "already exists" in error_msg:
        return "VAL_DUPLICATE_ENTRY"
    
    # Return the default error code if no specific match
    return error_code


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """
    Handles FastAPI HTTPException and converts it to a standardized error response.
    
    Args:
        request: The request that caused the exception
        exc: The HTTP exception
        
    Returns:
        Standardized JSON error response
    """
    # Log the exception
    logger.warning(
        f"HTTP exception: {exc.status_code} - {exc.detail}",
        extra={
            "request_path": request.url.path,
            "status_code": exc.status_code,
            "headers": dict(request.headers)
        }
    )
    
    # Create error response
    error_response = {
        "error_code": f"HTTP_{exc.status_code}",
        "message": str(exc.detail),
        "details": {}
    }
    
    # Return JSONResponse with appropriate status code and headers
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response,
        headers=getattr(exc, "headers", None)
    )


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """
    Handles FastAPI RequestValidationError and converts it to a standardized error response.
    
    Args:
        request: The request that caused the exception
        exc: The validation exception
        
    Returns:
        Standardized JSON error response
    """
    # Format validation errors
    formatted_errors = format_validation_errors(exc)
    
    # Determine appropriate error code
    error_code = get_error_code_for_validation(formatted_errors)
    
    # Create ValidationException with formatted errors
    validation_exception = ValidationException(
        message="Validation error in request data",
        validation_errors=formatted_errors,
        error_code=error_code
    )
    
    # Log the exception
    logger.warning(
        f"Validation error: {error_code}",
        extra={
            "request_path": request.url.path,
            "validation_errors": formatted_errors,
            "method": request.method
        }
    )
    
    # Return error response
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=validation_exception.to_dict()
    )


async def pydantic_validation_exception_handler(request: Request, exc: ValidationError) -> JSONResponse:
    """
    Handles Pydantic ValidationError and converts it to a standardized error response.
    
    Args:
        request: The request that caused the exception
        exc: The validation exception
        
    Returns:
        Standardized JSON error response
    """
    # Format validation errors
    formatted_errors = format_validation_errors(exc)
    
    # Determine appropriate error code
    error_code = get_error_code_for_validation(formatted_errors)
    
    # Create ValidationException with formatted errors
    validation_exception = ValidationException(
        message="Validation error in request data",
        validation_errors=formatted_errors,
        error_code=error_code
    )
    
    # Log the exception
    logger.warning(
        f"Pydantic validation error: {error_code}",
        extra={
            "request_path": request.url.path,
            "validation_errors": formatted_errors,
            "method": request.method
        }
    )
    
    # Return error response
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=validation_exception.to_dict()
    )


async def amira_exception_handler(request: Request, exc: AmiraException) -> JSONResponse:
    """
    Handles application-specific AmiraException and converts it to a standardized error response.
    
    Args:
        request: The request that caused the exception
        exc: The application exception
        
    Returns:
        Standardized JSON error response
    """
    # Log the exception with appropriate severity
    logger.error(
        f"Application exception: {exc.error_code} - {exc.message}",
        extra={
            "request_path": request.url.path,
            "error_code": exc.error_code,
            "category": str(exc.category),
            "details": exc.details,
            "method": request.method
        }
    )
    
    # Convert exception to dictionary
    error_data = exc.to_dict()
    
    # Determine HTTP status code based on error category
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    
    if exc.category == ErrorCategory.AUTHENTICATION:
        status_code = status.HTTP_401_UNAUTHORIZED
    elif exc.category == ErrorCategory.AUTHORIZATION:
        status_code = status.HTTP_403_FORBIDDEN
    elif exc.category == ErrorCategory.VALIDATION:
        status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    elif exc.category == ErrorCategory.RESOURCE:
        status_code = status.HTTP_404_NOT_FOUND
    elif exc.category == ErrorCategory.BUSINESS:
        status_code = status.HTTP_400_BAD_REQUEST
    elif exc.category == ErrorCategory.EXTERNAL:
        status_code = status.HTTP_502_BAD_GATEWAY
    
    # Return error response
    return JSONResponse(
        status_code=status_code,
        content=error_data
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Handles any unhandled exceptions and converts them to a standardized error response.
    
    Args:
        request: The request that caused the exception
        exc: The unhandled exception
        
    Returns:
        Standardized JSON error response
    """
    # Log the unhandled exception with traceback
    logger.exception(
        f"Unhandled exception: {str(exc)}",
        extra={
            "request_path": request.url.path,
            "method": request.method,
            "exception_type": type(exc).__name__
        }
    )
    
    # Create generic error response
    error_response = {
        "error_code": "SYS_INTERNAL_ERROR",
        "message": "An unexpected error occurred.",
        "details": {}
    }
    
    # In development, include more details about the exception
    from ..core.config import settings
    if settings.ENVIRONMENT.lower() != "production":
        error_response["details"] = {
            "exception_type": type(exc).__name__,
            "exception_message": str(exc)
        }
    
    # Return error response
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=error_response
    )


def register_exception_handlers(app):
    """
    Registers all exception handlers with the FastAPI application.
    
    Args:
        app: The FastAPI application instance
    """
    # Register HTTP exception handler
    app.add_exception_handler(HTTPException, http_exception_handler)
    
    # Register validation exception handlers
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(ValidationError, pydantic_validation_exception_handler)
    
    # Register application exception handler
    app.add_exception_handler(AmiraException, amira_exception_handler)
    
    # Register catch-all handler for unhandled exceptions
    app.add_exception_handler(Exception, unhandled_exception_handler)