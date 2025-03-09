from typing import Dict, Any, Optional, Callable
import traceback
import json

from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError  # pydantic v2.4+
from starlette.middleware.base import BaseHTTPMiddleware  # starlette v0.27+
from starlette.requests import Request  # starlette v0.27+
from starlette.responses import Response  # starlette v0.27+
from starlette.types import ASGIApp  # starlette v0.27+

from ..core.logging import get_logger, log_exception
from ..core.exceptions import AmiraException, ValidationException, SystemException
from ..constants.error_codes import ErrorCategory
from ..api.errors import format_validation_errors, get_error_code_for_validation

# Initialize logger
logger = get_logger(__name__)


def extract_request_details(request: Request) -> Dict[str, Any]:
    """
    Extracts relevant details from the request for error logging.
    
    Args:
        request: The request object
        
    Returns:
        Dictionary containing request details
    """
    # Start with basic details
    details = {
        "method": request.method,
        "url": str(request.url),
        "path": request.url.path,
        "query_params": dict(request.query_params.items()),
    }
    
    # Extract headers, excluding sensitive ones
    headers = {}
    for key, value in request.headers.items():
        # Skip sensitive headers
        if key.lower() not in ["authorization", "cookie", "x-api-key"]:
            headers[key] = value
    details["headers"] = headers
    
    # Extract client IP
    if hasattr(request, "client") and request.client:
        details["client_ip"] = request.client.host
    
    # Extract user agent
    if "user-agent" in request.headers:
        details["user_agent"] = request.headers["user-agent"]
    
    return details


def create_error_response(exc: Exception, request: Request) -> JSONResponse:
    """
    Creates a standardized error response from an exception.
    
    Args:
        exc: The exception that occurred
        request: The request that caused the exception
        
    Returns:
        Standardized JSON error response
    """
    # Extract request details for logging
    request_details = extract_request_details(request)
    
    # Handle different types of exceptions
    if isinstance(exc, AmiraException):
        # Use the built-in method to convert to HTTP exception
        http_exc = exc.to_http_exception()
        status_code = http_exc.status_code
        error_data = exc.to_dict()
        headers = getattr(http_exc, "headers", None)
    
    elif isinstance(exc, (RequestValidationError, ValidationError)):
        # Format validation errors
        validation_errors = format_validation_errors(exc)
        error_code = get_error_code_for_validation(validation_errors)
        
        # Create a ValidationException
        validation_exc = ValidationException(
            message="Validation error in request data",
            validation_errors=validation_errors,
            error_code=error_code
        )
        
        # Use the built-in method to convert to HTTP exception
        http_exc = validation_exc.to_http_exception()
        status_code = http_exc.status_code
        error_data = validation_exc.to_dict()
        headers = getattr(http_exc, "headers", None)
    
    elif isinstance(exc, HTTPException):
        # Handle FastAPI HTTPException
        status_code = exc.status_code
        error_data = {
            "error_code": f"HTTP_{exc.status_code}",
            "message": str(exc.detail),
            "category": "system",
            "details": {}
        }
        headers = getattr(exc, "headers", None)
    
    else:
        # Handle any other exception as a SystemException
        system_exc = SystemException(
            message="An unexpected error occurred",
            details={"error_type": type(exc).__name__},
            original_exception=exc
        )
        
        # Use the built-in method to convert to HTTP exception
        http_exc = system_exc.to_http_exception()
        status_code = http_exc.status_code
        error_data = system_exc.to_dict()
        headers = None
    
    # Log the exception with request context
    log_exception(
        exc=exc,
        context={"request": request_details},
        logger=logger
    )
    
    # Return a JSON response with the error data
    return JSONResponse(
        status_code=status_code,
        content=error_data,
        headers=headers
    )


class ErrorHandlerMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware that catches exceptions and converts them to standardized error responses.
    """
    
    def __init__(self, app: ASGIApp):
        """
        Initialize the error handler middleware.
        
        Args:
            app: The ASGI application
        """
        super().__init__(app)
        self.logger = get_logger(__name__)
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process the request and handle any exceptions that occur.
        
        Args:
            request: The HTTP request
            call_next: Callable to process the request with the next middleware or route handler
            
        Returns:
            The HTTP response
        """
        try:
            # Process the request with the next middleware or route handler
            return await call_next(request)
        except Exception as exc:
            # If an exception occurs, convert it to a standardized error response
            self.logger.error(f"Exception during request processing: {str(exc)}")
            return create_error_response(exc, request)