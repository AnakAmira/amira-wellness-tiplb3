"""
Unit tests for the authentication service in the Amira Wellness application.
Tests user authentication, token management, password operations, and device registration functionality.
"""

import pytest
import uuid
import datetime
from unittest.mock import patch, MagicMock
import jwt
from datetime import timedelta

# Import test fixtures
from ..fixtures.database import test_db
from ..fixtures.users import regular_user, inactive_user, unverified_user, TEST_PASSWORD

# Import auth service functions
from ...app.services.auth import (
    login_user, register_user, refresh_token, logout_user,
    blacklist_token, is_token_blacklisted, clean_token_blacklist,
    reset_password_request, reset_password_confirm, change_password,
    verify_email, send_verification_email, register_device,
    validate_token, generate_auth_tokens, get_user_from_token,
    TOKEN_BLACKLIST
)

# Import security functions
from ...app.core.security import (
    create_access_token, create_refresh_token, decode_token, is_token_valid,
    generate_token_id, TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH,
    InvalidTokenError, TokenExpiredError
)

# Import schemas and models
from ...app.schemas.user import UserCreate, UserPasswordUpdate
from ...app.models.device import DevicePlatform
from ...app.core.exceptions import (
    AuthenticationException, ValidationException, ResourceNotFoundException
)


def test_login_user_success(test_db, regular_user):
    """Test successful user login with valid credentials"""
    response = login_user(test_db, regular_user.email, TEST_PASSWORD)
    
    # Check that response contains tokens and user information
    assert "tokens" in response
    assert "user" in response
    
    # Check token structure
    assert "access_token" in response["tokens"]
    assert "refresh_token" in response["tokens"]
    assert "token_type" in response["tokens"]
    assert "expires_in" in response["tokens"]
    assert response["tokens"]["token_type"] == "bearer"
    
    # Check user data
    assert response["user"]["email"] == regular_user.email


def test_login_user_invalid_credentials(test_db, regular_user):
    """Test login failure with invalid credentials"""
    with pytest.raises(AuthenticationException):
        login_user(test_db, regular_user.email, "wrong_password")


def test_login_user_inactive_account(test_db, inactive_user):
    """Test login failure with inactive user account"""
    with pytest.raises(AuthenticationException):
        login_user(test_db, inactive_user.email, TEST_PASSWORD)


def test_register_user_success(test_db):
    """Test successful user registration with valid data"""
    user_data = UserCreate(
        email="new_user@example.com",
        password="SecureP@ss123",
        password_confirm="SecureP@ss123",
        language_preference="ES"
    )
    
    new_user = register_user(test_db, user_data)
    
    # Check that user was created with correct data
    assert new_user is not None
    assert new_user.email == "new_user@example.com"
    assert new_user.email_verified is False
    assert new_user.account_status == "active"
    assert new_user.encryption_key_salt is not None


def test_register_user_duplicate_email(test_db, regular_user):
    """Test registration failure with duplicate email"""
    user_data = UserCreate(
        email=regular_user.email,
        password="AnotherP@ss123",
        password_confirm="AnotherP@ss123",
        language_preference="ES"
    )
    
    with pytest.raises(ValidationException):
        register_user(test_db, user_data)


def test_refresh_token_success(test_db, regular_user):
    """Test successful token refresh with valid refresh token"""
    # Generate a valid refresh token
    token_id = generate_token_id()
    refresh_token = create_refresh_token(regular_user.id, token_id)
    
    # Refresh the token
    tokens = refresh_token(test_db, refresh_token)
    
    # Check that new tokens are returned
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert "token_type" in tokens
    assert "expires_in" in tokens
    
    # Verify new tokens are different from the original
    assert tokens["refresh_token"] != refresh_token
    
    # Check that the original token is now blacklisted
    refresh_data = decode_token(refresh_token)
    assert is_token_blacklisted(refresh_data["jti"]) is True


def test_refresh_token_invalid_token(test_db):
    """Test token refresh failure with invalid token"""
    with pytest.raises(AuthenticationException):
        refresh_token(test_db, "invalid.token.string")


