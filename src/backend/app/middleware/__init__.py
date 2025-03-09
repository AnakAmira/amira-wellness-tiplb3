"""Initialization module for the middleware package in the Amira Wellness application.
This module exports all middleware components for use in the main application, providing centralized access to authentication, logging, error handling, and rate limiting functionality.
"""

from .logging import LoggingMiddleware  # Import logging middleware for request/response tracking
from .error_handler import ErrorHandlerMiddleware, create_error_response  # Import error handling middleware for centralized exception handling and utility function for creating standardized error responses
from .authentication import AuthenticationMiddleware  # Import authentication middleware for JWT validation
from .rate_limiter import RateLimiterMiddleware  # Import rate limiting middleware for API protection
from ..core.logging import get_logger  # Import logging utility function

# Initialize logger for this module
logger = get_logger(__name__)

# Define the list of exported middleware components
__all__ = ["LoggingMiddleware", "ErrorHandlerMiddleware", "AuthenticationMiddleware", "RateLimiterMiddleware", "create_error_response"]


def get_middleware_stack() -> list:
    """Returns the middleware stack in the recommended order of application

    Returns:
        list: List of middleware classes in recommended application order
    """
    # Return a list containing middleware classes in the recommended order: ErrorHandlerMiddleware, LoggingMiddleware, AuthenticationMiddleware, RateLimiterMiddleware
    return [
        ErrorHandlerMiddleware,
        LoggingMiddleware,
        AuthenticationMiddleware,
        RateLimiterMiddleware,
    ]