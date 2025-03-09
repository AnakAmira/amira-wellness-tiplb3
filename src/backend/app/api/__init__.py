from fastapi import FastAPI  # fastapi: 0.104+

from .routes import api_routers  # Import list of all API routers from routes package
from .errors import register_exception_handlers  # Import function to register exception handlers
from ..core.logging import get_logger  # Import logging utility function

# Initialize logger
logger = get_logger(__name__)


def setup_routers(app: FastAPI, prefix: str) -> None:
    """Configures all API routers with the FastAPI application"""
    logger.info("Setting up API routers")
    for router in api_routers:
        app.include_router(router, prefix=prefix)
        logger.info(f"Registered router: {router.prefix}")
    logger.info("API routers setup complete")


def setup_exception_handlers(app: FastAPI) -> None:
    """Configures all exception handlers with the FastAPI application"""
    logger.info("Setting up exception handlers")
    register_exception_handlers(app)
    logger.info("Exception handlers setup complete")


__all__ = [
    "setup_routers",
    "setup_exception_handlers"
]