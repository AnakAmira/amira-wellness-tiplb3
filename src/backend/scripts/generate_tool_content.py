#!/usr/bin/env python
"""
generate_tool_content.py

A script that processes tool template JSON files and generates standardized tool content
for the Amira Wellness application. It reads template files for different tool categories,
validates their structure, and inserts them into the database with proper formatting and relationships.
"""

import json
import os
import sys
import logging
import argparse
import uuid
from datetime import datetime

# Internal imports
from ..app.db import session
from ..app.models.tool import Tool
from ..app.constants.tools import ToolCategory, ToolContentType, ToolDifficulty
from ..app.constants.emotions import EmotionType

# Define globals
TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data', 'tool_templates')
TEMPLATE_FILES = {
    'breathing': 'breathing_exercises.json',
    'meditation': 'meditation_guides.json',
    'journaling': 'journaling_prompts.json',
    'somatic': 'somatic_exercises.json',
    'gratitude': 'gratitude_exercises.json'
}

logger = logging.getLogger(__name__)

def setup_logging():
    """
    Configures the logging system for the script
    """
    logging.basicConfig(
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        level=logging.INFO
    )
    # Add console handler to display logs in the terminal
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    logger.addHandler(console_handler)

def parse_arguments():
    """
    Parses command line arguments for script configuration
    
    Returns:
        argparse.Namespace: Parsed command line arguments
    """
    parser = argparse.ArgumentParser(description='Generate tool content from template files')
    parser.add_argument('--category', type=str, help='Specific category to process (optional)')
    parser.add_argument('--dry-run', action='store_true', help='Validate templates without inserting into database')
    parser.add_argument('--verbose', action='store_true', help='Enable detailed logging')
    return parser.parse_args()

def load_template_file(file_path):
    """
    Loads and parses a JSON template file
    
    Args:
        file_path (str): Path to the template file
        
    Returns:
        list: List of tool template dictionaries
    """
    try:
        if not os.path.exists(file_path):
            logger.error(f"Template file not found: {file_path}")
            return []
        
        with open(file_path, 'r', encoding='utf-8') as file:
            content = json.load(file)
            
        if not isinstance(content, list):
            logger.error(f"Invalid template format in {file_path}. Expected a list.")
            return []
            
        return content
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in template file {file_path}: {str(e)}")
        return []
    except Exception as e:
        logger.error(f"Error loading template file {file_path}: {str(e)}")
        return []

def validate_tool_template(template):
    """
    Validates a tool template against the required schema
    
    Args:
        template (dict): Tool template to validate
        
    Returns:
        tuple: (is_valid: bool, error_message: str)
    """
    # Check required fields
    required_fields = [
        'name', 'description', 'category', 'content_type', 
        'estimated_duration', 'difficulty', 'target_emotions', 'content'
    ]
    
    for field in required_fields:
        if field not in template:
            return False, f"Missing required field: {field}"
    
    # Validate content type
    try:
        content_type = ToolContentType(template['content_type'])
    except ValueError:
        valid_types = [t.value for t in ToolContentType]
        return False, f"Invalid content_type. Must be one of: {valid_types}"
    
    # Validate difficulty
    try:
        difficulty = ToolDifficulty(template['difficulty'])
    except ValueError:
        valid_difficulties = [d.value for d in ToolDifficulty]
        return False, f"Invalid difficulty. Must be one of: {valid_difficulties}"
    
    # Validate target emotions
    if not isinstance(template['target_emotions'], list):
        return False, "target_emotions must be a list"
    
    for emotion in template['target_emotions']:
        try:
            EmotionType(emotion)
        except ValueError:
            valid_emotions = [e.value for e in EmotionType]
            return False, f"Invalid emotion: {emotion}. Must be one of: {valid_emotions}"
    
    # Validate category
    try:
        category = ToolCategory(template['category'])
    except ValueError:
        valid_categories = [c.value for c in ToolCategory]
        return False, f"Invalid category. Must be one of: {valid_categories}"
    
    # Validate content
    if not isinstance(template['content'], dict):
        return False, "content must be a dictionary"
    
    # Validate content structure based on content type
    if content_type == ToolContentType.TEXT:
        if 'text' not in template['content']:
            return False, "TEXT content must include 'text' field"
    
    elif content_type == ToolContentType.AUDIO:
        if 'audio_url' not in template['content']:
            return False, "AUDIO content must include 'audio_url' field"
    
    elif content_type == ToolContentType.VIDEO:
        if 'video_url' not in template['content']:
            return False, "VIDEO content must include 'video_url' field"
    
    elif content_type == ToolContentType.INTERACTIVE or content_type == ToolContentType.GUIDED_EXERCISE:
        if 'steps' not in template['content'] or not isinstance(template['content']['steps'], list):
            return False, f"{content_type.value} content must include 'steps' as a list"
    
    # Validate estimated duration range
    if not isinstance(template['estimated_duration'], int) or template['estimated_duration'] < 1 or template['estimated_duration'] > 60:
        return False, "estimated_duration must be an integer between 1 and 60"
    
    return True, ""

