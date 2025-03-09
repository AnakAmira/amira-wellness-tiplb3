import json
import uuid
import typing

import pytest  # pytest 7.0+

from ..conftest import app_client, auth_headers, premium_auth_headers, admin_auth_headers
from ..fixtures.users import regular_user, premium_user, admin_user, inactive_user
from ..fixtures.database import test_db
from ...app.constants.languages import LanguageCode

USERS_PREFIX = "/users"


@pytest.mark.integration
def test_get_current_user_profile(app_client, auth_headers, regular_user):
    """Test retrieving the current user's profile."""
    response = app_client.get(f"{USERS_PREFIX}/me", headers=auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == str(regular_user.id)
    assert data["email"] == regular_user.email
    assert data["account_status"] == "active"
    assert data["is_active"] is True
    assert data["subscription_tier"] == "free"
    assert data["is_premium"] is False


@pytest.mark.integration
def test_get_current_user_profile_premium(app_client, premium_auth_headers, premium_user):
    """Test retrieving a premium user's profile."""
    response = app_client.get(f"{USERS_PREFIX}/me", headers=premium_auth_headers)
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == str(premium_user.id)
    assert data["subscription_tier"] == "premium"
    assert data["is_premium"] is True


@pytest.mark.integration
def test_update_current_user_profile(app_client, auth_headers, regular_user):
    """Test updating the current user's profile."""
    update_data = {
        "language_preference": LanguageCode.ES_LATAM.value
    }
    
    response = app_client.patch(
        f"{USERS_PREFIX}/me", 
        headers=auth_headers,
        json=update_data
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == str(regular_user.id)
    assert data["language_preference"] == "es-la"


@pytest.mark.integration
def test_update_language_preference(app_client, auth_headers, regular_user):
    """Test updating the user's language preference directly."""
    response = app_client.patch(
        f"{USERS_PREFIX}/me/language",
        headers=auth_headers,
        json={"language_code": LanguageCode.EN.value}
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["language_preference"] == "en"


@pytest.mark.integration
def test_deactivate_account(app_client, auth_headers, regular_user, test_db):
    """Test deactivating a user account."""
    response = app_client.post(
        f"{USERS_PREFIX}/me/deactivate",
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert "success" in data
    
    # Verify account is now inactive in database
    test_db.refresh(regular_user)
    assert regular_user.account_status == "inactive"
    assert regular_user.is_active() is False


@pytest.mark.integration
def test_reactivate_account(app_client, auth_headers, inactive_user, test_db):
    """Test reactivating a previously deactivated account."""
    response = app_client.post(
        f"{USERS_PREFIX}/me/reactivate",
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert "success" in data
    
    # Verify account is now active in database
    test_db.refresh(inactive_user)
    assert inactive_user.account_status == "active"
    assert inactive_user.is_active() is True


@pytest.mark.integration
def test_reactivate_already_active_account(app_client, auth_headers):
    """Test attempting to reactivate an already active account."""
    response = app_client.post(
        f"{USERS_PREFIX}/me/reactivate",
        headers=auth_headers
    )
    assert response.status_code == 400
    
    data = response.json()
    assert "error" in data
    assert "already active" in data["error"].lower()


@pytest.mark.integration
def test_get_user_by_id_admin(app_client, admin_auth_headers, regular_user):
    """Test admin retrieving a user profile by ID."""
    response = app_client.get(
        f"{USERS_PREFIX}/{regular_user.id}",
        headers=admin_auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == str(regular_user.id)
    assert data["email"] == regular_user.email


@pytest.mark.integration
def test_get_user_by_id_non_admin(app_client, auth_headers, premium_user):
    """Test non-admin attempting to retrieve a user profile by ID."""
    response = app_client.get(
        f"{USERS_PREFIX}/{premium_user.id}",
        headers=auth_headers
    )
    assert response.status_code == 403
    
    data = response.json()
    assert "error" in data
    assert "permission" in data["error"].lower()


@pytest.mark.integration
def test_get_user_by_id_not_found(app_client, admin_auth_headers):
    """Test retrieving a non-existent user profile by ID."""
    random_uuid = str(uuid.uuid4())
    response = app_client.get(
        f"{USERS_PREFIX}/{random_uuid}",
        headers=admin_auth_headers
    )
    assert response.status_code == 404
    
    data = response.json()
    assert "error" in data
    assert "not found" in data["error"].lower()


@pytest.mark.integration
def test_update_user_by_id_admin(app_client, admin_auth_headers, regular_user):
    """Test admin updating a user profile by ID."""
    update_data = {
        "subscription_tier": "premium"
    }
    
    response = app_client.patch(
        f"{USERS_PREFIX}/{regular_user.id}",
        headers=admin_auth_headers,
        json=update_data
    )
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == str(regular_user.id)
    assert data["subscription_tier"] == "premium"
    assert data["is_premium"] is True


@pytest.mark.integration
def test_update_user_by_id_non_admin(app_client, auth_headers, premium_user):
    """Test non-admin attempting to update a user profile by ID."""
    update_data = {
        "subscription_tier": "free"
    }
    
    response = app_client.patch(
        f"{USERS_PREFIX}/{premium_user.id}",
        headers=auth_headers,
        json=update_data
    )
    assert response.status_code == 403
    
    data = response.json()
    assert "error" in data
    assert "permission" in data["error"].lower()


@pytest.mark.integration
def test_update_user_by_id_not_found(app_client, admin_auth_headers):
    """Test updating a non-existent user profile by ID."""
    random_uuid = str(uuid.uuid4())
    update_data = {
        "subscription_tier": "premium"
    }
    
    response = app_client.patch(
        f"{USERS_PREFIX}/{random_uuid}",
        headers=admin_auth_headers,
        json=update_data
    )
    assert response.status_code == 404
    
    data = response.json()
    assert "error" in data
    assert "not found" in data["error"].lower()


@pytest.mark.integration
def test_get_user_data_export(app_client, auth_headers):
    """Test generating a user data export."""
    response = app_client.get(
        f"{USERS_PREFIX}/me/export",
        headers=auth_headers
    )
    assert response.status_code == 200
    
    data = response.json()
    assert "download_url" in data
    assert "expiration_time" in data
    assert data["download_url"].startswith("http")
    # Verify expiration_time is a valid timestamp in the future
    assert "T" in data["expiration_time"]  # ISO format timestamp


@pytest.mark.integration
def test_health_check(app_client):
    """Test health check endpoint for user service."""
    response = app_client.get(f"{USERS_PREFIX}/health")
    assert response.status_code == 200
    
    data = response.json()
    assert "service" in data
    assert "status" in data
    assert data["service"] == "user_service"
    assert data["status"] == "healthy"