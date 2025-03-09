import time
import datetime
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..deps import get_db
from ...core.logging import get_logger
from ...core.config import settings

# Initialize logger
logger = get_logger(__name__)

# Create router with "/health" prefix and "Health" tag
router = APIRouter(prefix="/health", tags=["Health"])

# Store application startup time
startup_time = datetime.datetime.utcnow()

@router.get("/", status_code=status.HTTP_200_OK)
def check_basic_health():
    """
    Simple health check endpoint that returns 200 OK if the API is running.
    
    Returns:
        dict: Basic health status with timestamp
    """
    logger.info("Basic health check requested")
    return {
        "status": "ok",
        "timestamp": datetime.datetime.utcnow().isoformat()
    }

@router.get("/detailed", status_code=status.HTTP_200_OK)
def check_detailed_health(db: Session = Depends(get_db)):
    """
    Detailed health check that verifies all components are functioning correctly.
    
    Args:
        db: Database session dependency
        
    Returns:
        dict: Detailed health status with component checks
    """
    logger.info("Detailed health check requested")
    
    # Check database connectivity
    db_success, db_response_time, db_error = check_database_connection(db)
    
    # Calculate API uptime
    uptime_seconds = (datetime.datetime.utcnow() - startup_time).total_seconds()
    days, remainder = divmod(int(uptime_seconds), 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)
    uptime = f"{days}d {hours}h {minutes}m {seconds}s"
    
    # Construct detailed health response
    health_data = {
        "status": "ok" if db_success else "degraded",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "uptime": uptime,
        "components": {
            "api": {
                "status": "ok",
                "startup_time": startup_time.isoformat(),
            },
            "database": {
                "status": "ok" if db_success else "error",
                "response_time_ms": db_response_time,
                "error": db_error
            }
        }
    }
    
    # Try to get memory usage information if psutil is available
    try:
        import os, psutil
        process = psutil.Process(os.getpid())
        health_data["components"]["api"]["memory"] = {
            "rss_mb": round(process.memory_info().rss / (1024 * 1024), 2),  # RSS in MB
            "percent": round(process.memory_percent(), 2)
        }
    except (ImportError, Exception):
        # psutil not available or error occurred, silently skip this part
        pass
    
    return health_data

@router.get("/database", status_code=status.HTTP_200_OK)
def check_database_health(db: Session = Depends(get_db)):
    """
    Specific health check for database connectivity.
    
    Args:
        db: Database session dependency
        
    Returns:
        dict: Database health status
    """
    logger.info("Database health check requested")
    
    db_success, db_response_time, db_error = check_database_connection(db)
    
    return {
        "status": "ok" if db_success else "error",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "response_time_ms": db_response_time,
        "error": db_error
    }

@router.get("/version", status_code=status.HTTP_200_OK)
def get_version():
    """
    Endpoint to retrieve the current application version.
    
    Returns:
        dict: Application version information
    """
    return {
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "build_timestamp": getattr(settings, "BUILD_TIMESTAMP", None)
    }

def check_database_connection(db: Session) -> tuple:
    """
    Helper function to check database connectivity by executing a simple query.
    
    Args:
        db: Database session
        
    Returns:
        tuple: (success status, response time, error message if any)
    """
    start_time = time.time()
    try:
        # Execute a simple query to test the database
        db.execute("SELECT 1").first()
        response_time = round((time.time() - start_time) * 1000, 2)  # ms
        return True, response_time, None
    except Exception as e:
        response_time = round((time.time() - start_time) * 1000, 2)  # ms
        logger.error(f"Database connection check failed: {str(e)}")
        return False, response_time, str(e)