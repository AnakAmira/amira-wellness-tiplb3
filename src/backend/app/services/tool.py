"""
Service layer for the Tool Library feature in the Amira Wellness application.
Provides business logic for managing emotional regulation tools, tool favorites, tool usage tracking, and personalized recommendations.
"""

import typing
from typing import List, Dict, Optional, Any, Tuple, Union
import uuid
import datetime

from sqlalchemy.orm import Session  # sqlalchemy 2.0+

from ..crud import tool  # Internal import
from ..crud import tool_favorite  # Internal import
from ..crud import tool_usage  # Internal import
from ..models.tool import Tool  # Internal import
from ..models.tool import ToolFavorite  # Internal import
from ..models.tool import ToolUsage  # Internal import
from ..constants.tools import ToolCategory  # Internal import
from ..constants.tools import ToolContentType  # Internal import
from ..constants.tools import get_tool_category_display_name  # Internal import
from ..constants.tools import get_tool_category_description  # Internal import
from ..constants.tools import get_tool_content_type_display_name  # Internal import
from ..constants.tools import get_tool_difficulty_display_name  # Internal import
from ..constants.tools import get_tool_category_color  # Internal import
from ..constants.tools import get_tool_categories_for_emotion  # Internal import
from ..constants.emotions import EmotionType  # Internal import
from ..core.logging import get_logger  # Internal import
from ..core.exceptions import ResourceNotFoundException  # Internal import
from ..core.exceptions import ValidationException  # Internal import

# Initialize logger
logger = get_logger(__name__)


def get_tool(
    db: Session, tool_id: uuid.UUID, user_id: Optional[uuid.UUID] = None
) -> Tuple[Optional[Tool], bool]:
    """
    Get a tool by ID with optional favorite status for a user

    Args:
        db: Database session
        tool_id: ID of the tool to retrieve
        user_id: Optional user ID to check favorite status for

    Returns:
        Tuple[Optional[Tool], bool]: Tuple of (tool, is_favorited)
    """
    logger.info(f"Getting tool with id: {tool_id}, user_id: {user_id}")
    if user_id:
        tool_obj, is_favorited = tool.get_tool_with_favorite_status(db, tool_id, user_id)
        if not tool_obj:
            return None, False
        return tool_obj, is_favorited
    else:
        tool_obj = tool.get(db, tool_id)
        if not tool_obj:
            return None, False
        return tool_obj, False


def get_tool_by_name(
    db: Session, name: str, user_id: Optional[uuid.UUID] = None
) -> Tuple[Optional[Tool], bool]:
    """
    Get a tool by name with optional favorite status for a user

    Args:
        db: Database session
        name: Name of the tool to retrieve
        user_id: Optional user ID to check favorite status for

    Returns:
        Tuple[Optional[Tool], bool]: Tuple of (tool, is_favorited)
    """
    logger.info(f"Getting tool with name: {name}, user_id: {user_id}")
    tool_obj = db.query(Tool).filter(Tool.name == name).first()
    if not tool_obj:
        return None, False
    if user_id:
        is_favorited = tool_favorite.is_tool_favorited(db, user_id, tool_obj.id)
        return tool_obj, is_favorited
    else:
        return tool_obj, False


def get_tools(
    db: Session, skip: int = 0, limit: int = 100, user_id: Optional[uuid.UUID] = None
) -> Tuple[List[Tool], int]:
    """
    Get all tools with pagination and optional favorite status

    Args:
        db: Database session
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
        user_id: Optional user ID to check favorite status for

    Returns:
        Tuple[List[Tool], int]: Tuple of (tools, total_count)
    """
    logger.info(f"Getting tools with skip: {skip}, limit: {limit}, user_id: {user_id}")
    tools = tool.get_multi(db, skip=skip, limit=limit)
    total_count = tool.get_count(db)
    if user_id:
        tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
        return [tool_obj for tool_obj, _ in tools_with_favorites], total_count
    else:
        return tools, total_count


