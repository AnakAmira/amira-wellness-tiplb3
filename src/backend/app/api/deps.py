"""
Dependency injection module for FastAPI endpoints.

This module provides reusable dependencies for authentication, database sessions,
user validation, and rate limiting. It centralizes common dependencies used across
API routes to ensure consistent behavior and security enforcement.
"""

from typing import Optional, Annotated, Callable, Generator

from fastapi import Depends, HTTPException, status, Security, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession

# Internal imports
from ..db.session import get_db, get_async_db
from ..core.config import settings
from ..core.security import decode_token, is_token_valid, TOKEN_TYPE_ACCESS
from ..models.user import User
from ..crud.user import user
from ..core.exceptions import AuthenticationException, PermissionDeniedException, ResourceNotFoundException
from ..core.logging import get_logger
from ..middleware.rate_limiter import get_client_identifier

# Initialize logger
logger = get_logger(__name__)

# OAuth2 bearer token schema
oauth2_scheme = HTTPBearer(auto_error=False)

def get_current_user(
    db: Session = Depends(get_db),
    credentials: HTTPAuthorizationCredentials = Security(oauth2_scheme)
) -> User:
    """
    Dependency that extracts and validates the current user from JWT token.
    
    Args:
        db: Database session
        credentials: HTTP Authorization credentials
        
    Returns:
        Authenticated user model instance
        
    Raises:
        AuthenticationException: If authentication fails
    """
    # Check if credentials are provided
    if not credentials:
        logger.warning("Authentication failed: No token provided")
        raise AuthenticationException(
            error_code="AUTH_MISSING_TOKEN"
        )
    
    token = credentials.credentials
    
    # Validate token
    if not is_token_valid(token):
        logger.warning("Authentication failed: Invalid token")
        raise AuthenticationException(
            error_code="AUTH_INVALID_TOKEN"
        )
    
    # Decode token to get payload
    try:
        payload = decode_token(token)
        
        # Check token type
        if payload.get("type") != TOKEN_TYPE_ACCESS:
            logger.warning("Authentication failed: Invalid token type")
            raise AuthenticationException(
                error_code="AUTH_INVALID_TOKEN_TYPE"
            )
        
        # Extract user_id from token subject
        user_id = payload.get("sub")
        if not user_id:
            logger.warning("Authentication failed: Token missing subject claim")
            raise AuthenticationException(
                error_code="AUTH_INVALID_TOKEN"
            )
        
        # Get user from database
        current_user = user.get(db, user_id)
        if not current_user:
            logger.warning(f"Authentication failed: User not found for ID {user_id}")
            raise ResourceNotFoundException(resource_type="user", resource_id=user_id)
        
        # Check if user is active
        if not current_user.is_active():
            logger.warning(f"Authentication failed: User {user_id} is inactive")
            raise AuthenticationException(
                error_code="AUTH_INACTIVE_USER"
            )
        
        return current_user
    except AuthenticationException:
        # Re-raise authentication exceptions
        raise
    except Exception as e:
        # Log and convert other exceptions to authentication error
        logger.error(f"Authentication error: {str(e)}")
        raise AuthenticationException(
            error_code="AUTH_INVALID_TOKEN"
        )

def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency that ensures the current user is active.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        Active user model instance
        
    Raises:
        AuthenticationException: If user is inactive
    """
    if not current_user.is_active():
        logger.warning(f"Access denied: User {current_user.id} is inactive")
        raise AuthenticationException(
            error_code="AUTH_INACTIVE_USER"
        )
    return current_user

def get_current_premium_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency that ensures the current user has premium subscription.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        Premium user model instance
        
    Raises:
        PermissionDeniedException: If user doesn't have premium subscription
    """
    if not current_user.is_premium():
        logger.warning(f"Premium access denied: User {current_user.id} doesn't have premium subscription")
        raise PermissionDeniedException(
            message="Premium subscription required for this feature",
            error_code="PERM_PREMIUM_REQUIRED"
        )
    return current_user

def get_optional_current_user(
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Security(oauth2_scheme)
) -> Optional[User]:
    """
    Dependency that extracts the current user if token is provided, but doesn't require authentication.
    
    Args:
        db: Database session
        credentials: Optional HTTP Authorization credentials
        
    Returns:
        Authenticated user or None if no valid token
    """
    if not credentials:
        return None
    
    try:
        # Validate and decode token
        if not is_token_valid(credentials.credentials):
            return None
        
        payload = decode_token(credentials.credentials)
        
        # Check token type
        if payload.get("type") != TOKEN_TYPE_ACCESS:
            return None
        
        # Extract user_id from token subject
        user_id = payload.get("sub")
        if not user_id:
            return None
        
        # Get user from database
        current_user = user.get(db, user_id)
        if not current_user or not current_user.is_active():
            return None
        
        return current_user
    except Exception as e:
        logger.debug(f"Optional authentication failed: {str(e)}")
        return None

def get_client_rate_limit_key(
    request: Request,
    current_user: Optional[User] = Depends(get_optional_current_user)
) -> str:
    """
    Dependency that generates a rate limit key for the current client.
    
    Args:
        request: HTTP request
        current_user: Optional authenticated user
        
    Returns:
        Rate limit key for the client
    """
    # Get client identifier (IP address)
    client_id = get_client_identifier(request)
    
    # If user is authenticated, use user ID in the rate limit key
    if current_user:
        return f"{client_id}:user:{current_user.id}"
    
    # Otherwise, use just the client identifier
    return client_id

def validate_resource_ownership(resource_type: str, get_resource_owner_id: Callable) -> Callable:
    """
    Generic dependency factory for validating resource ownership.
    
    This function returns a dependency that ensures the current user is the owner of a resource.
    
    Args:
        resource_type: Type of resource being validated (for error messages)
        get_resource_owner_id: Function that retrieves the owner ID of the resource
        
    Returns:
        Dependency function that validates resource ownership
    """
    def dependency(
        resource_id: str,
        current_user: User = Depends(get_current_user)
    ) -> None:
        # Get the owner ID of the resource
        owner_id = get_resource_owner_id(resource_id)
        
        # Check if current user is the owner
        if str(current_user.id) != str(owner_id):
            logger.warning(f"Ownership validation failed: User {current_user.id} attempted to access {resource_type} {resource_id} owned by {owner_id}")
            raise PermissionDeniedException(
                message=f"You do not have permission to access this {resource_type}",
                error_code="PERM_RESOURCE_ACCESS_DENIED"
            )
    
    return dependency