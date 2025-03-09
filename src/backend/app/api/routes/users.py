"""
API routes for user management in the Amira Wellness application.
Implements endpoints for retrieving, updating, and managing user profiles with proper authentication and authorization controls.
"""

from typing import List, Optional, Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

# Internal imports
from ..api import deps
from ..api.deps import get_db, get_current_user, get_current_active_user, validate_resource_ownership
from ..models.user import User
from ..schemas.user import UserUpdate, UserResponse, UserProfileResponse
from ..crud import user
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException, PermissionDeniedException, ValidationException
from ..constants.languages import LanguageCode

# External imports
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status  # fastapi 0.104+
from sqlalchemy.orm import Session  # sqlalchemy.orm 2.0+
from uuid import UUID  # standard library

# Initialize logger
logger = get_logger(__name__)

# API router instance
router = APIRouter(prefix='/users', tags=['Users'])


@router.get('/me', response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserProfileResponse:
    """
    Get the current user's profile information
    """
    logger.info(f"Retrieving profile for user: {current_user.id}")
    return current_user


@router.patch('/me', response_model=UserResponse, status_code=status.HTTP_200_OK)
def update_current_user_profile(
    user_update: UserUpdate = Depends(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Update the current user's profile information
    """
    logger.info(f"Updating profile for user: {current_user.id}")
    updated_user = user.update(db, db_obj=current_user, obj_in=user_update)
    return updated_user


@router.patch('/me/language', response_model=UserResponse, status_code=status.HTTP_200_OK)
def update_language_preference(
    language_code: LanguageCode = Depends(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Update the current user's language preference
    """
    logger.info(f"Updating language preference for user: {current_user.id} to {language_code}")
    updated_user = user.update_language_preference(db, user=current_user, language_code=language_code.value)
    return updated_user


@router.post('/me/deactivate', status_code=status.HTTP_200_OK)
def deactivate_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    """
    Deactivate the current user's account
    """
    logger.info(f"Deactivating account for user: {current_user.id}")
    user.deactivate(db, user=current_user)
    return {"message": "Account deactivated successfully"}


@router.post('/me/reactivate', status_code=status.HTTP_200_OK)
def reactivate_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    """
    Reactivate a previously deactivated account
    """
    logger.info(f"Reactivating account for user: {current_user.id}")
    if current_user.account_status != "inactive":
        raise ValidationException(
            message="Account is not inactive",
            validation_errors=[{"field": "account_status", "message": "Account is not inactive"}],
            error_code="VAL_INVALID_INPUT"
        )
    user.reactivate(db, user=current_user)
    return {"message": "Account reactivated successfully"}


@router.get('/{user_id}', response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
def get_user_by_id(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserProfileResponse:
    """
    Get a user's profile by ID (admin only)
    """
    logger.info(f"Retrieving user with ID: {user_id}")
    if not current_user.is_active():
        raise PermissionDeniedException(message="Inactive users cannot access this resource")
    if not current_user.is_premium():
        raise PermissionDeniedException(message="Premium users cannot access this resource")
    db_user = user.get(db, user_id)
    if not db_user:
        raise ResourceNotFoundException(resource_type="user", resource_id=user_id)
    return db_user


@router.patch('/{user_id}', response_model=UserResponse, status_code=status.HTTP_200_OK)
def update_user_by_id(
    user_id: UUID,
    user_update: UserUpdate = Depends(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Update a user's profile by ID (admin only)
    """
    logger.info(f"Updating user with ID: {user_id}")
    if not current_user.is_active():
        raise PermissionDeniedException(message="Inactive users cannot access this resource")
    if not current_user.is_premium():
        raise PermissionDeniedException(message="Premium users cannot access this resource")
    db_user = user.get(db, user_id)
    if not db_user:
        raise ResourceNotFoundException(resource_type="user", resource_id=user_id)
    updated_user = user.update(db, db_obj=db_user, obj_in=user_update)
    return updated_user


@router.get('/me/export', status_code=status.HTTP_200_OK)
def get_user_data_export(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    """
    Generate and return a data export for the current user
    """
    logger.info(f"Exporting data for user: {current_user.id}")
    # TODO: Implement data export service
    download_url = "https://example.com/user_data_export.zip"  # Replace with actual URL
    expiration_time = "24 hours"  # Replace with actual expiration
    return {"download_url": download_url, "expires_in": expiration_time}


@router.get('/health', status_code=status.HTTP_200_OK)
def health_check() -> dict:
    """
    Health check endpoint for user service
    """
    return {"service": "user", "status": "healthy"}