def test_refresh_token_blacklisted(test_db, regular_user):
    """Test token refresh failure with blacklisted token"""
    # Generate a valid token
    token_id = generate_token_id()
    token = create_refresh_token(regular_user.id, token_id)
    
    # Get the token_id from the token
    token_data = decode_token(token)
    token_id = token_data["jti"]
    
    # Blacklist the token
    blacklist_token(token_id, token_data["exp"], "manual_blacklist")
    
    # Try to refresh the token
    with pytest.raises(AuthenticationException):
        refresh_token(test_db, token)


def test_logout_user_success(test_db, regular_user):
    """Test successful user logout with valid refresh token"""
    # Generate a valid refresh token
    token_id = generate_token_id()
    token = create_refresh_token(regular_user.id, token_id)
    
    # Logout the user
    result = logout_user(test_db, regular_user.id, token)
    assert result["success"] is True
    
    # Check that the token is blacklisted
    token_data = decode_token(token)
    token_id = token_data["jti"]
    assert is_token_blacklisted(token_id) is True


@patch('src.backend.app.services.auth.device.deactivate_user_devices')
def test_logout_all_devices(mock_deactivate_devices, test_db, regular_user):
    """Test logging out all user devices"""
    # Configure the mock
    mock_deactivate_devices.return_value = True
    
    # Logout all devices
    result = logout_user(test_db, regular_user.id, None, all_devices=True)
    assert result["success"] is True
    
    # Verify that device.deactivate_user_devices was called with user_id
    mock_deactivate_devices.assert_called_once_with(test_db, regular_user.id)


def test_blacklist_token():
    """Test adding a token to the blacklist"""
    token_id = str(uuid.uuid4())
    expiration = datetime.datetime.utcnow() + timedelta(hours=1)
    reason = "test_blacklisting"
    
    # Blacklist the token
    blacklist_token(token_id, expiration.timestamp(), reason)
    
    # Check that token is blacklisted
    assert is_token_blacklisted(token_id) is True
    assert TOKEN_BLACKLIST[token_id]["reason"] == reason


def test_is_token_blacklisted():
    """Test checking if a token is blacklisted"""
    # Create a blacklisted token
    token_id = str(uuid.uuid4())
    expiration = datetime.datetime.utcnow() + timedelta(hours=1)
    blacklist_token(token_id, expiration.timestamp())
    
    # Check that it's blacklisted
    assert is_token_blacklisted(token_id) is True
    
    # Check that another token is not blacklisted
    another_token_id = str(uuid.uuid4())
    assert is_token_blacklisted(another_token_id) is False


def test_is_token_blacklisted_expired():
    """Test that expired blacklisted tokens are removed from blacklist"""
    # Create a token with past expiration
    token_id = str(uuid.uuid4())
    expiration = datetime.datetime.utcnow() - timedelta(hours=1)
    blacklist_token(token_id, expiration.timestamp())
    
    # Check that it's not considered blacklisted (it should be auto-removed)
    assert is_token_blacklisted(token_id) is False
    assert token_id not in TOKEN_BLACKLIST


def test_clean_token_blacklist():
    """Test cleaning expired tokens from the blacklist"""
    # Clear the blacklist first
    TOKEN_BLACKLIST.clear()
    
    # Add some tokens with future expiration
    future_tokens = []
    for i in range(3):
        token_id = str(uuid.uuid4())
        future_tokens.append(token_id)
        expiration = datetime.datetime.utcnow() + timedelta(hours=1)
        blacklist_token(token_id, expiration.timestamp())
    
    # Add some tokens with past expiration
    past_tokens = []
    for i in range(2):
        token_id = str(uuid.uuid4())
        past_tokens.append(token_id)
        expiration = datetime.datetime.utcnow() - timedelta(hours=1)
        blacklist_token(token_id, expiration.timestamp())
    
    # Clean the blacklist
    removed_count = clean_token_blacklist()
    
    # Check that past tokens were removed
    assert removed_count == 2
    for token_id in past_tokens:
        assert token_id not in TOKEN_BLACKLIST
    
    # Check that future tokens are still there
    for token_id in future_tokens:
        assert token_id in TOKEN_BLACKLIST


@patch('src.backend.app.services.auth.send_password_reset_email')
def test_reset_password_request_success(mock_send_email, test_db, regular_user):
    """Test successful password reset request"""
    # Configure the mock
    mock_send_email.return_value = True
    
    # Request password reset
    result = reset_password_request(test_db, regular_user.email)
    assert result is True
    
    # Verify email was sent
    mock_send_email.assert_called_once()
    assert mock_send_email.call_args[0][0] == regular_user.email
    assert mock_send_email.call_args[0][1] is not None  # Token


