import json
import uuid
import re
from typing import Dict, Any

import pytest
import httpx

from ..fixtures.users import TEST_PASSWORD
from ..fixtures.database import test_db
from ...app.models.device import DevicePlatform

# Auth API prefix
AUTH_PREFIX = '/auth'

@pytest.mark.integration
def test_login_success(app_client, regular_user):
    """Test successful user login with valid credentials"""
    # Create login data
    login_data = {
        "email": regular_user.email,
        "password": TEST_PASSWORD
    }
    
    # Send login request
    response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains tokens and user data
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user" in data
    assert data["user"]["email"] == regular_user.email

@pytest.mark.integration
def test_login_invalid_credentials(app_client, regular_user):
    """Test login failure with invalid credentials"""
    # Create login data with wrong password
    login_data = {
        "email": regular_user.email,
        "password": "wrongpassword123"
    }
    
    # Send login request
    response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "Invalid credentials" in data["detail"]

@pytest.mark.integration
def test_login_inactive_user(app_client, inactive_user):
    """Test login failure with inactive user account"""
    # Create login data
    login_data = {
        "email": inactive_user.email,
        "password": TEST_PASSWORD
    }
    
    # Send login request
    response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "Account is inactive" in data["detail"]

@pytest.mark.integration
def test_login_suspended_user(app_client, suspended_user):
    """Test login failure with suspended user account"""
    # Create login data
    login_data = {
        "email": suspended_user.email,
        "password": TEST_PASSWORD
    }
    
    # Send login request
    response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "Account is suspended" in data["detail"]

@pytest.mark.integration
def test_register_success(app_client, test_db):
    """Test successful user registration with valid data"""
    # Create unique email for test
    email = f"test_register_{uuid.uuid4()}@example.com"
    
    # Create registration data
    register_data = {
        "email": email,
        "password": "SecurePassword123!",
        "password_confirm": "SecurePassword123!"
    }
    
    # Send registration request
    response = app_client.post(f"{AUTH_PREFIX}/register", json=register_data)
    
    # Assert response status code is 201
    assert response.status_code == 201
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains user_id and success message
    assert "user_id" in data
    assert "message" in data
    assert "success" in data["message"].lower()
    
    # Verify user exists in database
    from ...app.models.user import User
    user = test_db.query(User).filter(User.email == email).first()
    assert user is not None
    assert user.email == email

@pytest.mark.integration
def test_register_existing_email(app_client, regular_user):
    """Test registration failure with existing email"""
    # Create registration data with existing email
    register_data = {
        "email": regular_user.email,
        "password": "SecurePassword123!",
        "password_confirm": "SecurePassword123!"
    }
    
    # Send registration request
    response = app_client.post(f"{AUTH_PREFIX}/register", json=register_data)
    
    # Assert response status code is 400
    assert response.status_code == 400
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "already exists" in data["detail"].lower() or "already in use" in data["detail"].lower()

@pytest.mark.integration
def test_register_password_mismatch(app_client):
    """Test registration failure with password mismatch"""
    # Create unique email for test
    email = f"test_mismatch_{uuid.uuid4()}@example.com"
    
    # Create registration data with mismatched passwords
    register_data = {
        "email": email,
        "password": "SecurePassword123!",
        "password_confirm": "DifferentPassword123!"
    }
    
    # Send registration request
    response = app_client.post(f"{AUTH_PREFIX}/register", json=register_data)
    
    # Assert response status code is 400
    assert response.status_code == 400
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "password" in data["detail"].lower() and "match" in data["detail"].lower()

@pytest.mark.integration
def test_register_weak_password(app_client):
    """Test registration failure with weak password"""
    # Create unique email for test
    email = f"test_weak_{uuid.uuid4()}@example.com"
    
    # Create registration data with weak password
    register_data = {
        "email": email,
        "password": "weakpass",
        "password_confirm": "weakpass"
    }
    
    # Send registration request
    response = app_client.post(f"{AUTH_PREFIX}/register", json=register_data)
    
    # Assert response status code is 400
    assert response.status_code == 400
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "password" in data["detail"].lower() and "requirements" in data["detail"].lower()

@pytest.mark.integration
def test_refresh_token_success(app_client, regular_user):
    """Test successful token refresh with valid refresh token"""
    # Login to get initial tokens
    login_data = {
        "email": regular_user.email,
        "password": TEST_PASSWORD
    }
    
    login_response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    assert login_response.status_code == 200
    
    login_data = login_response.json()
    refresh_token = login_data["refresh_token"]
    
    # Create refresh request
    refresh_data = {
        "refresh_token": refresh_token
    }
    
    # Send refresh request
    refresh_response = app_client.post(f"{AUTH_PREFIX}/refresh", json=refresh_data)
    
    # Assert response status code is 200
    assert refresh_response.status_code == 200
    
    # Parse response JSON
    data = refresh_response.json()
    
    # Assert response contains new tokens
    assert "access_token" in data
    assert "refresh_token" in data
    
    # Verify new tokens are different
    assert data["access_token"] != login_data["access_token"]
    assert data["refresh_token"] != login_data["refresh_token"]

