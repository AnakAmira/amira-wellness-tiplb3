"""
Test fixture module that provides user-related fixtures for unit and integration tests in the Amira Wellness application.
Creates various user test objects with different account statuses, subscription tiers, and language preferences to support
comprehensive testing of user-related functionality.
"""

import pytest
import uuid
import datetime

from ...app.models.user import User
from ...app.constants.languages import LanguageCode
from ...app.core.security import get_password_hash
from .database import test_db

# Constants for test data
TEST_PASSWORD = "securepassword123"
TEST_PASSWORD_HASH = get_password_hash(TEST_PASSWORD)

def create_test_user(
    email: str,
    password_hash: str,
    email_verified: bool,
    account_status: str,
    subscription_tier: str,
    language_preference: LanguageCode
) -> User:
    """
    Helper function to create a test user with specified attributes.
    
    Args:
        email: User's email address
        password_hash: Hashed password
        email_verified: Whether the email is verified
        account_status: Account status (active, inactive, suspended)
        subscription_tier: Subscription tier (free, premium)
        language_preference: User's language preference
        
    Returns:
        User instance with specified attributes
    """
    # Create a new user
    user = User(
        email=email,
        password_hash=password_hash,
        email_verified=email_verified,
        account_status=account_status,
        subscription_tier=subscription_tier,
        language_preference=language_preference
    )
    
    return user

@pytest.fixture
def regular_user(test_db):
    """
    Creates a standard active user for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with standard active account
    """
    user = create_test_user(
        email="regular@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="active",
        subscription_tier="free",
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def premium_user(test_db):
    """
    Creates a premium subscription user for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with premium subscription
    """
    user = create_test_user(
        email="premium@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="active",
        subscription_tier="premium",
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def inactive_user(test_db):
    """
    Creates an inactive user for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with inactive account
    """
    user = create_test_user(
        email="inactive@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="inactive",
        subscription_tier="free",
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def unverified_user(test_db):
    """
    Creates a user with unverified email for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with unverified email
    """
    user = create_test_user(
        email="unverified@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=False,
        account_status="active",
        subscription_tier="free",
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def admin_user(test_db):
    """
    Creates an admin user for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with admin privileges
    """
    # Since there's no obvious admin field in the User model,
    # we're creating a regular user with an admin-like email.
    # The admin status would be determined by application logic elsewhere.
    user = create_test_user(
        email="admin@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="active",
        subscription_tier="premium",  # Admins might have premium access
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def suspended_user(test_db):
    """
    Creates a suspended user for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with suspended account
    """
    user = create_test_user(
        email="suspended@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="suspended",
        subscription_tier="free",
        language_preference=LanguageCode.ES
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user

@pytest.fixture
def latam_user(test_db):
    """
    Creates a user with Latin American Spanish preference for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        User instance with Latin American Spanish language preference
    """
    user = create_test_user(
        email="latam@example.com",
        password_hash=TEST_PASSWORD_HASH,
        email_verified=True,
        account_status="active",
        subscription_tier="free",
        language_preference=LanguageCode.ES_LATAM
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user