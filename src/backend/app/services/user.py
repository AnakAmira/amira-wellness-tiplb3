"""
User service module that provides high-level business logic for user management
in the Amira Wellness application. This service acts as an intermediary between
the API layer and data access layer, implementing user-related operations such
as profile management, subscription handling, and user preferences while
enforcing business rules and privacy requirements.
"""

from typing import Dict, List, Optional, Tuple, Union, Any
import uuid

from sqlalchemy.orm import Session  # sqlalchemy v2.0+

from ..crud import user  # Internal import
from ..models.user import User  # Internal import
from ..schemas.user import UserCreate, UserUpdate, UserResponse, UserProfileResponse, UserPasswordUpdate  # Internal import
from ..core.logging import get_logger  # Internal import
from ..core.security import get_password_hash, verify_password  # Internal import
from ..core.exceptions import ValidationException, ResourceNotFoundException, AuthenticationException  # Internal import
from ..constants.languages import LanguageCode, DEFAULT_LANGUAGE  # Internal import
from .encryption import generate_user_encryption_key, derive_user_key_from_password  # Internal import

# Initialize logger
logger = get_logger(__name__)


def get_user_by_id(db: Session, user_id: str) -> User:
    """Retrieve a user by their ID

    Args:
        db: Database session
        user_id: User ID

    Returns:
        User: User object if found

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise ValidationException(
            message="Invalid user ID format",
            validation_errors=[{"field": "user_id", "message": "Must be a valid UUID"}],
            error_code="VAL_INVALID_INPUT"
        )

    db_user = user.get(db, user_uuid)
    if not db_user:
        logger.warning(f"User not found: {user_id}")
        raise ResourceNotFoundException(resource_type="user", resource_id=user_id)
    return db_user


def get_user_by_email(db: Session, email: str) -> User:
    """Retrieve a user by their email address

    Args:
        db: Database session
        email: Email address

    Returns:
        User: User object if found

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = user.get_by_email(db, email)
    if not db_user:
        logger.warning(f"User not found with email: {email}")
        raise ResourceNotFoundException(resource_type="user", resource_id=email)
    return db_user


def create_user(db: Session, user_data: UserCreate) -> User:
    """Create a new user account

    Args:
        db: Database session
        user_data: User creation data

    Returns:
        User: Created user object

    Raises:
        ValidationException: If the email is not available
    """
    if not user.is_email_available(db, user_data.email):
        logger.warning(f"Attempt to create user with existing email: {user_data.email}")
        raise ValidationException(
            message="Email already registered",
            validation_errors=[{"field": "email", "message": "Email already registered"}],
            error_code="VAL_DUPLICATE_ENTRY"
        )

    db_user = user.create(db, user_data)

    logger.info(f"Created new user with email: {db_user.email}")
    return db_user


def update_user_profile(db: Session, user_id: str, user_data: UserUpdate) -> User:
    """Update a user's profile information

    Args:
        db: Database session
        user_id: User ID
        user_data: User update data

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.update(db, db_user, user_data)
    logger.info(f"Updated user profile: {user_id}")
    return updated_user


def update_user_password(db: Session, user_id: str, password_data: UserPasswordUpdate) -> bool:
    """Update a user's password with verification

    Args:
        db: Database session
        user_id: User ID
        password_data: Password update data

    Returns:
        bool: True if password was updated successfully

    Raises:
        ResourceNotFoundException: If the user is not found
        ValidationException: If the current password is incorrect
    """
    db_user = get_user_by_id(db, user_id)
    user.update_password(db, db_user, password_data)
    logger.info(f"Updated password for user: {user_id}")
    return True


def update_language_preference(db: Session, user_id: str, language_code: LanguageCode) -> User:
    """Update a user's language preference

    Args:
        db: Database session
        user_id: User ID
        language_code: Language code

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
        ValidationException: If the language code is invalid
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.update_language_preference(db, db_user, language_code.value)
    logger.info(f"Updated language preference for user: {user_id} to {language_code}")
    return updated_user