def get_filtered_tools(
    db: Session,
    categories: Optional[List[ToolCategory]] = None,
    content_types: Optional[List[ToolContentType]] = None,
    target_emotions: Optional[List[EmotionType]] = None,
    max_duration: Optional[int] = None,
    is_active: Optional[bool] = None,
    is_premium: Optional[bool] = None,
    search_query: Optional[str] = None,
    favorites_only: Optional[bool] = None,
    user_id: Optional[uuid.UUID] = None,
    skip: int = 0,
    limit: int = 100,
) -> Tuple[List[Tool], int]:
    """
    Get tools filtered by various criteria

    Args:
        db: Database session
        categories: List of tool categories to include
        content_types: List of content types to include
        target_emotions: List of target emotions to include
        max_duration: Maximum duration in minutes
        is_active: Filter by active status
        is_premium: Filter by premium status
        search_query: Search string for name or description
        favorites_only: Filter by favorite status
        user_id: Optional user ID to check favorite status for
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return

    Returns:
        Tuple[List[Tool], int]: Tuple of (tools, total_count)
    """
    logger.info(f"Getting filtered tools with categories: {categories}, content_types: {content_types}, target_emotions: {target_emotions}, max_duration: {max_duration}, is_active: {is_active}, is_premium: {is_premium}, search_query: {search_query}, favorites_only: {favorites_only}, user_id: {user_id}, skip: {skip}, limit: {limit}")
    if favorites_only and user_id:
        tools, total_count = tool_favorite.get_favorite_tools(db, user_id, skip=skip, limit=limit)
        tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
        return [tool_obj for tool_obj, _ in tools_with_favorites], total_count
    else:
        tools, total_count = tool.filter_tools(
            db,
            categories=categories,
            content_types=content_types,
            target_emotions=target_emotions,
            max_duration=max_duration,
            is_active=is_active,
            is_premium=is_premium,
            search_query=search_query,
            skip=skip,
            limit=limit,
        )
        if user_id:
            tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
            return [tool_obj for tool_obj, _ in tools_with_favorites], total_count
        else:
            return tools, total_count


def get_tools_by_category(
    db: Session, category: ToolCategory, skip: int = 0, limit: int = 100, user_id: Optional[uuid.UUID] = None
) -> Tuple[List[Tool], int]:
    """
    Get tools by category with pagination and optional favorite status

    Args:
        db: Database session
        category: Tool category to filter by
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
        user_id: Optional user ID to check favorite status for

    Returns:
        Tuple[List[Tool], int]: Tuple of (tools, total_count)
    """
    logger.info(f"Getting tools by category: {category}, skip: {skip}, limit: {limit}, user_id: {user_id}")
    tools = tool.get_by_category(db, category, skip=skip, limit=limit)
    total_count = tool.get_count(db)
    if user_id:
        tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
        return [tool_obj for tool_obj, _ in tools_with_favorites], total_count
    else:
        return tools, total_count


def get_tools_by_emotion(
    db: Session, emotion_type: EmotionType, skip: int = 0, limit: int = 100, user_id: Optional[uuid.UUID] = None
) -> Tuple[List[Tool], int]:
    """
    Get tools targeting a specific emotion

    Args:
        db: Database session
        emotion_type: Emotion type to filter by
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
        user_id: Optional user ID to check favorite status for

    Returns:
        Tuple[List[Tool], int]: Tuple of (tools, total_count)
    """
    logger.info(f"Getting tools by emotion: {emotion_type}, skip: {skip}, limit: {limit}, user_id: {user_id}")
    tools = tool.get_by_target_emotion(db, emotion_type, skip=skip, limit=limit)
    total_count = tool.get_count(db)
    if user_id:
        tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
        return [tool_obj for tool_obj, _ in tools_with_favorites], total_count
    else:
        return tools, total_count


def create_tool(db: Session, tool_data: Dict[str, Any]) -> Tool:
    """
    Create a new tool

    Args:
        db: Database session
        tool_data: Data to create the tool with

    Returns:
        Tool: Created tool
    """
    logger.info(f"Creating tool with data: {tool_data}")
    return tool.create(db, obj_in=tool_data)


def update_tool(db: Session, tool_id: uuid.UUID, tool_data: Dict[str, Any]) -> Tool:
    """
    Update an existing tool

    Args:
        db: Database session
        tool_id: ID of the tool to update
        tool_data: Data to update the tool with

    Returns:
        Tool: Updated tool
    """
    logger.info(f"Updating tool with id: {tool_id}, data: {tool_data}")
    db_obj = tool.get(db, tool_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="tool", resource_id=tool_id)
    return tool.update(db, db_obj=db_obj, obj_in=tool_data)


def delete_tool(db: Session, tool_id: uuid.UUID) -> bool:
    """
    Delete a tool

    Args:
        db: Database session
        tool_id: ID of the tool to delete

    Returns:
        bool: True if deleted successfully
    """
    logger.info(f"Deleting tool with id: {tool_id}")
    db_obj = tool.get(db, tool_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="tool", resource_id=tool_id)
    tool.delete(db, id_or_obj=db_obj)
    return True


def get_user_favorite_tools(
    db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100
) -> Tuple[List[Tool], int]:
    """
    Get tools favorited by a user

    Args:
        db: Database session
        user_id: ID of the user
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return

    Returns:
        Tuple[List[Tool], int]: Tuple of (tools, total_count)
    """
    logger.info(f"Getting favorite tools for user: {user_id}, skip: {skip}, limit: {limit}")
    tools, total_count = tool_favorite.get_favorite_tools(db, user_id, skip=skip, limit=limit)
    tools_with_favorites = tool.get_tools_with_favorite_status(db, user_id, tools)
    return [tool_obj for tool_obj, _ in tools_with_favorites], total_count


