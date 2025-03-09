import os
import sys
import logging

import pytest

from .fixtures.database import test_db, test_async_db, override_dependencies, setup_test_db
from ..app.db.session import Base

# Environment variable for test configuration
TEST_ENV = os.environ.get('TEST_ENV', 'test')


def pytest_configure(config):
    """
    Pytest hook that runs before test collection to configure the test environment.
    
    Args:
        config: pytest.Config
    """
    # Set environment variables for testing
    os.environ["ENVIRONMENT"] = "test"
    os.environ["TESTING"] = "true"
    
    # Configure logging for tests
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    
    # Initialize test database schema
    setup_test_db()
    
    # Register custom markers
    config.addinivalue_line("markers", "unit: mark a test as a unit test")
    config.addinivalue_line("markers", "integration: mark a test as an integration test")
    config.addinivalue_line("markers", "api: mark a test as an API test")
    config.addinivalue_line("markers", "slow: mark a test as slow running")


def pytest_collection_modifyitems(config, items):
    """
    Pytest hook that runs after test collection to modify test items.
    
    Args:
        config: pytest.Config
        items: list[pytest.Item]
    """
    # Add markers based on path/name
    for item in items:
        # Mark tests based on directory/module naming
        if "unit" in item.nodeid:
            item.add_marker(pytest.mark.unit)
        
        if "integration" in item.nodeid:
            item.add_marker(pytest.mark.integration)
        
        if "api" in item.nodeid:
            item.add_marker(pytest.mark.api)
        
        # Skip tests based on environment if needed
        if TEST_ENV == "quick" and "slow" in item.keywords:
            item.add_marker(pytest.mark.skip(reason="Skipping slow test in quick mode"))


@pytest.fixture(scope="session")
def app():
    """
    Provides a test instance of the FastAPI application.
    
    Returns:
        FastAPI application instance
    """
    # Import here to avoid circular imports
    from ..app.main import app as fastapi_app
    
    # Return the app instance
    return fastapi_app


@pytest.fixture(scope="function")
def client(app):
    """
    Provides a test client for the FastAPI application.
    
    Args:
        app: app
    
    Returns:
        TestClient instance
    """
    # Import here to avoid circular imports
    from fastapi.testclient import TestClient
    
    # Apply dependency overrides
    override_dependencies(app)
    
    # Create a test client
    return TestClient(app)


@pytest.fixture(scope="function")
def auth_headers():
    """
    Provides authentication headers for authenticated API requests.
    
    Returns:
        Dict with Authorization header
    """
    # Import here to avoid circular imports
    from jose import jwt
    from ..app.core.config import settings
    
    # Create a test JWT token
    payload = {
        "sub": "test-user@example.com",
        "user_id": "test-user-id",
        "role": "user",
        "exp": 9999999999  # Far future expiration
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    # Return headers with the token
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(scope="function")
def admin_auth_headers():
    """
    Provides authentication headers for admin API requests.
    
    Returns:
        Dict with Authorization header for admin user
    """
    # Import here to avoid circular imports
    from jose import jwt
    from ..app.core.config import settings
    
    # Create a test admin JWT token
    payload = {
        "sub": "test-admin@example.com",
        "user_id": "test-admin-id",
        "role": "admin",
        "exp": 9999999999  # Far future expiration
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    # Return headers with the token
    return {"Authorization": f"Bearer {token}"}