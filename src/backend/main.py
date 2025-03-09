import os  # standard library
import sys  # standard library

import uvicorn  # uvicorn 0.23+
from fastapi import FastAPI  # fastapi 0.104+
from fastapi.middleware.cors import CORSMiddleware  # fastapi.middleware.cors 0.104+

from app import initialize_application, setup_routers, setup_exception_handlers, setup_middleware, settings  # Internal import
from app.background.scheduler import run_scheduler  # Internal import
from app.background.worker import run_worker  # Internal import


# Create FastAPI application instance
app: FastAPI = FastAPI(title=settings.PROJECT_NAME, openapi_url=f"{settings.API_V1_STR}/openapi.json")


def create_application() -> FastAPI:
    """Creates and configures the FastAPI application with all required components"""
    # Initialize core application components using initialize_application()
    initialize_application()

    # Create FastAPI application with project name from settings
    fast_app: FastAPI = FastAPI(title=settings.PROJECT_NAME, openapi_url=f"{settings.API_V1_STR}/openapi.json")

    # Configure CORS middleware with allowed origins from settings
    fast_app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Set up API routes using setup_routers(app, settings.API_V1_STR)
    setup_routers(fast_app, settings.API_V1_STR)

    # Set up exception handlers using setup_exception_handlers(app)
    setup_exception_handlers(fast_app)

    # Set up middleware stack using setup_middleware(app)
    setup_middleware(fast_app)

    # Return the configured FastAPI application
    return fast_app


def run_development_server() -> None:
    """Runs the application using Uvicorn development server"""
    # Configure Uvicorn with development settings
    uvicorn_config = uvicorn.Config(
        "src.backend.main:app",
        reload=True,  # Enable hot reload for development
        host="0.0.0.0",  # Listen on all interfaces
        port=8000,  # Default port
    )

    # Run the server with hot reload enabled
    server = uvicorn.Server(uvicorn_config)
    server.run()

    # Set host to 0.0.0.0 and port to 8000 by default
    # Use environment variables for host and port if provided


def run_background_services() -> None:
    """Runs the background services (scheduler or worker) based on command line arguments"""
    # Check command line arguments for service type
    if len(sys.argv) > 1:
        service_type = sys.argv[1]

        # If 'scheduler' is specified, run the scheduler service
        if service_type == "scheduler":
            run_scheduler()

        # If 'worker' is specified, run the worker service
        elif service_type == "worker":
            run_worker()

        # Log error and exit if invalid service type is specified
        else:
            print("Invalid service type. Use 'api', 'scheduler', or 'worker'.")
            sys.exit(1)
    else:
        print("Please specify a service type: 'api', 'scheduler', or 'worker'.")
        sys.exit(1)


def main() -> None:
    """Main entry point that parses command line arguments and runs the appropriate service"""
    # Parse command line arguments
    if len(sys.argv) > 1:
        service_type = sys.argv[1]

        # If no arguments or 'api' specified, run the API server
        if service_type == "api":
            # Create the FastAPI application
            global app
            app = create_application()
            run_development_server()

        # If 'scheduler' or 'worker' specified, run the background service
        elif service_type in ["scheduler", "worker"]:
            run_background_services()

        # Handle any unexpected exceptions during startup
        else:
            print("Invalid service type. Use 'api', 'scheduler', or 'worker'.")
            sys.exit(1)
    else:
        # Create the FastAPI application
        global app
        app = create_application()
        run_development_server()


if __name__ == "__main__":
    main()