import os
import sys
import importlib
from typing import Any

from fastapi import FastAPI  # fastapi: 0.104+

from .core.config import settings  # Internal import
from .core.logging import setup_logging, get_logger  # Internal import
from .api import setup_routers, setup_exception_handlers  # Internal import
from .middleware import get_middleware_stack, LoggingMiddleware, ErrorHandlerMiddleware, AuthenticationMiddleware, RateLimiterMiddleware  # Internal import
from .db.init_db import init_db  # Internal import
from .core.encryption import EncryptionManager  # Internal import
from .core.events import event_bus  # Internal import
from .background.tasks import initialize_background_tasks  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Application version
__version__ = "0.1.0"

# Global encryption manager instance
encryption_manager: EncryptionManager = None


def initialize_application() -> None:
    """Initializes all core application components in the correct order"""
    # Set up logging system
    setup_logging()

    logger.info("Starting application initialization")

    # Initialize database connection and run migrations
    init_db()

    # Initialize encryption manager and store in global variable
    global encryption_manager
    encryption_manager = EncryptionManager()
    logger.info(f"Encryption Manager initialized: {encryption_manager}")

    # Initialize event bus and register event handlers
    logger.info("Initializing event bus")
    # No specific event handlers to register in this module
    logger.info("Event bus initialized")

    # Initialize background tasks
    initialize_background_tasks()

    logger.info("Application initialization completed successfully")


def setup_middleware(app: FastAPI) -> None:
    """Configures middleware components for the FastAPI application"""
    logger.info("Setting up middleware")

    # Get middleware stack in the correct order
    middleware = get_middleware_stack()

    # Add each middleware to the FastAPI application
    for middleware_class in middleware:
        app.add_middleware(middleware_class)
        logger.info(f"Added middleware: {middleware_class.__name__}")

    logger.info("Middleware setup completed")


def get_encryption_manager() -> EncryptionManager:
    """Returns the global encryption manager instance"""
    global encryption_manager
    if encryption_manager is None:
        encryption_manager = EncryptionManager()
    return encryption_manager


def import_submodules() -> None:
    """Dynamically imports all submodules to ensure they are properly initialized"""
    # Define list of core submodules to import
    core_modules = [
        ".core.config",
        ".core.logging",
        ".api",
        ".db",
        ".models",
        ".schemas",
        ".utils",
        ".services",
        ".background",
        ".middleware"
    ]

    # Iterate through the list and import each module
    for module_name in core_modules:
        try:
            importlib.import_module(module_name, package=__package__)
            logger.debug(f"Imported submodule: {module_name}")
        except ImportError as e:
            logger.error(f"Failed to import submodule {module_name}: {e}")

    logger.info("Core submodules imported successfully")


# Application configuration settings
__all__ = [
    "settings",
    "setup_logging",
    "get_logger",
    "initialize_application",
    "setup_routers",
    "setup_exception_handlers",
    "setup_middleware",
    "get_encryption_manager",
    "__version__"
]