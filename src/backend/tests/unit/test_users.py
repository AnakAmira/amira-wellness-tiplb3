import pytest
from uuid import uuid4

from src.backend.app.models.user import User
from src.backend.app.crud.user import CRUDUser, user
from src.backend.app.schemas.user import UserCreate, UserUpdate, UserPasswordUpdate
from src.backend.app.constants.languages import LanguageCode, DEFAULT_LANGUAGE
from src.backend.app.core.security import get_password_hash, verify_password
from src.backend.app.core.exceptions import ValidationException, ResourceNotFoundException
from src.backend.tests.fixtures.database import test_db
from src.backend.tests.fixtures.users import regular_user, premium_user, inactive_user, unverified_user

# Import pytest
import pytest

# Import uuid for generating unique identifiers
import uuid

def test_create_user(test_db):
    """Test creating a new user with valid data"""
    # Create a UserCreate object with valid email and matching passwords
    user_create = UserCreate(email="test@example.com", password="securePassword1!", password_confirm="securePassword1!")
    
    # Call user.create to create the user
    created_user = user.create(test_db, user_create)
    
    # Assert that the created user has the expected email
    assert created_user.email == "test@example.com"
    
    # Assert that the created user has a password_hash
    assert created_user.password_hash is not None
    
    # Assert that the created user has the default language preference
    assert created_user.language_preference == DEFAULT_LANGUAGE
    
    # Assert that the created user has account_status set to 'active'
    assert created_user.account_status == "active"
    
    # Assert that the created user has email_verified set to False
    assert created_user.email_verified is False

def test_create_user_duplicate_email(test_db, regular_user):
    """Test that creating a user with an existing email raises ValidationException"""
    # Create a UserCreate object with the same email as regular_user
    user_create = UserCreate(email=regular_user.email, password="securePassword1!", password_confirm="securePassword1!")
    
    # Use pytest.raises to assert that ValidationException is raised
    with pytest.raises(ValidationException) as exc_info:
        # Call user.create inside the context manager to verify the exception is raised
        user.create(test_db, user_create)
    
    # Assert that the exception message is correct
    assert "User with email" in str(exc_info.value)

def test_get_user_by_email(test_db, regular_user):
    """Test retrieving a user by email"""
    # Call user.get_by_email with the regular_user's email
    retrieved_user = user.get_by_email(test_db, regular_user.email)
    
    # Assert that the returned user is not None
    assert retrieved_user is not None
    
    # Assert that the returned user's email matches the regular_user's email
    assert retrieved_user.email == regular_user.email
    
    # Assert that the returned user's id matches the regular_user's id
    assert retrieved_user.id == regular_user.id

def test_get_user_by_email_not_found(test_db):
    """Test retrieving a non-existent user by email returns None"""
    # Call user.get_by_email with a non-existent email
    retrieved_user = user.get_by_email(test_db, "nonexistent@example.com")
    
    # Assert that the returned value is None
    assert retrieved_user is None

def test_authenticate_user_valid(test_db, regular_user):
    """Test authenticating a user with valid credentials"""
    # Call user.authenticate with the regular_user's email and the test password
    authenticated_user = user.authenticate(test_db, regular_user.email, "securepassword123")
    
    # Assert that the returned user is not None
    assert authenticated_user is not None
    
    # Assert that the returned user's email matches the regular_user's email
    assert authenticated_user.email == regular_user.email
    
    # Assert that the returned user's last_login is updated
    assert authenticated_user.last_login is not None

def test_authenticate_user_invalid_password(test_db, regular_user):
    """Test authenticating a user with invalid password returns None"""
    # Call user.authenticate with the regular_user's email and an incorrect password
    authenticated_user = user.authenticate(test_db, regular_user.email, "incorrect_password")
    
    # Assert that the returned value is None
    assert authenticated_user is None

def test_authenticate_user_not_found(test_db):
    """Test authenticating a non-existent user returns None"""
    # Call user.authenticate with a non-existent email and any password
    authenticated_user = user.authenticate(test_db, "nonexistent@example.com", "any_password")
    
    # Assert that the returned value is None
    assert authenticated_user is None

def test_update_user(test_db, regular_user):
    """Test updating user information"""
    # Create a UserUpdate object with updated language_preference
    user_update = UserUpdate(language_preference=LanguageCode.EN)
    
    # Call user.update with the regular_user and the update object
    updated_user = user.update(test_db, regular_user, user_update)
    
    # Assert that the updated user's language_preference matches the new value
    assert updated_user.language_preference == LanguageCode.EN

def test_update_password(test_db, regular_user):
    """Test updating a user's password"""
    # Create a UserPasswordUpdate object with current password and new password
    password_update = UserPasswordUpdate(current_password="securepassword123", new_password="newSecurePassword4!", new_password_confirm="newSecurePassword4!")
    
    # Call user.update_password with the regular_user and the password update object
    updated_user = user.update_password(test_db, regular_user, password_update)
    
    # Assert that the updated user's password_hash is different from the original
    assert updated_user.password_hash != regular_user.password_hash
    
    # Verify that authentication works with the new password
    assert user.authenticate(test_db, regular_user.email, "newSecurePassword4!") is not None
    
    # Verify that authentication fails with the old password
    assert user.authenticate(test_db, regular_user.email, "securepassword123") is None

def test_update_password_invalid_current(test_db, regular_user):
    """Test updating password with invalid current password raises ValidationException"""
    # Create a UserPasswordUpdate object with incorrect current password and new password
    password_update = UserPasswordUpdate(current_password="incorrect_password", new_password="newSecurePassword4!", new_password_confirm="newSecurePassword4!")
    
    # Use pytest.raises to assert that ValidationException is raised
    with pytest.raises(ValidationException) as exc_info:
        # Call user.update_password inside the context manager to verify the exception is raised
        user.update_password(test_db, regular_user, password_update)
    
    # Assert that the exception message is correct
    assert "Current password is incorrect" in str(exc_info.value)

