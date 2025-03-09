"""
Database package initialization module that exports database components and initializes the database connection.
This module serves as the entry point for database-related functionality in the Amira Wellness application.
"""

from .session import Base, engine, async_engine, get_db, get_async_db  # Import database session dependencies
from .init_db import init_db  # Import database initialization function
from ..core.logging import logger  # Import logging functionality for database operations

__all__ = ["Base", "engine", "async_engine", "get_db", "get_async_db", "init_db"]


def initialize_db():
    """
    Initialize database components and log initialization
    """
    logger.info("Initializing database module")

    # The following imports are already handled by the named imports above:
    # from .session import Base, engine, async_engine, get_db, get_async_db
    # from .init_db import init_db

    # Set up __all__ to control what is exported from the package
    # __all__ = ["Base", "engine", "async_engine", "get_db", "get_async_db", "init_db"]
    logger.info("Database module initialized")