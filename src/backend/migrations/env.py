import logging
from logging.config import fileConfig
import os
import sys

from alembic import context
from sqlalchemy import engine_from_config, pool
from sqlalchemy.engine.url import URL

# Add the parent directory to the Python path to enable relative imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import application modules
from app.core.config import settings
from app.db.session import Base
import app.db.base  # This imports all models to ensure they are registered with metadata

# Alembic configuration
config = context.config

# Setup logging from alembic.ini
fileConfig(config.config_file_name)
logger = logging.getLogger("alembic.env")

# Set target metadata for auto-generating migrations
target_metadata = Base.metadata

def get_url():
    """
    Get database URL from application settings or Alembic config.
    
    Returns:
        str: Database connection URL
    """
    try:
        # Try to get URL from application settings
        return settings.SQLALCHEMY_DATABASE_URI
    except (AttributeError, ImportError):
        # Fall back to Alembic config
        return config.get_main_option("sqlalchemy.url")

def include_object(object, name, type_, reflected, compare_to):
    """
    Filter function to determine which database objects should be included in migrations.
    
    Args:
        object: The database object
        name: The name of the object
        type_: The type of the object (table, column, etc.)
        reflected: Whether the object was reflected
        compare_to: The object being compared to
        
    Returns:
        bool: True if object should be included, False otherwise
    """
    # Exclude alembic's own tables
    if type_ == "table" and name.startswith("alembic_"):
        return False
    
    # Include all other objects
    return True

def run_migrations_offline():
    """
    Run migrations in 'offline' mode.
    
    This configures the context with just a URL and not an Engine,
    though an Engine is acceptable here as well. By skipping the Engine creation
    we don't even need a DBAPI to be available.
    
    Calls to context.execute() here emit the given string to the
    script output.
    """
    url = get_url()
    logger.info(f"Running offline migrations with URL: {url}")
    
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_object=include_object,
        compare_type=True,
        compare_server_default=True,
        include_schemas=True,
        include_comments=True
    )

    with context.begin_transaction():
        context.run_migrations()
    
    logger.info("Offline migrations completed")

def run_migrations_online():
    """
    Run migrations in 'online' mode.
    
    In this scenario we need to create an Engine and associate a connection with the context.
    """
    url = get_url()
    logger.info(f"Running online migrations with database connection")
    
    # Override sqlalchemy.url in alembic.ini
    config_section = config.get_section(config.config_ini_section)
    config_section["sqlalchemy.url"] = url
    
    # Create engine with connection pooling settings
    connectable = engine_from_config(
        config_section,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            include_object=include_object,
            compare_type=True,
            compare_server_default=True,
            include_schemas=True,
            include_comments=True,
            transaction_per_migration=True
        )

        try:
            with context.begin_transaction():
                context.run_migrations()
            logger.info("Online migrations completed successfully")
        except Exception as e:
            logger.error(f"Error during migrations: {e}")
            raise

# Execute migrations based on invocation type
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()