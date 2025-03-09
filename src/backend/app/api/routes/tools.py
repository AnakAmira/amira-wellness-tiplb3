"""
FastAPI router for the Tool Library feature in the Amira Wellness application.
Defines API endpoints for managing emotional regulation tools, tool favorites,
tool usage tracking, and personalized recommendations.
"""

import typing
from typing import List, Dict, Optional, Any
import uuid

from fastapi import APIRouter, Depends, HTTPException, status  # fastapi: 0.95.0
from fastapi.security import Security
from sqlalchemy.orm import Session  # sqlalchemy 2.0+

# Internal imports
from ..api.deps import get_db, get_current_user, get_current_premium_user, get_optional_current_user, validate_resource_ownership
from ..schemas.tool import ToolBase, ToolCreate, ToolUpdate, Tool, ToolSummary, ToolFilter, ToolList, ToolFavoriteCreate, ToolFavorite, ToolUsageCreate, ToolUsage, ToolUsageFilter, ToolUsageList, ToolUsageStatistics, ToolRecommendationRequest, ToolRecommendationResponse, ToolLibraryStats
from ..constants.tools import ToolCategory, ToolContentType, EmotionType
from ..services.tool import get_tool, get_tools, get_filtered_tools, get_tools_by_category, get_tools_by_emotion, create_tool, update_tool, delete_tool, get_user_favorite_tools, toggle_tool_favorite, record_tool_usage, get_user_tool_usage, get_tool_usage_stats, get_recommended_tools, get_tool_categories, get_tool_content_types
from ..core.exceptions import ResourceNotFoundException, ValidationException
from ..core.logging import get_logger

# Initialize logger
logger = get_logger(__name__)

# Create router for tool-related endpoints
router = APIRouter(prefix="/tools", tags=["tools"])


@router.get("/{tool_id}", response_model=Tool)
def get_tool_by_id(
    tool_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: Optional[typing.Any] = Depends(get_optional_current_user)
) -> Tool:
    """
    Get a tool by ID with optional favorite status
    """
    logger.info(f"Getting tool with id: {tool_id}")
    tool_obj, is_favorited = get_tool(db, tool_id, getattr(current_user, "id", None))
    if not tool_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {tool_id} not found",
        )
    tool_data = tool_obj.__dict__
    tool_data["is_favorited"] = is_favorited
    return Tool(**tool_data)


@router.get("/", response_model=ToolList)
def get_all_tools(
    filter_params: ToolFilter = Depends(),
    db: Session = Depends(get_db),
    current_user: Optional[typing.Any] = Depends(get_optional_current_user)
) -> ToolList:
    """
    Get all tools with pagination and optional filtering
    """
    logger.info(f"Getting tools with filters: {filter_params}")
    tools, total = get_filtered_tools(
        db,
        categories=filter_params.categories,
        content_types=filter_params.content_types,
        target_emotions=filter_params.target_emotions,
        max_duration=filter_params.max_duration,
        is_active=filter_params.is_active,
        is_premium=filter_params.is_premium,
        search_query=filter_params.search_query,
        favorites_only=filter_params.favorites_only,
        user_id=getattr(current_user, "id", None),
        skip=filter_params.page_size * (filter_params.page - 1),
        limit=filter_params.page_size,
    )
    return ToolList(
        items=tools,
        total=total,
        page=filter_params.page,
        page_size=filter_params.page_size,
    )


@router.get("/category/{category}", response_model=ToolList)
def get_tools_by_category_endpoint(
    category: ToolCategory,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: Optional[typing.Any] = Depends(get_optional_current_user)
) -> ToolList:
    """
    Get tools by category with pagination
    """
    logger.info(f"Getting tools by category: {category}")
    tools, total = get_tools_by_category(
        db,
        category=category,
        skip=skip,
        limit=limit,
        user_id=getattr(current_user, "id", None),
    )
    return ToolList(items=tools, total=total, page=skip // limit + 1, page_size=limit)


@router.get("/emotion/{emotion_type}", response_model=ToolList)
def get_tools_by_emotion_endpoint(
    emotion_type: EmotionType,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: Optional[typing.Any] = Depends(get_optional_current_user)
) -> ToolList:
    """
    Get tools targeting a specific emotion
    """
    logger.info(f"Getting tools by emotion: {emotion_type}")
    tools, total = get_tools_by_emotion(
        db,
        emotion_type=emotion_type,
        skip=skip,
        limit=limit,
        user_id=getattr(current_user, "id", None),
    )
    return ToolList(items=tools, total=total, page=skip // limit + 1, page_size=limit)


@router.post("/", response_model=Tool, status_code=status.HTTP_201_CREATED)
def create_tool_endpoint(
    tool_data: ToolCreate,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> Tool:
    """
    Create a new tool (admin only)
    """
    logger.info(f"Creating tool with data: {tool_data}")
    # Verify that the current user has admin privileges
    # Placeholder for admin check logic
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required to create tools",
        )
    return create_tool(db, tool_data)


@router.put("/{tool_id}", response_model=Tool)
def update_tool_endpoint(
    tool_id: uuid.UUID,
    tool_data: ToolUpdate,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> Tool:
    """
    Update an existing tool (admin only)
    """
    logger.info(f"Updating tool with id: {tool_id}, data: {tool_data}")
    # Verify that the current user has admin privileges
    # Placeholder for admin check logic
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required to update tools",
        )
    try:
        return update_tool(db, tool_id, tool_data)
    except ResourceNotFoundException:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {tool_id} not found",
        )


@router.delete("/{tool_id}", status_code=status.HTTP_200_OK)
def delete_tool_endpoint(
    tool_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> Dict[str, bool]:
    """
    Delete a tool (admin only)
    """
    logger.info(f"Deleting tool with id: {tool_id}")
    # Verify that the current user has admin privileges
    # Placeholder for admin check logic
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required to delete tools",
        )
    try:
        delete_tool(db, tool_id)
        return {"success": True}
    except ResourceNotFoundException:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {tool_id} not found",
        )


