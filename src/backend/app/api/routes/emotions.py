# src/backend/app/api/routes/emotions.py
"""
API routes for emotional data in the Amira Wellness application. Implements endpoints for emotional check-ins, trend analysis, pattern detection, and tool recommendations based on emotional states, supporting the core emotional wellness functionality of the application.
"""

import typing
from typing import List, Dict, Any, Optional
import uuid
import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Body, Query, Path, Response  # fastapi==0.104+
from sqlalchemy.orm import Session  # sqlalchemy==2.0+

# Internal imports
from ..api.deps import get_db, get_current_user, validate_resource_ownership, get_client_rate_limit_key
from ..models.emotion import EmotionalCheckin  # Internal import
from ..models.user import User  # Internal import
from ..schemas.emotion import EmotionalStateBase, EmotionalStateCreate, EmotionalState, EmotionalStateFilter, EmotionalStateList, EmotionalShift, EmotionalTrendRequest, EmotionalTrendResponse, EmotionalPatternDetection, EmotionalHealthAnalysis, ToolRecommendationRequest  # Internal import
from ..constants.emotions import EmotionType, EmotionContext, PeriodType  # Internal import
from ..services.emotion import create_emotional_checkin, get_emotional_checkin, get_user_emotional_checkins, get_filtered_emotional_checkins, get_emotion_distribution, analyze_emotional_trends, detect_emotional_patterns, generate_emotional_insights, get_recommended_tools_for_emotion, EmotionAnalysisService  # Internal import
from ..core.logging import get_logger  # Internal import
from ..core.exceptions import ResourceNotFoundException, PermissionDeniedException, ValidationException  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Initialize emotion analysis service
emotion_analysis_service = EmotionAnalysisService()

# Create router for emotion endpoints
router = APIRouter(prefix="/emotions", tags=["emotions"])

def get_emotional_checkin_owner_id(db: Session, checkin_id: uuid.UUID) -> uuid.UUID:
    """
    Helper function to get the owner ID of an emotional check-in for ownership validation

    Args:
        db: Database session
        checkin_id: ID of the emotional check-in

    Returns:
        User ID of the emotional check-in owner
    """
    # Query the database for the emotional check-in with the given ID
    checkin = db.query(EmotionalCheckin).filter(EmotionalCheckin.id == checkin_id).first()

    # If check-in not found, raise ResourceNotFoundException
    if not checkin:
        raise ResourceNotFoundException(resource_type="EmotionalCheckin", resource_id=checkin_id)

    # Return the user_id of the check-in
    return checkin.user_id

@router.post("/", 
             response_model=EmotionalState, 
             status_code=status.HTTP_201_CREATED,
             summary="Create a new emotional check-in",
             description="Creates a new emotional check-in with emotion type, intensity, and context")
def create_emotion(
    checkin_data: EmotionalStateCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalState:
    """
    Create a new emotional check-in
    """
    try:
        # Create emotional check-in data dictionary
        checkin_data_dict = checkin_data.model_dump()
        checkin_data_dict["user_id"] = current_user.id

        # Create emotional check-in using service function
        emotional_checkin = create_emotional_checkin(db, checkin_data_dict)

        # Return created emotional check-in
        return emotional_checkin
    except ValidationException as e:
        # Raise HTTPException for validation errors
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error creating emotional check-in: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/", 
            response_model=EmotionalStateList,
            summary="Get user's emotional check-ins",
            description="Retrieves a paginated list of emotional check-ins for the current user")
