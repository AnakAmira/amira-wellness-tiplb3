"""
Authentication middleware for the Amira Wellness application.

This module implements a FastAPI middleware that intercepts incoming requests,
validates JWT tokens, and sets authenticated user information in the request state.
It supports the privacy-first approach by ensuring proper authentication for
accessing sensitive user data while allowing public routes to bypass authentication.
"""

from typing import Optional

from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp

from ..core.security import decode_token, InvalidTokenError, TokenExpiredError
from ..core.config import settings
from ..core.exceptions import AuthenticationException
from ..core.logging import get_logger
from ..crud.user import user
from ..db.session import get_db

# Initialize logger
logger = get_logger(__name__)

# Define public paths that don't require authentication
PUBLIC_PATHS = [
    '/api/v1/auth/login', 
    '/api/v1/auth/register', 
    '/api/v1/auth/refresh', 
    '/api/v1/auth/password-reset', 
    '/api/v1/auth/password-reset-confirm', 
    '/api/v1/auth/verify-email', 
    '/api/v1/health', 
    '/docs', 
    '/redoc', 
    '/openapi.json'
]


def is_path_public(path: str) -> bool:
    """
    Determines if a request path should bypass authentication.
    
    Args:
        path: URL path to check
        
    Returns:
        True if the path is public, False otherwise
    """
    # Check if path is in the explicit public paths list
    if path in PUBLIC_PATHS:
        return True
    
    # Special handling for documentation paths which may have query parameters
    documentation_paths = ['/docs', '/redoc', '/openapi.json']
    if any(path.startswith(doc_path) for doc_path in documentation_paths):
        return True
    
    # Path requires authentication
    return False


def extract_token_from_header(request: Request) -> Optional[str]:
    """
    Extracts the JWT token from the Authorization header.
    
    Args:
        request: The incoming HTTP request
        
    Returns:
        The extracted token or None if not found
    """
    authorization = request.headers.get("Authorization")
    
    if not authorization:
        return None
    
    # Check if the header has the Bearer prefix
    if not authorization.startswith("Bearer "):
        return None
    
    # Extract the token part
    token = authorization.replace("Bearer ", "")
    
    if not token:
        return None
    
    return token


def get_current_user_from_token(token: str) -> Optional[any]:
    """
    Retrieves the current user based on the JWT token.
    
    Args:
        token: The JWT token to validate
        
    Returns:
        The authenticated user or None if token is invalid
    """
    try:
        # Decode and validate the token
        payload = decode_token(token)
        
        # Extract user email from token subject
        email = payload.get("sub")
        if not email:
            logger.warning("Token missing subject claim")
            return None
        
        # Get database session
        db = next(get_db())
        
        # Get user by email
        current_user = user.get_by_email(db, email)
        
        # Verify user exists and is active
        if not current_user:
            logger.warning(f"User not found for token: {email}")
            return None
        
        if not user.is_active(current_user):
            logger.warning(f"Inactive user attempted access: {email}")
            return None
        
        return current_user
        
    except (InvalidTokenError, TokenExpiredError) as e:
        logger.warning(f"Token validation failed: {str(e)}")
        return None
    except Exception as e:
        logger.error(f"Error processing token: {str(e)}")
        return None


class AuthenticationMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware that handles authentication for all requests.
    
    This middleware intercepts incoming requests, validates JWT tokens,
    and sets the authenticated user in the request state for access by route handlers.
    """
    
    def __init__(self, app: ASGIApp):
        """
        Initializes the authentication middleware.
        
        Args:
            app: The ASGI application
        """
        super().__init__(app)
        self.logger = get_logger(__name__)
    
    async def dispatch(self, request: Request, call_next) -> Response:
        """
        Processes HTTP requests and handles authentication.
        
        Args:
            request: The incoming HTTP request
            call_next: The next middleware in the chain
            
        Returns:
            The HTTP response from the application
        """
        # Get request path and check if it's public
        path = request.url.path
        
        # Set default user to None (unauthenticated)
        request.state.user = None
        
        # If path is public, skip authentication
        if is_path_public(path):
            self.logger.debug(f"Public path accessed: {path}")
            return await call_next(request)
        
        # For non-public paths, extract token from header
        token = extract_token_from_header(request)
        
        if token:
            # Try to get user from token
            try:
                request.state.user = get_current_user_from_token(token)
                
                if request.state.user:
                    self.logger.debug(f"Authenticated user: {request.state.user.email}")
                else:
                    self.logger.debug("Invalid token, proceeding as unauthenticated")
                    
            except Exception as e:
                self.logger.error(f"Error during authentication: {str(e)}")
                # Continue without authentication rather than rejecting the request
                # The actual route handler will enforce authentication if needed
        else:
            self.logger.debug(f"No authentication token for path: {path}")
        
        # Continue processing the request
        response = await call_next(request)
        return response