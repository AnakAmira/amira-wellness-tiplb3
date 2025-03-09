"""
CRUD operations for user management in the Amira Wellness application.
Extends the base CRUD class with user-specific functionality for creating,
retrieving, updating, and deleting user accounts with secure password handling.
"""

from typing import Optional, Dict, Any, Union
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate, UserPasswordUpdate
from ..core.security import get_password_hash, verify_password
from ..core.logging import get_logger
from ..core.exceptions import ValidationException, ResourceNotFoundException
from ..constants.languages import DEFAULT_LANGUAGE, LanguageCode, is_language_available

# Initialize logger
logger = get_logger(__name__)


class CRUDUser(CRUDBase[User, UserCreate, UserUpdate]):
    """CRUD operations for User model with additional user-specific functionality"""
    
    def __init__(self):
        """Initialize the CRUD operations for User model"""
        super().__init__(User)
    
    def get_by_email(self, db: Session, email: str) -> Optional[User]:
        """Get a user by email address
        
        Args:
            db: Database session
            email: Email address to search for
            
        Returns:
            User if found, None otherwise
        """
        query = select(self.model).where(self.model.email == email)
        result = db.execute(query).scalars().first()
        return result
    
    def create(self, db: Session, obj_in: UserCreate) -> User:
        """Create a new user with password hashing
        
        Args:
            db: Database session
            obj_in: User creation data with validated fields
            
        Returns:
            Created user instance
            
        Raises:
            ValidationException: If a user with the same email already exists
        """
        # Check if user with the same email already exists
        existing_user = self.get_by_email(db, obj_in.email)
        if existing_user:
            logger.warning(f"Attempted to create user with existing email: {obj_in.email}")
            raise ValidationException(
                message=f"User with email {obj_in.email} already exists",
                validation_errors=[{"field": "email", "message": "Email already registered"}],
                error_code="VAL_DUPLICATE_ENTRY"
            )
        
        # Hash the password
        hashed_password = get_password_hash(obj_in.password)
        
        # Create user data dictionary
        user_data = obj_in.model_dump(exclude={"password", "password_confirm"})
        user_data["password_hash"] = hashed_password
        user_data["email_verified"] = False
        user_data["account_status"] = "active"
        user_data["subscription_tier"] = "free"
        
        # Ensure language preference is set (default if not provided)
        if "language_preference" not in user_data or user_data["language_preference"] is None:
            user_data["language_preference"] = DEFAULT_LANGUAGE
        
        # Call parent create method
        db_obj = super().create(db, user_data)
        logger.info(f"Created new user with email: {db_obj.email}")
        
        return db_obj
    
    def update(self, db: Session, db_obj: User, obj_in: Union[UserUpdate, Dict[str, Any]]) -> User:
        """Update user information
        
        Args:
            db: Database session
            db_obj: Existing user object to update
            obj_in: Data to update (schema or dict)
            
        Returns:
            Updated user instance
        """
        # Call parent update method
        updated_user = super().update(db, db_obj, obj_in)
        logger.info(f"Updated user: {updated_user.id}")
        return updated_user
    
    def update_password(self, db: Session, user: User, password_update: UserPasswordUpdate) -> User:
        """Update user password with verification
        
        Args:
            db: Database session
            user: User to update
            password_update: Password update data with current and new password
            
        Returns:
            Updated user instance
            
        Raises:
            ValidationException: If current password is incorrect
        """
        # Verify current password
        if not verify_password(password_update.current_password, user.password_hash):
            logger.warning(f"Password update failed - incorrect current password for user: {user.id}")
            raise ValidationException(
                message="Current password is incorrect",
                validation_errors=[{"field": "current_password", "message": "Current password is incorrect"}],
                error_code="VAL_INVALID_INPUT"
            )
        
        # Hash the new password
        hashed_password = get_password_hash(password_update.new_password)
        
        # Update user's password
        user.set_password(hashed_password)
        
        # Commit changes
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logger.info(f"Password updated for user: {user.id}")
        return user
    
    def authenticate(self, db: Session, email: str, password: str) -> Optional[User]:
        """Authenticate a user with email and password
        
        Args:
            db: Database session
            email: User's email
            password: User's password
            
        Returns:
            Authenticated user or None if authentication fails
        """
        # Get user by email
        user = self.get_by_email(db, email)
        if not user:
            logger.info(f"Authentication failed - user not found: {email}")
            return None
        
        # Verify password
        if not verify_password(password, user.password_hash):
            logger.info(f"Authentication failed - incorrect password for user: {email}")
            return None
        
        # Update last login timestamp
        self.update_last_login(db, user)
        logger.info(f"User authenticated successfully: {email}")
        
        return user
    
    def is_active(self, user: User) -> bool:
        """Check if a user account is active
        
        Args:
            user: User to check
            
        Returns:
            True if user is active, False otherwise
        """
        return user.is_active()
    
    def is_email_available(self, db: Session, email: str) -> bool:
        """Check if an email address is available for registration
        
        Args:
            db: Database session
            email: Email to check
            
        Returns:
            True if email is available, False if already in use
        """
        user = self.get_by_email(db, email)
        return user is None
    
    def set_email_verified(self, db: Session, user: User) -> User:
        """Mark a user's email as verified
        
        Args:
            db: Database session
            user: User to update
            
        Returns:
            Updated user instance
        """
        user.email_verified = True
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Email verified for user: {user.id}")
        return user
    
    def update_last_login(self, db: Session, user: User) -> User:
        """Update a user's last login timestamp
        
        Args:
            db: Database session
            user: User to update
            
        Returns:
            Updated user instance
        """
        user.update_last_login()
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    
    def deactivate(self, db: Session, user: User) -> User:
        """Deactivate a user account
        
        Args:
            db: Database session
            user: User to deactivate
            
        Returns:
            Updated user instance
        """
        user.account_status = "inactive"
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"User account deactivated: {user.id}")
        return user
    
    def reactivate(self, db: Session, user: User) -> User:
        """Reactivate a deactivated user account
        
        Args:
            db: Database session
            user: User to reactivate
            
        Returns:
            Updated user instance
        """
        user.account_status = "active"
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"User account reactivated: {user.id}")
        return user
    
    def update_subscription(self, db: Session, user: User, subscription_tier: str) -> User:
        """Update a user's subscription tier
        
        Args:
            db: Database session
            user: User to update
            subscription_tier: New subscription tier ('free' or 'premium')
            
        Returns:
            Updated user instance
            
        Raises:
            ValidationException: If subscription tier is invalid
        """
        # Validate subscription tier
        if subscription_tier not in ["free", "premium"]:
            raise ValidationException(
                message="Invalid subscription tier",
                validation_errors=[{"field": "subscription_tier", "message": "Must be 'free' or 'premium'"}],
                error_code="VAL_INVALID_INPUT"
            )
        
        user.subscription_tier = subscription_tier
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Subscription updated for user {user.id}: {subscription_tier}")
        return user
    
    def update_language_preference(self, db: Session, user: User, language_code: str) -> User:
        """Update a user's language preference
        
        Args:
            db: Database session
            user: User to update
            language_code: Language code to set
            
        Returns:
            Updated user instance
            
        Raises:
            ValidationException: If language code is invalid or not available
        """
        # Validate language code
        try:
            # Convert string to enum value
            lang_code = LanguageCode(language_code)
            
            # Check if the language is available
            if not is_language_available(lang_code):
                raise ValidationException(
                    message=f"Language {language_code} is not available",
                    validation_errors=[{"field": "language_preference", "message": "Language not available"}],
                    error_code="VAL_INVALID_INPUT"
                )
            
            # Set the language preference
            user.language_preference = lang_code
            db.add(user)
            db.commit()
            db.refresh(user)
            logger.info(f"Language preference updated for user {user.id}: {language_code}")
            return user
            
        except ValueError:
            raise ValidationException(
                message=f"Invalid language code: {language_code}",
                validation_errors=[{"field": "language_preference", "message": "Invalid language code"}],
                error_code="VAL_INVALID_INPUT"
            )
    
    def store_encryption_key_salt(self, db: Session, user: User, salt: str) -> User:
        """Store the salt used for deriving user's encryption key
        
        Args:
            db: Database session
            user: User to update
            salt: Salt value to store
            
        Returns:
            Updated user instance
        """
        user.encryption_key_salt = salt
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Encryption key salt stored for user: {user.id}")
        return user
    
    def get_encryption_key_salt(self, user: User) -> Optional[str]:
        """Get the salt used for deriving user's encryption key
        
        Args:
            user: User to get salt for
            
        Returns:
            The encryption key salt or None if not set
        """
        return user.encryption_key_salt


# Create singleton instance for application-wide use
user = CRUDUser()