def test_is_active(regular_user, inactive_user):
    """Test checking if a user is active"""
    # Call user.is_active with the regular_user
    assert user.is_active(regular_user) is True
    
    # Call user.is_active with the inactive_user
    assert user.is_active(inactive_user) is False

def test_is_email_available(test_db, regular_user):
    """Test checking if an email is available for registration"""
    # Call user.is_email_available with the regular_user's email
    assert user.is_email_available(test_db, regular_user.email) is False
    
    # Call user.is_email_available with a new, unused email
    assert user.is_email_available(test_db, "new@example.com") is True

def test_set_email_verified(test_db, unverified_user):
    """Test marking a user's email as verified"""
    # Assert that the unverified_user's email_verified is False
    assert unverified_user.email_verified is False
    
    # Call user.set_email_verified with the unverified_user
    updated_user = user.set_email_verified(test_db, unverified_user)
    
    # Assert that the updated user's email_verified is True
    assert updated_user.email_verified is True

def test_update_last_login(test_db, regular_user):
    """Test updating a user's last login timestamp"""
    # Store the original last_login value
    original_last_login = regular_user.last_login
    
    # Call user.update_last_login with the regular_user
    updated_user = user.update_last_login(test_db, regular_user)
    
    # Assert that the updated user's last_login is different from the original
    assert updated_user.last_login != original_last_login

def test_deactivate_user(test_db, regular_user):
    """Test deactivating a user account"""
    # Assert that the regular_user's account_status is 'active'
    assert regular_user.account_status == "active"
    
    # Call user.deactivate with the regular_user
    updated_user = user.deactivate(test_db, regular_user)
    
    # Assert that the updated user's account_status is 'inactive'
    assert updated_user.account_status == "inactive"
    
    # Assert that user.is_active returns False for the updated user
    assert user.is_active(updated_user) is False

def test_reactivate_user(test_db, inactive_user):
    """Test reactivating a deactivated user account"""
    # Assert that the inactive_user's account_status is 'inactive'
    assert inactive_user.account_status == "inactive"
    
    # Call user.reactivate with the inactive_user
    updated_user = user.reactivate(test_db, inactive_user)
    
    # Assert that the updated user's account_status is 'active'
    assert updated_user.account_status == "active"
    
    # Assert that user.is_active returns True for the updated user
    assert user.is_active(updated_user) is True

def test_update_subscription(test_db, regular_user):
    """Test updating a user's subscription tier"""
    # Assert that the regular_user's subscription_tier is 'free'
    assert regular_user.subscription_tier == "free"
    
    # Call user.update_subscription with the regular_user and 'premium'
    updated_user = user.update_subscription(test_db, regular_user, "premium")
    
    # Assert that the updated user's subscription_tier is 'premium'
    assert updated_user.subscription_tier == "premium"
    
    # Assert that user.is_premium returns True for the updated user
    assert user.is_premium(updated_user) is True

def test_update_subscription_invalid(test_db, regular_user):
    """Test updating a user's subscription tier with invalid value raises ValidationException"""
    # Use pytest.raises to assert that ValidationException is raised
    with pytest.raises(ValidationException) as exc_info:
        # Call user.update_subscription with the regular_user and an invalid tier inside the context manager
        user.update_subscription(test_db, regular_user, "invalid_tier")
    
    # Assert that the exception message is correct
    assert "Invalid subscription tier" in str(exc_info.value)

def test_update_language_preference(test_db, regular_user):
    """Test updating a user's language preference"""
    # Assert that the regular_user's language_preference is the default
    assert regular_user.language_preference == DEFAULT_LANGUAGE
    
    # Call user.update_language_preference with the regular_user and a different language code
    updated_user = user.update_language_preference(test_db, regular_user, LanguageCode.EN.value)
    
    # Assert that the updated user's language_preference matches the new value
    assert updated_user.language_preference == LanguageCode.EN

def test_update_language_preference_invalid(test_db, regular_user):
    """Test updating a user's language preference with invalid value raises ValidationException"""
    # Use pytest.raises to assert that ValidationException is raised
    with pytest.raises(ValidationException) as exc_info:
        # Call user.update_language_preference with the regular_user and an invalid language code inside the context manager
        user.update_language_preference(test_db, regular_user, "invalid_language")
    
    # Assert that the exception message is correct
    assert "Invalid language code" in str(exc_info.value)

def test_store_encryption_key_salt(test_db, regular_user):
    """Test storing a user's encryption key salt"""
    # Generate a random salt string
    salt = uuid.uuid4().hex
    
    # Call user.store_encryption_key_salt with the regular_user and the salt
    updated_user = user.store_encryption_key_salt(test_db, regular_user, salt)
    
    # Assert that the updated user's encryption_key_salt matches the provided salt
    assert updated_user.encryption_key_salt == salt

def test_get_encryption_key_salt(test_db, regular_user):
    """Test retrieving a user's encryption key salt"""
    # Generate a random salt string
    salt = uuid.uuid4().hex
    
    # Call user.store_encryption_key_salt with the regular_user and the salt
    user.store_encryption_key_salt(test_db, regular_user, salt)
    
    # Call user.get_encryption_key_salt with the updated user
    retrieved_salt = user.get_encryption_key_salt(regular_user)
    
    # Assert that the returned salt matches the stored salt
    assert retrieved_salt == salt