@patch('src.backend.app.services.auth.send_password_reset_email')
def test_reset_password_request_nonexistent_user(mock_send_email, test_db):
    """Test password reset request with nonexistent user"""
    # Request password reset for non-existent email
    result = reset_password_request(test_db, "nonexistent@example.com")
    assert result is False
    
    # Verify email was not sent
    mock_send_email.assert_not_called()


@patch('src.backend.app.services.auth.validate_reset_token')
@patch('src.backend.app.services.auth.user.update_password')
def test_reset_password_confirm_success(mock_update_password, mock_validate_token, test_db, regular_user):
    """Test successful password reset confirmation"""
    # Configure mocks
    mock_validate_token.return_value = regular_user.id
    mock_update_password.return_value = regular_user
    
    # Confirm password reset
    result = reset_password_confirm(test_db, "valid_token", "new_password")
    assert result is True
    
    # Verify token was validated
    mock_validate_token.assert_called_once_with("valid_token")
    
    # Verify password was updated
    mock_update_password.assert_called_once_with(test_db, regular_user.id, "new_password")


@patch('src.backend.app.services.auth.validate_reset_token')
def test_reset_password_confirm_invalid_token(mock_validate_token, test_db):
    """Test password reset confirmation with invalid token"""
    # Configure mock to raise exception
    mock_validate_token.side_effect = AuthenticationException("AUTH_INVALID_TOKEN", "Invalid token")
    
    # Attempt to confirm with invalid token
    with pytest.raises(AuthenticationException):
        reset_password_confirm(test_db, "invalid_token", "new_password")


def test_change_password_success(test_db, regular_user):
    """Test successful password change"""
    # Change password
    result = change_password(test_db, regular_user.id, TEST_PASSWORD, "new_password")
    assert result is True
    
    # Verify we can login with new password
    response = login_user(test_db, regular_user.email, "new_password")
    assert "user" in response
    assert response["user"]["email"] == regular_user.email


def test_change_password_incorrect_current(test_db, regular_user):
    """Test password change with incorrect current password"""
    with pytest.raises(ValidationException):
        change_password(test_db, regular_user.id, "wrong_password", "new_password")


@patch('src.backend.app.services.auth.validate_verification_token')
@patch('src.backend.app.services.auth.user.set_email_verified')
def test_verify_email_success(mock_set_verified, mock_validate_token, test_db, unverified_user):
    """Test successful email verification"""
    # Configure mocks
    mock_validate_token.return_value = unverified_user.id
    mock_set_verified.return_value = unverified_user
    
    # Verify email
    result = verify_email(test_db, "valid_token")
    assert result is True
    
    # Verify token was validated
    mock_validate_token.assert_called_once_with("valid_token")
    
    # Verify email was marked as verified
    mock_set_verified.assert_called_once_with(test_db, unverified_user.id)


@patch('src.backend.app.services.auth.validate_verification_token')
def test_verify_email_invalid_token(mock_validate_token, test_db):
    """Test email verification with invalid token"""
    # Configure mock to raise exception
    mock_validate_token.side_effect = AuthenticationException("AUTH_INVALID_TOKEN", "Invalid token")
    
    # Attempt to verify with invalid token
    with pytest.raises(AuthenticationException):
        verify_email(test_db, "invalid_token")


@patch('src.backend.app.services.auth.send_email_verification')
def test_send_verification_email_success(mock_send_email, test_db, unverified_user):
    """Test successful sending of verification email"""
    # Send verification email
    result = send_verification_email(test_db, unverified_user.id)
    assert result is True
    
    # Verify email was sent
    mock_send_email.assert_called_once()
    assert mock_send_email.call_args[0][0] == unverified_user.email
    assert mock_send_email.call_args[0][1] is not None  # Token


@patch('src.backend.app.services.auth.send_email_verification')
def test_send_verification_email_already_verified(mock_send_email, test_db, regular_user):
    """Test verification email for already verified user"""
    # Send verification email to already verified user
    result = send_verification_email(test_db, regular_user.id)
    assert result is False
    
    # Verify email was not sent
    mock_send_email.assert_not_called()


