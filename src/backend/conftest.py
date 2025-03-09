import os
import sys
import logging
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.db.session import Base
from app.core.config import settings
from app.core.logging import get_logger

# Configure logger for tests
logger = get_logger(__name__)

# In-memory SQLite database URL for testing
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:"

def pytest_configure(config):
    """
    Pytest hook that runs before test collection to configure the test environment.
    
    Args:
        config: The pytest config object
    """
    # Set testing mode in environment
    os.environ["TESTING"] = "True"
    
    # Configure logging for tests
    logging.basicConfig(level=logging.INFO)
    
    # Register custom markers
    config.addinivalue_line("markers", "unit: mark a test as a unit test")
    config.addinivalue_line("markers", "integration: mark a test as an integration test")
    config.addinivalue_line("markers", "api: mark a test as an API test")
    config.addinivalue_line("markers", "slow: mark a test as slow running")
    
    # Add project root to Python path for imports
    sys.path.append(os.path.abspath(os.path.dirname(os.path.dirname(__file__))))


def pytest_sessionstart(session):
    """
    Pytest hook that runs at the start of the test session.
    
    Args:
        session: The pytest session object
    """
    # Create in-memory SQLite database for testing
    engine = create_engine(
        SQLALCHEMY_TEST_DATABASE_URL,
        connect_args={"check_same_thread": False}  # Needed for SQLite
    )
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    logger.info("Test database initialized")


def pytest_collection_modifyitems(config, items):
    """
    Pytest hook that runs after test collection to modify test items.
    
    Args:
        config: The pytest config object
        items: List of collected test items
    """
    # Automatically mark tests based on directory/file location
    for item in items:
        # Mark unit tests
        if "unit" in item.nodeid:
            item.add_marker(pytest.mark.unit)
        
        # Mark integration tests
        if "integration" in item.nodeid:
            item.add_marker(pytest.mark.integration)
        
        # Mark API tests
        if "api" in item.nodeid:
            item.add_marker(pytest.mark.api)
        
        # Skip slow tests unless explicitly requested
        if "slow" in item.keywords and not config.getoption("--run-slow", default=False):
            item.add_marker(pytest.mark.skip(reason="Need --run-slow option to run"))


def create_test_app():
    """
    Creates a FastAPI application instance configured for testing.
    
    Returns:
        FastAPI application instance for testing
    """
    # Import here to avoid circular imports
    from app.main import create_application
    
    # Create test application with testing settings
    app = create_application()
    
    # Override dependencies with test versions
    from app.api.deps import get_db, get_async_db
    
    # Dependency overrides
    app.dependency_overrides[get_db] = get_test_db
    app.dependency_overrides[get_async_db] = get_test_async_db
    
    return app


def get_test_db():
    """
    Generator function that provides a test database session.
    
    Yields:
        SQLAlchemy Session for testing
    """
    # Create test engine
    engine = create_engine(
        SQLALCHEMY_TEST_DATABASE_URL,
        connect_args={"check_same_thread": False}  # Needed for SQLite
    )
    
    # Create session factory
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create session
    db = TestingSessionLocal()
    
    try:
        # Start a transaction
        db.begin()
        # Provide the session to the test
        yield db
    finally:
        # Roll back the transaction to isolate tests
        db.rollback()
        # Close the session
        db.close()


async def get_test_async_db():
    """
    Async generator function that provides an async test database session.
    
    Yields:
        AsyncSession for testing
    """
    # Create async test engine - requires aiosqlite package
    # Note: SQLite has limited async support, consider using PostgreSQL for production
    engine = create_async_engine(
        SQLALCHEMY_TEST_DATABASE_URL.replace("sqlite://", "sqlite+aiosqlite://"),
        connect_args={"check_same_thread": False}
    )
    
    # Create async session factory
    TestingAsyncSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create tables if they don't exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create session
    async_session = TestingAsyncSessionLocal()
    
    try:
        # Start a transaction
        await async_session.begin()
        # Provide the session to the test
        yield async_session
    finally:
        # Roll back the transaction to isolate tests
        await async_session.rollback()
        # Close the session
        await async_session.close()


@pytest.fixture(scope="session")
def app():
    """
    Provides a test instance of the FastAPI application.
    
    Returns:
        FastAPI application instance
    """
    return create_test_app()


@pytest.fixture(scope="function")
def client(app):
    """
    Provides a test client for the FastAPI application.
    
    Args:
        app: The FastAPI application fixture
        
    Returns:
        TestClient instance
    """
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="function")
def db():
    """
    Provides a database session for testing with automatic rollback.
    
    Yields:
        SQLAlchemy Session object
    """
    yield from get_test_db()


@pytest.fixture(scope="function")
async def async_db():
    """
    Provides an async database session for testing with automatic rollback.
    
    Yields:
        AsyncSession object
    """
    async for session in get_test_async_db():
        yield session


@pytest.fixture(scope="function")
def auth_headers():
    """
    Provides authentication headers for authenticated API requests.
    
    Returns:
        Dict with Authorization header
    """
    # Import here to avoid circular imports
    from app.core.security import create_access_token
    
    # Create a test access token
    access_token = create_access_token(
        data={"sub": "test-user", "username": "testuser", "is_admin": False},
        expires_minutes=30
    )
    
    # Return headers with the token
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture(scope="function")
def admin_auth_headers():
    """
    Provides authentication headers for admin API requests.
    
    Returns:
        Dict with Authorization header for admin user
    """
    # Import here to avoid circular imports
    from app.core.security import create_access_token
    
    # Create a test admin access token
    access_token = create_access_token(
        data={"sub": "admin-user", "username": "adminuser", "is_admin": True},
        expires_minutes=30
    )
    
    # Return headers with the token
    return {"Authorization": f"Bearer {access_token}"}