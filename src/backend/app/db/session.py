import contextlib
from typing import Generator, AsyncGenerator

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from ..core.config import settings
from ..core.logging import logger

# Create SQLAlchemy declarative base for model definitions
Base = declarative_base()

# Initialize database engines and session factories
engine = None
async_engine = None
SessionLocal = None
AsyncSessionLocal = None

def init_db_engine():
    """
    Initialize the database engine with proper configuration
    """
    global engine, async_engine, SessionLocal, AsyncSessionLocal
    
    # Configure synchronous engine with connection pooling
    engine = create_engine(
        settings.SQLALCHEMY_DATABASE_URI,
        pool_size=20,            # Default maximum number of connections kept open
        max_overflow=10,         # Allow up to 10 connections above pool_size
        pool_timeout=30,         # Seconds to wait for a connection from the pool
        pool_recycle=1800,       # Recycle connections after 30 minutes (prevents stale connections)
        echo=False               # Don't log all SQL queries (set to True for debugging)
    )
    
    # Create async engine by converting the standard URI
    # Replace postgresql:// with postgresql+asyncpg:// for async support
    async_db_uri = settings.SQLALCHEMY_DATABASE_URI.replace(
        'postgresql://', 'postgresql+asyncpg://'
    )
    
    # Configure asynchronous engine with similar settings
    async_engine = create_async_engine(
        async_db_uri,
        pool_size=20,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=1800,
        echo=False
    )
    
    # Create session factories
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    AsyncSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=async_engine)
    
    logger.info("Database engines initialized successfully")

def get_db() -> Generator[Session, None, None]:
    """
    Dependency function that provides a database session for FastAPI endpoints
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        logger.error(f"Database session error: {str(e)}")
        db.rollback()
        raise
    finally:
        db.close()

async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency function that provides an async database session for FastAPI endpoints
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception as e:
            logger.error(f"Async database session error: {str(e)}")
            await session.rollback()
            raise

# Initialize the database engine when the module is imported
init_db_engine()