@pytest.mark.integration
def test_refresh_token_invalid(app_client):
    """Test token refresh failure with invalid refresh token"""
    # Create refresh request data with invalid token
    refresh_data = {
        "refresh_token": "invalid_token_here"
    }
    
    # Send refresh request
    response = app_client.post(f"{AUTH_PREFIX}/refresh", json=refresh_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "invalid" in data["detail"].lower() or "invalid token" in data["detail"].lower()

@pytest.mark.integration
def test_logout_success(app_client, regular_user, auth_headers):
    """Test successful logout with valid refresh token"""
    # Login to get tokens
    login_data = {
        "email": regular_user.email,
        "password": TEST_PASSWORD
    }
    
    login_response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    assert login_response.status_code == 200
    
    login_data = login_response.json()
    refresh_token = login_data["refresh_token"]
    
    # Create logout request data
    logout_data = {
        "refresh_token": refresh_token
    }
    
    # Send logout request
    logout_response = app_client.post(
        f"{AUTH_PREFIX}/logout",
        json=logout_data,
        headers=auth_headers
    )
    
    # Assert response status code is 200
    assert logout_response.status_code == 200
    
    # Parse response JSON
    data = logout_response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "logged out" in data["message"].lower() or "success" in data["message"].lower()
    
    # Try to use the refresh token again and verify it fails
    refresh_data = {
        "refresh_token": refresh_token
    }
    
    refresh_response = app_client.post(f"{AUTH_PREFIX}/refresh", json=refresh_data)
    assert refresh_response.status_code == 401

@pytest.mark.integration
def test_logout_all_devices(app_client, regular_user, auth_headers):
    """Test successful logout from all devices"""
    # Create logout request data with all_devices flag
    logout_data = {
        "all_devices": True
    }
    
    # Send logout request
    response = app_client.post(
        f"{AUTH_PREFIX}/logout",
        json=logout_data,
        headers=auth_headers
    )
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "all devices" in data["message"].lower() or "all sessions" in data["message"].lower()

@pytest.mark.integration
def test_reset_password_request(app_client, regular_user):
    """Test password reset request with valid email"""
    # Create password reset request data
    reset_data = {
        "email": regular_user.email
    }
    
    # Send reset password request
    response = app_client.post(f"{AUTH_PREFIX}/reset-password", json=reset_data)
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "email" in data["message"].lower() or "instructions" in data["message"].lower()

@pytest.mark.integration
def test_reset_password_confirm(app_client, test_db, regular_user):
    """Test password reset confirmation with valid token"""
    # Create mock reset token
    reset_token = str(uuid.uuid4())
    
    # Store token in test database
    from ...app.models.user import User
    from ...app.core.security import get_password_hash
    
    # In a real implementation, you would create a password reset entry in your database
    # For this test, we'll assume the token is directly associated with the user
    user = test_db.query(User).filter(User.id == regular_user.id).first()
    # Mock setting a reset token in user record or separate table
    
    # Create password reset confirmation data
    reset_confirm_data = {
        "token": reset_token,
        "password": "NewSecurePassword123!",
        "password_confirm": "NewSecurePassword123!"
    }
    
    # Send reset password confirmation request
    response = app_client.post(f"{AUTH_PREFIX}/reset-password-confirm", json=reset_confirm_data)
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "password" in data["message"].lower() and "reset" in data["message"].lower()
    
    # Verify user can login with new password
    login_data = {
        "email": regular_user.email,
        "password": "NewSecurePassword123!"
    }
    
    login_response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    assert login_response.status_code == 200

@pytest.mark.integration
def test_reset_password_invalid_token(app_client):
    """Test password reset confirmation failure with invalid token"""
    # Create password reset confirmation data with invalid token
    reset_confirm_data = {
        "token": "invalid_token_here",
        "password": "NewSecurePassword123!",
        "password_confirm": "NewSecurePassword123!"
    }
    
    # Send reset password confirmation request
    response = app_client.post(f"{AUTH_PREFIX}/reset-password-confirm", json=reset_confirm_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "invalid" in data["detail"].lower() or "expired" in data["detail"].lower()

@pytest.mark.integration
def test_change_password(app_client, auth_headers, regular_user):
    """Test password change with valid current password"""
    # Create password change data
    change_data = {
        "current_password": TEST_PASSWORD,
        "new_password": "NewSecurePassword123!",
        "new_password_confirm": "NewSecurePassword123!"
    }
    
    # Send change password request
    response = app_client.post(
        f"{AUTH_PREFIX}/change-password",
        json=change_data,
        headers=auth_headers
    )
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "password" in data["message"].lower() and "changed" in data["message"].lower()
    
    # Verify user can login with new password
    login_data = {
        "email": regular_user.email,
        "password": "NewSecurePassword123!"
    }
    
    login_response = app_client.post(f"{AUTH_PREFIX}/login", json=login_data)
    assert login_response.status_code == 200
    
    # Verify user cannot login with old password
    old_login_data = {
        "email": regular_user.email,
        "password": TEST_PASSWORD
    }
    
    old_login_response = app_client.post(f"{AUTH_PREFIX}/login", json=old_login_data)
    assert old_login_response.status_code == 401

@pytest.mark.integration
def test_change_password_incorrect_current(app_client, auth_headers):
    """Test password change failure with incorrect current password"""
    # Create password change data with incorrect current password
    change_data = {
        "current_password": "WrongCurrentPassword123!",
        "new_password": "NewSecurePassword123!",
        "new_password_confirm": "NewSecurePassword123!"
    }
    
    # Send change password request
    response = app_client.post(
        f"{AUTH_PREFIX}/change-password",
        json=change_data,
        headers=auth_headers
    )
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "current password" in data["detail"].lower() and "incorrect" in data["detail"].lower()

@pytest.mark.integration
def test_verify_email(app_client, test_db, unverified_user):
    """Test email verification with valid token"""
    # Create mock verification token
    verification_token = str(uuid.uuid4())
    
    # Store token in test database
    from ...app.models.user import User
    
    # In a real implementation, you would create a verification entry in your database
    # For this test, we'll assume the token is directly associated with the user
    user = test_db.query(User).filter(User.id == unverified_user.id).first()
    # Mock setting a verification token in user record or separate table
    
    # Create verification request data
    verification_data = {
        "token": verification_token
    }
    
    # Send verify email request
    response = app_client.post(f"{AUTH_PREFIX}/verify-email", json=verification_data)
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "verified" in data["message"].lower() or "success" in data["message"].lower()
    
    # Verify user's email_verified flag is now True
    user = test_db.query(User).filter(User.id == unverified_user.id).first()
    assert user.email_verified is True

@pytest.mark.integration
def test_verify_email_invalid_token(app_client):
    """Test email verification failure with invalid token"""
    # Create verification request data with invalid token
    verification_data = {
        "token": "invalid_token_here"
    }
    
    # Send verify email request
    response = app_client.post(f"{AUTH_PREFIX}/verify-email", json=verification_data)
    
    # Assert response status code is 401
    assert response.status_code == 401
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains error detail
    assert "detail" in data
    assert "invalid" in data["detail"].lower() or "expired" in data["detail"].lower()

@pytest.mark.integration
def test_resend_verification_email(app_client, auth_headers):
    """Test resending verification email"""
    # Send resend verification request
    response = app_client.post(
        f"{AUTH_PREFIX}/resend-verification",
        headers=auth_headers
    )
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains success message
    assert "message" in data
    assert "email" in data["message"].lower() and "sent" in data["message"].lower()

@pytest.mark.integration
def test_register_device(app_client, auth_headers):
    """Test device registration for a user"""
    # Generate unique device_id
    device_id = str(uuid.uuid4())
    
    # Create device registration data
    device_data = {
        "device_id": device_id,
        "device_name": "Test Device",
        "platform": DevicePlatform.IOS.value,
        "push_token": "test_push_token_123",
        "app_version": "1.0.0",
        "os_version": "15.0"
    }
    
    # Send device registration request
    response = app_client.post(
        f"{AUTH_PREFIX}/devices",
        json=device_data,
        headers=auth_headers
    )
    
    # Assert response status code is 201
    assert response.status_code == 201
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains device information
    assert "device_id" in data
    assert data["device_id"] == device_id
    assert "device_name" in data
    assert data["device_name"] == "Test Device"
    assert "platform" in data
    assert data["platform"] == DevicePlatform.IOS.value

@pytest.mark.integration
def test_health_check(app_client):
    """Test health check endpoint"""
    # Send health check request
    response = app_client.get(f"{AUTH_PREFIX}/health")
    
    # Assert response status code is 200
    assert response.status_code == 200
    
    # Parse response JSON
    data = response.json()
    
    # Assert response contains service and status
    assert "service" in data
    assert "status" in data
    assert data["status"] == "ok"