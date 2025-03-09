import os
import json
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from .session import Base
from .base import get_user_model, get_tool_models, get_achievement_model
from ..core.config import settings
from ..core.logging import logger
from ..core.security import get_password_hash
from ..constants.languages import DEFAULT_LANGUAGE

# Define paths for data files
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent
TOOL_TEMPLATES_DIR = BASE_DIR / 'data' / 'tool_templates'
ACHIEVEMENTS_FILE = BASE_DIR / 'data' / 'initial_achievements.json'

def init_db(drop_all: bool = False) -> None:
    """
    Main function to initialize the database, create tables, and seed initial data
    
    Args:
        drop_all: If True, drop all existing tables before creating new ones
    """
    logger.info("Initializing database...")
    
    # Create database engine
    engine = create_engine(settings.SQLALCHEMY_DATABASE_URI)
    
    # Drop all tables if requested
    if drop_all:
        logger.info("Dropping all tables...")
        Base.metadata.drop_all(engine)
    
    # Create all tables
    logger.info("Creating database tables...")
    Base.metadata.create_all(engine)
    
    # Create a database session
    db = Session(engine)
    
    try:
        # Create initial data
        create_initial_data(db)
        
        # Commit the session
        db.commit()
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        db.rollback()
        raise
    finally:
        db.close()
    
    logger.info("Database initialization completed successfully")

def create_initial_data(db: Session) -> None:
    """
    Creates initial data in the database including tools, achievements, and test users
    
    Args:
        db: SQLAlchemy database session
    """
    # Create tool library content
    create_tools(db)
    
    # Create achievements
    create_achievements(db)
    
    # Create test users in development environment
    if settings.ENVIRONMENT == "development":
        create_test_users(db)
    
    logger.info("Initial data creation completed successfully")

def create_tools(db: Session) -> None:
    """
    Seeds the database with tool library content from JSON template files
    
    Args:
        db: SQLAlchemy database session
    """
    # Get the Tool model
    Tool = get_tool_models()["Tool"]
    
    # Check if tools already exist
    existing_tools = db.query(Tool).count()
    if existing_tools > 0:
        logger.info(f"Tools already exist ({existing_tools} found), skipping tool creation")
        return
    
    # Get tool templates
    tool_templates = get_tool_templates()
    
    # Track the number of tools created for each category
    tool_counts = {}
    
    # Process tool templates by category
    for category, tools in tool_templates.items():
        # Initialize counter for this category
        if category not in tool_counts:
            tool_counts[category] = 0
        
        for tool_data in tools:
            try:
                # Create Tool object
                tool = Tool(**tool_data)
                
                # Add to the database session
                db.add(tool)
                tool_counts[category] += 1
            except Exception as e:
                logger.error(f"Error creating tool: {str(e)}, data: {tool_data}")
    
    # Log the number of tools created
    for category, count in tool_counts.items():
        logger.info(f"Created {count} tools for category: {category}")

def create_achievements(db: Session) -> None:
    """
    Seeds the database with achievement definitions from JSON template file
    
    Args:
        db: SQLAlchemy database session
    """
    # Get the Achievement model
    Achievement = get_achievement_model()
    
    # Check if achievements already exist
    existing_achievements = db.query(Achievement).count()
    if existing_achievements > 0:
        logger.info(f"Achievements already exist ({existing_achievements} found), skipping achievement creation")
        return
    
    # Get achievement templates
    achievement_templates = get_achievement_templates()
    
    # Process achievement templates
    achievement_count = 0
    for achievement_data in achievement_templates:
        try:
            # Create Achievement object
            achievement = Achievement(**achievement_data)
            
            # Add to the database session
            db.add(achievement)
            achievement_count += 1
        except Exception as e:
            logger.error(f"Error creating achievement: {str(e)}, data: {achievement_data}")
    
    logger.info(f"Created {achievement_count} achievements")

def create_test_users(db: Session) -> None:
    """
    Creates test users for development environment
    
    Args:
        db: SQLAlchemy database session
    """
    # Get the User model
    User = get_user_model()
    
    # Check if test users already exist
    admin_user = db.query(User).filter(User.email == "admin@example.com").first()
    if admin_user:
        logger.info("Test users already exist, skipping user creation")
        return
    
    # Create admin user
    admin = User(
        email="admin@example.com",
        password_hash=get_password_hash("adminpassword"),
        email_verified=True,
        language_preference=DEFAULT_LANGUAGE,
        subscription_tier="premium"
    )
    
    # Create regular user
    user = User(
        email="user@example.com",
        password_hash=get_password_hash("userpassword"),
        email_verified=True,
        language_preference=DEFAULT_LANGUAGE,
        subscription_tier="free"
    )
    
    # Add users to the session
    db.add(admin)
    db.add(user)
    
    logger.info("Created test users: admin@example.com and user@example.com")

def get_tool_templates() -> dict:
    """
    Loads tool templates from JSON files in the templates directory
    
    Returns:
        Dictionary mapping tool categories to lists of tool templates
    """
    templates = {}
    
    # Check if the templates directory exists
    if not TOOL_TEMPLATES_DIR.exists():
        logger.warning(f"Tool templates directory not found: {TOOL_TEMPLATES_DIR}")
        return templates
    
    # Process each JSON file in the templates directory
    for file_path in TOOL_TEMPLATES_DIR.glob("*.json"):
        try:
            with open(file_path, "r", encoding="utf-8") as file:
                data = json.load(file)
                
                # Extract category from filename or from the first tool
                category_name = file_path.stem.upper()  # Use filename as category
                
                # Handle both list and dictionary formats in JSON files
                if isinstance(data, dict) and "category" in data:
                    category_name = data["category"]
                    tools = [data]  # Single tool as a dictionary
                elif isinstance(data, list) and data and "category" in data[0]:
                    category_name = data[0]["category"]
                    tools = data  # List of tools
                else:
                    tools = data if isinstance(data, list) else [data]
                
                # Initialize category in the templates dictionary if needed
                if category_name not in templates:
                    templates[category_name] = []
                
                # Add tools to the templates dictionary
                templates[category_name].extend(tools)
                
                logger.info(f"Loaded {len(tools)} tool templates from {file_path.name}")
                
        except Exception as e:
            logger.error(f"Error loading tool template file {file_path}: {str(e)}")
    
    return templates

def get_achievement_templates() -> list:
    """
    Loads achievement templates from the achievements JSON file
    
    Returns:
        List of achievement template dictionaries
    """
    # Check if the achievements file exists
    if not ACHIEVEMENTS_FILE.exists():
        logger.warning(f"Achievements file not found: {ACHIEVEMENTS_FILE}")
        return []
    
    try:
        with open(ACHIEVEMENTS_FILE, "r", encoding="utf-8") as file:
            achievements = json.load(file)
            logger.info(f"Loaded {len(achievements)} achievement templates from {ACHIEVEMENTS_FILE.name}")
            return achievements
    except Exception as e:
        logger.error(f"Error loading achievements file {ACHIEVEMENTS_FILE}: {str(e)}")
        return []