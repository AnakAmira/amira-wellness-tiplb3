import os
import secrets
from pathlib import Path
from typing import Dict, List, Optional, Union, Any

from pydantic import BaseSettings, Field, validator  # pydantic v2.4+
from dotenv import load_dotenv  # python-dotenv v1.0+

# Base directory of the project
BASE_DIR = Path(__file__).resolve().parent.parent.parent


def get_environment_variable(name: str, default: str = "") -> str:
    """
    Helper function to get environment variables with default values.
    
    Args:
        name: Name of the environment variable
        default: Default value if environment variable is not set
        
    Returns:
        Value of the environment variable or default if not set
    """
    return os.getenv(name, default)


def get_database_url() -> str:
    """
    Constructs the database URL from individual environment variables.
    
    Returns:
        Complete database connection URL
    """
    db_user = get_environment_variable("POSTGRES_USER", "postgres")
    db_password = get_environment_variable("POSTGRES_PASSWORD", "postgres")
    db_host = get_environment_variable("POSTGRES_HOST", "localhost")
    db_port = get_environment_variable("POSTGRES_PORT", "5432")
    db_name = get_environment_variable("POSTGRES_DB", "amira_wellness")
    
    return f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"


class Settings(BaseSettings):
    """
    Pydantic settings class that defines and validates all application configuration.
    Configuration is loaded from environment variables with sensible defaults.
    """
    
    # Application basics
    PROJECT_NAME: str = Field(
        "Amira Wellness", 
        description="Name of the project"
    )
    API_V1_STR: str = Field(
        "/api/v1", 
        description="API version prefix"
    )
    ENVIRONMENT: str = Field(
        get_environment_variable("ENVIRONMENT", "development"),
        description="Application environment (development, staging, production)"
    )
    
    # Security settings
    SECRET_KEY: str = Field(
        get_environment_variable("SECRET_KEY", secrets.token_urlsafe(32)),
        description="Secret key for JWT token generation and verification"
    )
    ALGORITHM: str = Field(
        "HS256",
        description="Algorithm used for JWT token generation"
    )
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        int(get_environment_variable("ACCESS_TOKEN_EXPIRE_MINUTES", "15")),
        description="Minutes until access token expires"
    )
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(
        int(get_environment_variable("REFRESH_TOKEN_EXPIRE_DAYS", "14")),
        description="Days until refresh token expires"
    )
    
    # Database settings
    SQLALCHEMY_DATABASE_URI: str = Field(
        get_environment_variable("DATABASE_URL", get_database_url()),
        description="Database connection URI"
    )
    
    # AWS settings
    AWS_REGION: str = Field(
        get_environment_variable("AWS_REGION", "us-east-1"),
        description="AWS region for S3 and other services"
    )
    S3_BUCKET_NAME: str = Field(
        get_environment_variable("S3_BUCKET_NAME", "amira-audio-storage"),
        description="S3 bucket name for storing encrypted audio files"
    )
    USE_AWS_KMS: bool = Field(
        get_environment_variable("USE_AWS_KMS", "False").lower() in ("true", "1", "t"),
        description="Whether to use AWS KMS for encryption key management"
    )
    ENCRYPTION_KEY_ID: str = Field(
        get_environment_variable("ENCRYPTION_KEY_ID", ""),
        description="KMS key ID for encryption"
    )
    
    # CORS settings
    CORS_ORIGINS: List[str] = Field(
        get_environment_variable("CORS_ORIGINS", "http://localhost,http://localhost:3000").split(","),
        description="Allowed CORS origins"
    )
    
    # API rate limiting
    RATE_LIMIT_PER_MINUTE: int = Field(
        int(get_environment_variable("RATE_LIMIT_PER_MINUTE", "100")),
        description="Maximum API requests per minute per user"
    )
    
    # Logging
    LOG_LEVEL: str = Field(
        get_environment_variable("LOG_LEVEL", "INFO"),
        description="Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
    
    def __init__(self, **data: Any):
        """
        Initialize the Settings class with values from environment variables.
        Loads environment variables from .env file if it exists.
        """
        # Load environment variables from .env file
        dotenv_path = BASE_DIR / ".env"
        if dotenv_path.exists():
            load_dotenv(dotenv_path)
            
        super().__init__(**data)
    
    @validator("SECRET_KEY")
    def validate_secret_key(cls, v: str) -> str:
        """
        Validates that the SECRET_KEY is sufficiently long and secure.
        
        Args:
            cls: Class reference
            v: Secret key value
            
        Returns:
            Validated SECRET_KEY
        """
        if len(v) < 32:
            raise ValueError("SECRET_KEY must be at least 32 characters long")
        return v
    
    @validator("CORS_ORIGINS", pre=True)
    def validate_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """
        Validates and transforms CORS_ORIGINS from string to list.
        
        Args:
            cls: Class reference
            v: CORS origins as string or list
            
        Returns:
            List of allowed CORS origins
        """
        if isinstance(v, list):
            return v
        if isinstance(v, str) and v:
            return [origin.strip() for origin in v.split(",")]
        return []
    
    def get_database_connection_parameters(self) -> Dict[str, str]:
        """
        Returns database connection parameters for logging and monitoring.
        
        Returns:
            Dictionary with database connection parameters (with password masked)
        """
        uri = self.SQLALCHEMY_DATABASE_URI
        
        # Simple parsing - in production you might want a more robust approach
        try:
            # Format is postgresql://user:password@host:port/database
            parts = uri.split("@")
            credentials = parts[0].split("://")[1].split(":")
            user = credentials[0]
            # Mask the password
            host_port_db = parts[1].split("/")
            host_port = host_port_db[0].split(":")
            host = host_port[0]
            port = host_port[1] if len(host_port) > 1 else "5432"
            database = host_port_db[1]
            
            return {
                "user": user,
                "password": "********",  # Masked for security
                "host": host,
                "port": port,
                "database": database,
            }
        except (IndexError, ValueError):
            return {"uri": "Invalid database URI format"}


# Create and export the settings instance
settings = Settings()