@patch('src.backend.app.services.auth.device.register_device')
def test_register_device_success(mock_register_device, test_db, regular_user):
    """Test successful device registration"""
    # Configure mock
    device_data = {
        "id": str(uuid.uuid4()),
        "name": "Test Device",
        "platform": DevicePlatform.IOS
    }
    mock_register_device.return_value = device_data
    
    # Register device
    device = register_device(
        test_db, 
        regular_user.id, 
        "device123", 
        DevicePlatform.IOS, 
        "Test iPhone", 
        "push_token123", 
        "1.0.0", 
        "iOS 15.0"
    )
    
    # Verify device was registered
    mock_register_device.assert_called_once_with(
        test_db, 
        regular_user.id,
        "device123",
        DevicePlatform.IOS,
        "Test iPhone",
        "push_token123",
        "1.0.0",
        "iOS 15.0",
        None
    )
    
    # Verify returned device
    assert device == device_data


def test_validate_token_success():
    """Test successful token validation"""
    # Create a valid token
    user_id = str(uuid.uuid4())
    token = create_access_token(user_id)
    
    # Validate the token
    payload = validate_token(token, TOKEN_TYPE_ACCESS)
    
    # Verify payload contains expected fields
    assert "sub" in payload
    assert payload["sub"] == user_id
    assert "type" in payload
    assert payload["type"] == TOKEN_TYPE_ACCESS
    assert "exp" in payload
    assert "iat" in payload


def test_validate_token_invalid():
    """Test token validation with invalid token"""
    with pytest.raises(InvalidTokenError):
        validate_token("invalid.token.string", TOKEN_TYPE_ACCESS)


def test_validate_token_wrong_type():
    """Test token validation with wrong token type"""
    # Create an access token
    user_id = str(uuid.uuid4())
    token = create_access_token(user_id)
    
    # Try to validate as refresh token
    with pytest.raises(InvalidTokenError):
        validate_token(token, TOKEN_TYPE_REFRESH)


def test_validate_token_blacklisted():
    """Test validation of blacklisted token"""
    # Create a token with a specific token_id
    token_id = generate_token_id()
    user_id = str(uuid.uuid4())
    token = create_refresh_token(user_id, token_id)
    
    # Blacklist the token
    token_data = decode_token(token)
    blacklist_token(token_data["jti"], token_data["exp"])
    
    # Try to validate the blacklisted token
    with pytest.raises(InvalidTokenError):
        validate_token(token, TOKEN_TYPE_REFRESH)


def test_generate_auth_tokens():
    """Test generation of authentication tokens"""
    # Generate tokens
    user_id = str(uuid.uuid4())
    tokens = generate_auth_tokens(user_id)
    
    # Verify token structure
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert "token_type" in tokens
    assert "expires_in" in tokens
    
    # Decode and verify tokens
    access_data = decode_token(tokens["access_token"])
    assert access_data["sub"] == user_id
    assert access_data["type"] == TOKEN_TYPE_ACCESS
    
    refresh_data = decode_token(tokens["refresh_token"])
    assert refresh_data["sub"] == user_id
    assert refresh_data["type"] == TOKEN_TYPE_REFRESH
    assert "jti" in refresh_data  # Has token ID


@patch('src.backend.app.services.auth.user.get')
def test_get_user_from_token(mock_get_user, test_db, regular_user):
    """Test retrieving user from token data"""
    # Configure mock
    mock_get_user.return_value = regular_user
    
    # Create token data
    token_data = {
        "sub": str(regular_user.id),
        "type": TOKEN_TYPE_ACCESS
    }
    
    # Get user from token
    user = get_user_from_token(test_db, token_data)
    
    # Verify user was retrieved
    mock_get_user.assert_called_once_with(test_db, regular_user.id)
    assert user == regular_user


@patch('src.backend.app.services.auth.user.get')
def test_get_user_from_token_not_found(mock_get_user, test_db):
    """Test user retrieval with nonexistent user"""
    # Configure mock
    mock_get_user.return_value = None
    
    # Create token data with random user ID
    user_id = str(uuid.uuid4())
    token_data = {
        "sub": user_id,
        "type": TOKEN_TYPE_ACCESS
    }
    
    # Try to get nonexistent user
    with pytest.raises(AuthenticationException):
        get_user_from_token(test_db, token_data)