def get_or_create_category(category_name, db_session):
    """
    Gets an existing category or creates a new one if it doesn't exist
    
    Args:
        category_name (str): Name of the category
        db_session (sqlalchemy.orm.Session): Database session
        
    Returns:
        ToolCategory: The retrieved or newly created category object
    """
    try:
        # Convert category name to enum value
        category_enum = ToolCategory(category_name.upper())
        
        # In this application, ToolCategory is an enum, not a database model
        # So we just return the enum value - no need to query or create in database
        return category_enum
    except ValueError:
        valid_categories = [c.value for c in ToolCategory]
        logger.error(f"Invalid category: {category_name}. Must be one of: {valid_categories}")
        return None

def create_tool_from_template(template, category, dry_run=False):
    """
    Creates a Tool object from a validated template
    
    Args:
        template (dict): Validated tool template
        category (ToolCategory): Category enum value
        dry_run (bool): If True, return the Tool object without adding to session
        
    Returns:
        Tool: The created Tool object
    """
    # Convert string enums to proper enum types
    content_type = ToolContentType(template['content_type'])
    difficulty = ToolDifficulty(template['difficulty'])
    
    # Convert emotion strings to their enum values
    target_emotions = []
    for emotion_str in template['target_emotions']:
        try:
            emotion_enum = EmotionType(emotion_str)
            target_emotions.append(emotion_enum.value)
        except ValueError:
            logger.warning(f"Skipping invalid emotion: {emotion_str}")
    
    # Create tool object
    tool = Tool(
        id=uuid.uuid4(),
        name=template['name'],
        description=template['description'],
        category=category,
        content_type=content_type,
        content=template['content'],
        estimated_duration=template['estimated_duration'],
        difficulty=difficulty,
        target_emotions=target_emotions,
        icon_url=template.get('icon_url'),
        is_active=template.get('is_active', True),
        is_premium=template.get('is_premium', False),
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    
    return tool

def process_template_file(category, file_name, db_session, dry_run=False):
    """
    Processes a single template file and creates tools from it
    
    Args:
        category (str): Tool category
        file_name (str): Template file name
        db_session (sqlalchemy.orm.Session): Database session
        dry_run (bool): If True, validate only without database changes
        
    Returns:
        tuple: (success_count: int, error_count: int)
    """
    file_path = os.path.join(TEMPLATE_DIR, file_name)
    templates = load_template_file(file_path)
    
    if not templates:
        logger.error(f"No templates found in {file_path}")
        return 0, 0
    
    logger.info(f"Processing {len(templates)} templates from {file_path}")
    
    # Get or create category
    db_category = get_or_create_category(category, db_session)
    if not db_category:
        logger.error(f"Failed to get or create category: {category}")
        return 0, len(templates)
    
    success_count = 0
    error_count = 0
    
    for template in templates:
        # Validate template
        is_valid, error_message = validate_tool_template(template)
        
        if not is_valid:
            logger.error(f"Invalid template: {error_message}")
            error_count += 1
            continue
        
        try:
            # Create tool from template
            tool = create_tool_from_template(template, db_category, dry_run)
            
            if not dry_run:
                # Add to database
                db_session.add(tool)
                logger.info(f"Added tool: {tool.name}")
            else:
                logger.info(f"Would add tool: {tool.name} (dry run)")
            
            success_count += 1
            
        except Exception as e:
            logger.error(f"Error creating tool: {str(e)}")
            error_count += 1
    
    if not dry_run and success_count > 0:
        # Commit changes
        try:
            db_session.commit()
            logger.info(f"Committed {success_count} tools to database")
        except Exception as e:
            logger.error(f"Error committing changes: {str(e)}")
            db_session.rollback()
            return 0, len(templates)
    
    return success_count, error_count

def main():
    """
    Main function that orchestrates the tool content generation process
    
    Returns:
        int: Exit code (0 for success, 1 for error)
    """
    # Set up logging
    setup_logging()
    
    # Parse command line arguments
    args = parse_arguments()
    
    # Set logging level to DEBUG if verbose flag is set
    if args.verbose:
        logger.setLevel(logging.DEBUG)
        logger.debug("Verbose logging enabled")
    
    # Create a database session
    db_session = session.SessionLocal()
    
    try:
        total_success = 0
        total_errors = 0
        
        # Process specific category if provided, otherwise process all
        if args.category:
            if args.category not in TEMPLATE_FILES:
                logger.error(f"Unknown category: {args.category}")
                return 1
            
            categories_to_process = {args.category: TEMPLATE_FILES[args.category]}
        else:
            categories_to_process = TEMPLATE_FILES
        
        # Process each category
        for category, file_name in categories_to_process.items():
            logger.info(f"Processing category: {category}")
            success, errors = process_template_file(
                category, file_name, db_session, args.dry_run
            )
            total_success += success
            total_errors += errors
        
        logger.info(f"Processing complete. Added {total_success} tools with {total_errors} errors.")
        
        return 0 if total_errors == 0 else 1
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return 1
    finally:
        db_session.close()

if __name__ == '__main__':
    sys.exit(main())