def update_subscription_tier(db: Session, user_id: str, subscription_tier: str) -> User:
    """Update a user's subscription tier

    Args:
        db: Database session
        user_id: User ID
        subscription_tier: Subscription tier

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
        ValidationException: If the subscription tier is invalid
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.update_subscription(db, db_user, subscription_tier)
    logger.info(f"Updated subscription tier for user: {user_id} to {subscription_tier}")
    return updated_user


def deactivate_user(db: Session, user_id: str) -> User:
    """Deactivate a user account

    Args:
        db: Database session
        user_id: User ID

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.deactivate(db, db_user)
    logger.info(f"Deactivated user: {user_id}")
    return updated_user


def reactivate_user(db: Session, user_id: str) -> User:
    """Reactivate a previously deactivated user account

    Args:
        db: Database session
        user_id: User ID

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.reactivate(db, db_user)
    logger.info(f"Reactivated user: {user_id}")
    return updated_user


def get_user_profile(db: Session, user_id: str) -> Dict:
    """Get a user's complete profile information

    Args:
        db: Database session
        user_id: User ID

    Returns:
        Dict: User profile data

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    # TODO: Retrieve additional user-related data (e.g., activity statistics)
    profile_data = {
        "id": db_user.id,
        "email": db_user.email,
        "language_preference": db_user.language_preference,
        "subscription_tier": db_user.subscription_tier
    }
    logger.info(f"Retrieved profile for user: {user_id}")
    return profile_data


def check_email_availability(db: Session, email: str) -> bool:
    """Check if an email address is available for registration

    Args:
        db: Database session
        email: Email address

    Returns:
        bool: True if email is available, False if already in use
    """
    is_available = user.is_email_available(db, email)
    logger.debug(f"Checked email availability: {email} - Available: {is_available}")
    return is_available


def get_user_encryption_key_salt(db: Session, user_id: str) -> Optional[str]:
    """Get the salt used for deriving a user's encryption key

    Args:
        db: Database session
        user_id: User ID

    Returns:
        Optional[str]: The encryption key salt or None if not set

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    salt = user.get_encryption_key_salt(db_user)
    if salt:
        logger.debug(f"Retrieved encryption key salt for user: {user_id}")
    else:
        logger.debug(f"No encryption key salt found for user: {user_id}")
    return salt


def store_user_encryption_key_salt(db: Session, user_id: str, salt: str) -> User:
    """Store the salt used for deriving a user's encryption key

    Args:
        db: Database session
        user_id: User ID
        salt: Salt value to store

    Returns:
        User: Updated user object

    Raises:
        ResourceNotFoundException: If the user is not found
    """
    db_user = get_user_by_id(db, user_id)
    updated_user = user.store_encryption_key_salt(db, db_user, salt)
    logger.info(f"Stored encryption key salt for user: {user_id}")
    return updated_user


def generate_user_key(db: Session, user_id: str, password: Optional[str] = None) -> Tuple[bytes, Optional[bytes]]:
    """Generate or derive an encryption key for a user

    Args:
        db: Database session
        user_id: User ID
        password: User password (optional, if deriving from password)

    Returns:
        Tuple[bytes, Optional[bytes]]: Tuple containing the key and salt (or None if generated)

    Raises:
        ResourceNotFoundException: If the user is not found
        EncryptionKeyError: If key generation fails
    """
    db_user = get_user_by_id(db, user_id)

    if password:
        # Retrieve existing salt if available
        salt = get_user_encryption_key_salt(db, user_id)
        if salt:
            salt = salt.encode('utf-8')
        key, salt = derive_user_key_from_password(password, salt)
        if salt and db_user.encryption_key_salt is None:
            store_user_encryption_key_salt(db, user_id, salt.decode('utf-8'))
        logger.info(f"Derived encryption key from password for user {user_id}")
    else:
        key = generate_user_encryption_key(user_id)
        salt = None
        logger.info(f"Generated random encryption key for user {user_id}")

    return key, salt