@router.get("/favorites", response_model=ToolList)
def get_favorite_tools_endpoint(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolList:
    """
    Get tools favorited by the current user
    """
    logger.info(f"Getting favorite tools for user: {current_user.id}")
    tools, total = get_user_favorite_tools(
        db, user_id=current_user.id, skip=skip, limit=limit
    )
    return ToolList(items=tools, total=total, page=skip // limit + 1, page_size=limit)


@router.post("/favorites/{tool_id}", status_code=status.HTTP_200_OK)
def toggle_favorite_endpoint(
    tool_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> Dict[str, bool]:
    """
    Toggle favorite status of a tool for the current user
    """
    logger.info(f"Toggling favorite status for tool: {tool_id}, user: {current_user.id}")
    try:
        is_favorited = toggle_tool_favorite(db, user_id=current_user.id, tool_id=tool_id)
        return {"is_favorited": is_favorited}
    except ResourceNotFoundException:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {tool_id} not found",
        )


@router.post("/usage", response_model=ToolUsage, status_code=status.HTTP_201_CREATED)
def record_tool_usage_endpoint(
    usage_data: ToolUsageCreate,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolUsage:
    """
    Record a user's usage of a tool
    """
    logger.info(f"Recording tool usage for user: {current_user.id}, tool: {usage_data.tool_id}")
    # Set user_id in usage_data if not provided
    usage_data.user_id = current_user.id
    try:
        return record_tool_usage(db, usage_data.__dict__)
    except ResourceNotFoundException:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {usage_data.tool_id} not found",
        )


@router.get("/usage", response_model=ToolUsageList)
def get_user_tool_usage_endpoint(
    filter_params: ToolUsageFilter = Depends(),
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolUsageList:
    """
    Get a user's tool usage history
    """
    logger.info(f"Getting tool usage for user: {current_user.id}, filter_params: {filter_params}")
    usage_records, total = get_user_tool_usage(
        db,
        user_id=current_user.id,
        filter_params=filter_params.__dict__,
        skip=filter_params.page_size * (filter_params.page - 1),
        limit=filter_params.page_size,
    )
    return ToolUsageList(items=usage_records, total=total, page=filter_params.page, page_size=filter_params.page_size)


@router.get("/usage/stats/{tool_id}", response_model=ToolUsageStatistics)
def get_tool_usage_stats_endpoint(
    tool_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolUsageStatistics:
    """
    Get usage statistics for a specific tool
    """
    logger.info(f"Getting usage statistics for tool: {tool_id}")
    try:
        return get_tool_usage_stats(db, tool_id)
    except ResourceNotFoundException:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tool with id {tool_id} not found",
        )


@router.post("/recommendations", response_model=ToolRecommendationResponse)
def get_recommended_tools_endpoint(
    request_data: ToolRecommendationRequest,
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolRecommendationResponse:
    """
    Get recommended tools based on emotional state
    """
    logger.info(f"Getting recommended tools for user: {current_user.id}, emotion: {request_data.emotion_type}, intensity: {request_data.intensity}")
    recommendations = get_recommended_tools(
        db,
        user_id=current_user.id,
        emotion_type=request_data.emotion_type,
        intensity=request_data.intensity,
        limit=request_data.limit,
        include_premium=request_data.include_premium
    )
    return ToolRecommendationResponse(
        emotion_type=request_data.emotion_type,
        intensity=request_data.intensity,
        recommendations=recommendations
    )


@router.get("/categories", response_model=List[Dict[str, Any]])
def get_tool_categories_endpoint() -> List[Dict[str, Any]]:
    """
    Get all tool categories with metadata
    """
    logger.info("Getting tool categories")
    return get_tool_categories()


@router.get("/content-types", response_model=List[Dict[str, Any]])
def get_tool_content_types_endpoint() -> List[Dict[str, Any]]:
    """
    Get all tool content types with metadata
    """
    logger.info("Getting tool content types")
    return get_tool_content_types()


@router.get("/stats", response_model=ToolLibraryStats)
def get_tool_library_stats_endpoint(
    db: Session = Depends(get_db),
    current_user: typing.Any = Depends(get_current_user)
) -> ToolLibraryStats:
    """
    Get overall statistics for the tool library (admin only)
    """
    logger.info("Getting tool library statistics")
    # Verify that the current user has admin privileges
    # Placeholder for admin check logic
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required to view tool library statistics",
        )
    # Call the tool.get_tool_statistics service function
    # Return the library statistics
    return tool.get_tool_statistics(db)