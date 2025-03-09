from fastapi import APIRouter  # fastapi: 0.104+

from .health import router as health_router  # Import health check API router
from .auth import router as auth_router  # Import authentication API router
from .users import router as users_router  # Import user management API router
from .journals import router as journals_router  # Import voice journaling API router
from .emotions import router as emotions_router  # Import emotional tracking API router
from .tools import router as tools_router  # Import tool library API router
from .progress import router as progress_router  # Import progress tracking API router
from .notifications import router as notifications_router  # Import notifications API router
from ..core.logging import get_logger  # Import logging utility function

# Initialize logger
logger = get_logger(__name__)

# Define a list of all API routers to be included in the main application
api_routers = [
    health_router,
    auth_router,
    users_router,
    journals_router,
    emotions_router,
    tools_router,
    progress_router,
    notifications_router
]

# Export the list of API routers for use in the main application
__all__ = [
    "api_routers",
    "health_router",
    "auth_router",
    "users_router",
    "journals_router",
    "emotions_router",
    "tools_router",
    "progress_router",
    "notifications_router"
]