def get_emotions(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalStateList:
    """
    Get a list of emotional check-ins for the current user
    """
    try:
        # Get emotional check-ins for user using service function
        checkins, total = get_user_emotional_checkins(db, current_user.id, (page - 1) * page_size, page_size)

        # Return paginated list of emotional check-ins
        return EmotionalStateList(items=checkins, total=total, page=page, page_size=page_size)
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting emotional check-ins: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.post("/filter", 
             response_model=EmotionalStateList,
             summary="Filter emotional check-ins",
             description="Retrieves a filtered list of emotional check-ins based on criteria")
def filter_emotions(
    filter_params: EmotionalStateFilter,
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalStateList:
    """
    Get a filtered list of emotional check-ins
    """
    try:
        # Filter emotional check-ins using service function
        filtered_checkins, total = get_filtered_emotional_checkins(db, filter_params.model_dump(), current_user.id, (page - 1) * page_size, page_size)

        # Return paginated list of filtered emotional check-ins
        return EmotionalStateList(items=filtered_checkins, total=total, page=page, page_size=page_size)
    except ValidationException as e:
        # Raise HTTPException for validation errors
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error filtering emotional check-ins: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/{checkin_id}", 
            response_model=EmotionalState,
            summary="Get a specific emotional check-in",
            description="Retrieves a specific emotional check-in by ID")
def get_emotion(
    checkin_id: uuid.UUID = Path(..., description="The ID of the emotional check-in to retrieve"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalState:
    """
    Get a specific emotional check-in by ID
    """
    try:
        # Validate resource ownership
        validate_resource_ownership(resource_type="EmotionalCheckin", get_resource_owner_id=get_emotional_checkin_owner_id)(resource_id=checkin_id, current_user=current_user)

        # Get emotional check-in using service function
        emotional_checkin = get_emotional_checkin(db, checkin_id, current_user.id)

        # Return emotional check-in
        return emotional_checkin
    except ResourceNotFoundException as e:
        # Raise HTTPException for resource not found
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        # Raise HTTPException for permission denied
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting emotional check-in: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/distribution", 
            response_model=Dict[str, Any],
            summary="Get emotion distribution",
            description="Retrieves the distribution of emotions for the user within a date range")
def get_emotion_distribution_route(
    start_date: Optional[datetime.datetime] = Query(None, description="Start date for the time period"),
    end_date: Optional[datetime.datetime] = Query(None, description="End date for the time period"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Get the distribution of emotions for the user within a date range
    """
    try:
        # Get emotion distribution using service function
        emotion_distribution = get_emotion_distribution(db, current_user.id, start_date, end_date)

        # Return emotion distribution data
        return emotion_distribution
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting emotion distribution: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.post("/trends", 
             response_model=EmotionalTrendResponse,
             summary="Analyze emotional trends",
             description="Analyzes emotional trends for the user over a specified time period")
def analyze_trends(
    trend_request: EmotionalTrendRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalTrendResponse:
    """
    Analyze emotional trends for the user over a specified time period
    """
    try:
        # Analyze emotional trends using service function
        trend_analysis = analyze_emotional_trends(db, current_user.id, trend_request.model_dump())

        # Return trend analysis results
        return EmotionalTrendResponse(**trend_analysis)
    except ValidationException as e:
        # Raise HTTPException for validation errors
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error analyzing emotional trends: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.post("/patterns", 
             response_model=List[Dict[str, Any]],
             summary="Detect emotional patterns",
             description="Detects patterns in emotional data for the user")
def detect_patterns(
    detection_params: EmotionalPatternDetection,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """
    Detect patterns in emotional data for the user
    """
    try:
        # Detect emotional patterns using service function
        patterns = detect_emotional_patterns(db, current_user.id, detection_params.model_dump())

        # Return detected patterns
        return patterns
    except ValidationException as e:
        # Raise HTTPException for validation errors
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error detecting emotional patterns: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/insights", 
            response_model=List[Dict[str, Any]],
            summary="Generate emotional insights",
            description="Generates insights from emotional data for the user")
def generate_insights_route(
    start_date: Optional[datetime.datetime] = Query(None, description="Start date for the analysis period"),
    end_date: Optional[datetime.datetime] = Query(None, description="End date for the analysis period"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """
    Generate insights from emotional data for the user
    """
    try:
        # Generate emotional insights using service function
        insights = generate_emotional_insights(db, current_user.id, start_date, end_date)

        # Return generated insights
        return insights
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error generating emotional insights: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.post("/recommendations", 
             response_model=List[Dict[str, Any]],
             summary="Get tool recommendations",
             description="Retrieves tool recommendations based on emotional state")
def get_tool_recommendations(
    recommendation_request: ToolRecommendationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """
    Get tool recommendations based on emotional state
    """
    try:
        # Get tool recommendations using service function
        recommendations = get_recommended_tools_for_emotion(db, current_user.id, recommendation_request.emotion_type, recommendation_request.intensity, recommendation_request.limit)

        # Return list of recommended tools
        return recommendations
    except ValidationException as e:
        # Raise HTTPException for validation errors
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=e.to_dict())
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting tool recommendations: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/health-analysis", 
            response_model=EmotionalHealthAnalysis,
            summary="Analyze emotional health",
            description="Performs comprehensive analysis of a user's emotional health")
def analyze_emotional_health_route(
    start_date: Optional[datetime.datetime] = Query(None, description="Start date for the analysis period"),
    end_date: Optional[datetime.datetime] = Query(None, description="End date for the analysis period"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalHealthAnalysis:
    """
    Analyze emotional health
    """
    try:
        # Analyze emotional health using service function
        analysis_results = emotion_analysis_service.analyze_emotional_health(db, current_user.id, start_date, end_date)

        # Return comprehensive emotional health analysis
        return EmotionalHealthAnalysis(**analysis_results)
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error analyzing emotional health: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/by-journal/{journal_id}", 
            response_model=List[EmotionalState],
            summary="Get emotional check-ins for journal",
            description="Retrieves emotional check-ins related to a specific journal entry")
def get_emotions_by_journal(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal entry"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[EmotionalState]:
    """
    Get emotional check-ins related to a specific journal entry
    """
    try:
        # Get emotional check-ins for journal using service function
        emotional_checkins = emotion.get_by_journal(db, journal_id)

        # Return list of emotional check-ins
        return emotional_checkins
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting emotional check-ins for journal: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

@router.get("/by-tool/{tool_id}", 
            response_model=EmotionalStateList,
            summary="Get emotional check-ins for tool",
            description="Retrieves emotional check-ins related to a specific tool usage")
def get_emotions_by_tool(
    tool_id: uuid.UUID = Path(..., description="The ID of the tool"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalStateList:
    """
    Get emotional check-ins related to a specific tool usage
    """
    try:
        # Get emotional check-ins for tool using service function
        emotional_checkins, total = emotion.get_by_tool(db, tool_id, (page - 1) * page_size, page_size)

        # Return list of emotional check-ins
        return EmotionalStateList(items=emotional_checkins, total=total, page=page, page_size=page_size)
    except Exception as e:
        # Log unexpected exceptions
        logger.error(f"Unexpected error getting emotional check-ins for tool: {str(e)}")
        # Raise HTTPException for internal server error
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error_code": "SYS_INTERNAL_ERROR", "message": "Internal server error"})

# Export the router