def toggle_tool_favorite(db: Session, user_id: uuid.UUID, tool_id: uuid.UUID) -> bool:
    """
    Toggle favorite status of a tool for a user

    Args:
        db: Database session
        user_id: ID of the user
        tool_id: ID of the tool

    Returns:
        bool: True if tool is now favorited, False if unfavorited
    """
    logger.info(f"Toggling favorite status for tool: {tool_id}, user: {user_id}")
    db_obj = tool.get(db, tool_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="tool", resource_id=tool_id)
    return tool_favorite.toggle_favorite(db, user_id, tool_id)


def is_tool_favorite(db: Session, user_id: uuid.UUID, tool_id: uuid.UUID) -> bool:
    """
    Check if a tool is favorited by a user

    Args:
        db: Database session
        user_id: ID of the user
        tool_id: ID of the tool

    Returns:
        bool: True if tool is favorited, False otherwise
    """
    logger.info(f"Checking favorite status for tool: {tool_id}, user: {user_id}")
    return tool_favorite.is_tool_favorited(db, user_id, tool_id)


def record_tool_usage(db: Session, usage_data: Dict[str, Any]) -> ToolUsage:
    """
    Record a user's usage of a tool

    Args:
        db: Database session
        usage_data: Data for the tool usage record

    Returns:
        ToolUsage: Created usage record
    """
    logger.info(f"Recording tool usage with data: {usage_data}")
    return tool_usage.create(db, obj_in=usage_data)


def get_user_tool_usage(
    db: Session, user_id: uuid.UUID, filter_params: Optional[Dict[str, Any]] = None, skip: int = 0, limit: int = 100
) -> Tuple[List[ToolUsage], int]:
    """
    Get a user's tool usage history

    Args:
        db: Database session
        user_id: ID of the user
        filter_params: Optional filters for the usage records
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return

    Returns:
        Tuple[List[ToolUsage], int]: Tuple of (usage_records, total_count)
    """
    logger.info(f"Getting tool usage for user: {user_id}, filter_params: {filter_params}, skip: {skip}, limit: {limit}")
    if filter_params:
        usage_records, total_count = tool_usage.filter_usage_records(db, user_id, **filter_params, skip=skip, limit=limit)
    else:
        usage_records = tool_usage.get_by_user(db, user_id, skip=skip, limit=limit)
        total_count = tool_usage.get_count(db)
    return usage_records, total_count


def get_tool_usage_stats(db: Session, tool_id: uuid.UUID) -> Dict[str, Any]:
    """
    Get usage statistics for a specific tool

    Args:
        db: Database session
        tool_id: ID of the tool

    Returns:
        Dict[str, Any]: Tool usage statistics
    """
    logger.info(f"Getting usage statistics for tool: {tool_id}")
    return tool_usage.get_usage_statistics(db, tool_id)


def get_recommended_tools(
    db: Session,
    user_id: uuid.UUID,
    emotion_type: Optional[EmotionType] = None,
    intensity: Optional[int] = None,
    limit: Optional[int] = None,
    include_premium: Optional[bool] = False,
) -> List[Tool]:
    """
    Get recommended tools for a user based on emotional state

    Args:
        db: Database session
        user_id: ID of the user
        emotion_type: Optional emotion type to filter by
        intensity: Optional intensity of the emotion
        limit: Optional limit for the number of recommendations
        include_premium: Optional flag to include premium tools

    Returns:
        List[Tool]: List of recommended tools
    """
    logger.info(f"Getting recommended tools for user: {user_id}, emotion_type: {emotion_type}, intensity: {intensity}, limit: {limit}, include_premium: {include_premium}")
    recommendations = recommendation_service.get_recommendations_for_emotion(db, emotion_type, intensity, user_id, limit, include_premium)
    return [rec['tool'] for rec in recommendations]


def get_tool_categories() -> List[Dict[str, Any]]:
    """
    Get all tool categories with metadata

    Returns:
        List[Dict[str, Any]]: List of tool categories with metadata
    """
    logger.info("Getting tool categories")
    return [
        {"name": category.name, "value": category.value}
        for category in ToolCategory
    ]


def get_tool_content_types() -> List[Dict[str, Any]]:
    """
    Get all tool content types with metadata

    Returns:
        List[Dict[str, Any]]: List of tool content types with metadata
    """
    logger.info("Getting tool content types")
    return [
        {"name": content_type.name, "value": content_type.value}
        for content_type in ToolContentType
    ]