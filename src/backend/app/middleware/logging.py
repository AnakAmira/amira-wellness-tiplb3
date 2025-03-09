import time
import typing
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp

from ..core.logging import (
    get_logger,
    get_correlation_id,
    set_correlation_id,
    log_request,
    log_response
)

# Initialize logger
logger = get_logger(__name__)

# Paths that should be excluded from detailed logging
EXCLUDED_PATHS = ['/api/v1/health', '/metrics', '/docs', '/redoc', '/openapi.json']

class LoggingMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware that logs HTTP requests and responses with privacy protection
    and performance metrics.
    """
    
    def __init__(self, app: ASGIApp):
        """
        Initializes the logging middleware.
        
        Args:
            app: The ASGI application
        """
        super().__init__(app)
        self.logger = get_logger(__name__)
    
    async def dispatch(self, request: Request, call_next: typing.Callable) -> Response:
        """
        Processes HTTP requests and logs request/response details.
        
        Args:
            request: The HTTP request
            call_next: The next middleware or route handler
            
        Returns:
            The HTTP response from the application
        """
        # Skip logging for excluded paths
        if self.is_path_excluded(request.url.path):
            return await call_next(request)
        
        # Get or generate correlation ID
        correlation_id = self.get_correlation_id_from_request(request)
        
        # Set correlation ID in current context
        set_correlation_id(correlation_id)
        
        # Store correlation ID in request state for use in route handlers
        request.state.correlation_id = correlation_id
        
        # Record request start time
        start_time = time.time()
        
        # Log request details
        log_request(request, self.logger)
        
        # Process the request
        response = await call_next(request)
        
        # Calculate request duration
        duration = time.time() - start_time
        
        # Log response details
        log_response(response, duration, self.logger)
        
        # Add correlation ID to response headers
        response.headers["X-Correlation-ID"] = correlation_id
        
        return response
    
    def is_path_excluded(self, path: str) -> bool:
        """
        Checks if a request path should be excluded from logging.
        
        Args:
            path: The request path
            
        Returns:
            True if the path should be excluded, False otherwise
        """
        if path in EXCLUDED_PATHS:
            return True
        
        # Also exclude Swagger UI assets
        if path.startswith('/docs/') or path.startswith('/redoc/'):
            return True
        
        return False
    
    def get_correlation_id_from_request(self, request: Request) -> str:
        """
        Extracts correlation ID from request headers or generates a new one.
        
        Args:
            request: The HTTP request
            
        Returns:
            Correlation ID for request tracing
        """
        # Check for existing correlation ID in headers
        if "X-Correlation-ID" in request.headers:
            return request.headers["X-Correlation-ID"]
        
        # Generate a new correlation ID if not found
        return get_correlation_id()