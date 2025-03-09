import pytest
import contextlib
from typing import Generator, AsyncGenerator

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from ...app.db.session import Base, get_db, get_async_db

# Use in-memory SQLite for tests
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:"

# Create sync and async engines for testing
test_engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL, 
    connect_args={"check_same_thread": False}  # Needed for SQLite
)

test_async_engine = create_async_engine(
    "sqlite+aiosqlite:///:memory:",
    connect_args={"check_same_thread": False}
)

# Create session factories
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
AsyncTestingSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=test_async_engine)


def setup_test_db():
    """Initialize the test database by creating all tables."""
    Base.metadata.create_all(bind=test_engine)


def get_test_db() -> Generator[Session, None, None]:
    """Generator function that provides a test database session."""
    db = TestingSessionLocal()
    try:
        db.begin()  # Start a transaction
        yield db
        db.rollback()  # Roll back the transaction after the test
    finally:
        db.close()


async def get_test_async_db() -> AsyncGenerator[AsyncSession, None]:
    """Async generator function that provides an async test database session."""
    async with AsyncTestingSessionLocal() as session:
        async with session.begin():
            yield session
            await session.rollback()  # Roll back the transaction after the test


def override_get_db():
    """Override function for the get_db dependency in tests."""
    yield from get_test_db()


async def override_get_async_db():
    """Override function for the get_async_db dependency in tests."""
    async for session in get_test_async_db():
        yield session


@pytest.fixture(scope="function")
def test_db():
    """Provides a SQLAlchemy session for testing with automatic rollback."""
    setup_test_db()
    yield from get_test_db()


@pytest.fixture(scope="function")
async def test_async_db():
    """Provides an async SQLAlchemy session for testing with automatic rollback."""
    setup_test_db()
    async for session in get_test_async_db():
        yield session


@pytest.fixture(scope="function")
def override_dependencies(app):
    """Overrides database dependencies for testing."""
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_async_db] = override_get_async_db
    yield
    app.dependency_overrides.clear()