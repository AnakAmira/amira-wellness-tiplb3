from typing import List, Dict, Optional, Union, Any, Tuple
import uuid
import datetime

from sqlalchemy import select, func, case, and_, or_, desc
from sqlalchemy.orm import Session, aliased

from .base import CRUDBase
from ..models.tool import Tool, ToolFavorite, ToolUsage
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException, ValidationException
from ..constants.tools import ToolCategory, ToolContentType, get_tool_categories_for_emotion, TOOL_RECOMMENDATION_WEIGHTS
from ..constants.emotions import EmotionType

# Initialize logger
logger = get_logger(__name__)


class CRUDTool(CRUDBase[Tool, Any, Any]):
    """
    CRUD operations for the Tool model.
    """
    
    def __init__(self):
        """Initialize the CRUD operations for the Tool model."""
        super().__init__(Tool)
    
    def get_by_category(self, db: Session, category: ToolCategory, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Get tools filtered by category.
        
        Args:
            db: Database session
            category: Tool category to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of tools in the specified category
        """
        query = select(self.model).where(self.model.category == category).offset(skip).limit(limit)
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_content_type(self, db: Session, content_type: ToolContentType, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Get tools filtered by content type.
        
        Args:
            db: Database session
            content_type: Tool content type to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of tools with the specified content type
        """
        query = select(self.model).where(self.model.content_type == content_type).offset(skip).limit(limit)
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_target_emotion(self, db: Session, emotion_type: EmotionType, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Get tools that target a specific emotion.
        
        Args:
            db: Database session
            emotion_type: Emotion type to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of tools targeting the specified emotion
        """
        # Use array contains operator to check if emotion is in target_emotions
        query = select(self.model).where(self.model.target_emotions.contains([emotion_type.value])).offset(skip).limit(limit)
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_active_tools(self, db: Session, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Get all active tools.
        
        Args:
            db: Database session
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of active tools
        """
        query = select(self.model).where(self.model.is_active.is_(True)).offset(skip).limit(limit)
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_premium_tools(self, db: Session, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Get premium tools.
        
        Args:
            db: Database session
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of premium tools
        """
        query = select(self.model).where(self.model.is_premium.is_(True)).offset(skip).limit(limit)
        result = db.execute(query).scalars().all()
        return list(result)
    
    def search_tools(self, db: Session, query: str, skip: int = 0, limit: int = 100) -> List[Tool]:
        """
        Search tools by name or description.
        
        Args:
            db: Database session
            query: Search string to look for in tool name or description
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of tools matching the search query
        """
        search_pattern = f"%{query}%"
        search_query = (
            select(self.model)
            .where(
                or_(
                    self.model.name.ilike(search_pattern),
                    self.model.description.ilike(search_pattern)
                )
            )
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(search_query).scalars().all()
        return list(result)
    
    def filter_tools(
        self,
        db: Session,
        categories: Optional[List[ToolCategory]] = None,
        content_types: Optional[List[ToolContentType]] = None,
        target_emotions: Optional[List[EmotionType]] = None,
        max_duration: Optional[int] = None,
        is_active: Optional[bool] = None,
        is_premium: Optional[bool] = None,
        search_query: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> Tuple[List[Tool], int]:
        """
        Filter tools by multiple criteria.
        
        Args:
            db: Database session
            categories: List of tool categories to include
            content_types: List of content types to include
            target_emotions: List of target emotions to include
            max_duration: Maximum duration in minutes
            is_active: Filter by active status
            is_premium: Filter by premium status
            search_query: Search string for name or description
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (tools, total_count)
        """
        filters = []
        
        # Apply filters
        if categories:
            filters.append(self.model.category.in_([cat for cat in categories]))
            
        if content_types:
            filters.append(self.model.content_type.in_([ct for ct in content_types]))
            
        if target_emotions:
            # Handle array overlap for target_emotions
            emotion_values = [emotion.value for emotion in target_emotions]
            filters.append(self.model.target_emotions.overlap(emotion_values))
            
        if max_duration is not None:
            filters.append(self.model.estimated_duration <= max_duration)
            
        if is_active is not None:
            filters.append(self.model.is_active.is_(is_active))
            
        if is_premium is not None:
            filters.append(self.model.is_premium.is_(is_premium))
            
        if search_query:
            search_pattern = f"%{search_query}%"
            filters.append(
                or_(
                    self.model.name.ilike(search_pattern),
                    self.model.description.ilike(search_pattern)
                )
            )
        
        # Build base query
        base_query = select(self.model)
        if filters:
            base_query = base_query.where(and_(*filters))
        
        # Get total count
        count_query = select(func.count()).select_from(base_query.subquery())
        total_count = db.execute(count_query).scalar_one()
        
        # Apply pagination
        paginated_query = base_query.offset(skip).limit(limit)
        result = db.execute(paginated_query).scalars().all()
        
        return list(result), total_count
    
    def get_tool_with_favorite_status(self, db: Session, tool_id: uuid.UUID, user_id: uuid.UUID) -> Tuple[Optional[Tool], bool]:
        """
        Get a tool with its favorite status for a user.
        
        Args:
            db: Database session
            tool_id: ID of the tool to retrieve
            user_id: ID of the user to check favorite status for
            
        Returns:
            Tuple of (tool, is_favorited)
        """
        # Get the tool
        tool = self.get(db, tool_id)
        if not tool:
            return None, False
        
        # Check if the tool is favorited by the user
        favorite_exists_query = (
            select(func.count())
            .select_from(ToolFavorite)
            .where(
                ToolFavorite.user_id == user_id,
                ToolFavorite.tool_id == tool_id
            )
        )
        favorite_count = db.execute(favorite_exists_query).scalar_one()
        is_favorited = favorite_count > 0
        
        return tool, is_favorited
    
    def get_tools_with_favorite_status(self, db: Session, user_id: uuid.UUID, tools: List[Tool]) -> List[Tuple[Tool, bool]]:
        """
        Get tools with their favorite status for a user.
        
        Args:
            db: Database session
            user_id: ID of the user to check favorite status for
            tools: List of tools to check favorite status for
            
        Returns:
            List of (tool, is_favorited) tuples
        """
        if not tools:
            return []
        
        # Get all tool IDs
        tool_ids = [tool.id for tool in tools]
        
        # Get all favorites for this user and these tools
        favorites_query = (
            select(ToolFavorite.tool_id)
            .where(
                ToolFavorite.user_id == user_id,
                ToolFavorite.tool_id.in_(tool_ids)
            )
        )
        favorited_tool_ids = set(db.execute(favorites_query).scalars().all())
        
        # Create list of (tool, is_favorited) tuples
        result = [(tool, tool.id in favorited_tool_ids) for tool in tools]
        
        return result
    
    def get_recommended_tools(
        self,
        db: Session,
        emotion_type: EmotionType,
        intensity: int,
        user_id: Optional[uuid.UUID] = None,
        include_premium: Optional[bool] = False,
        limit: Optional[int] = 5
    ) -> List[Dict[str, Any]]:
        """
        Get tool recommendations based on emotional state.
        
        Args:
            db: Database session
            emotion_type: Current emotion of the user
            intensity: Intensity of the emotion (1-10)
            user_id: Optional user ID for personalized recommendations
            include_premium: Whether to include premium tools
            limit: Maximum number of tools to recommend
            
        Returns:
            List of recommended tools with relevance scores
        """
        # Get recommended tool categories for this emotion
        recommended_categories = get_tool_categories_for_emotion(emotion_type)
        
        # Start with base query for active tools
        base_query = select(self.model).where(self.model.is_active.is_(True))
        
        # Filter for target emotions
        base_query = base_query.where(self.model.target_emotions.contains([emotion_type.value]))
        
        # Filter premium tools if needed
        if not include_premium:
            base_query = base_query.where(self.model.is_premium.is_(False))
        
        # Calculate relevance score based on multiple factors
        emotional_relevance = TOOL_RECOMMENDATION_WEIGHTS['emotional_relevance']
        category_relevance = TOOL_RECOMMENDATION_WEIGHTS['contextual_factors']
        
        # Create a weighted scoring case statement
        relevance_score = case(
            # Emotional relevance (40%)
            [(self.model.target_emotions.contains([emotion_type.value]), emotional_relevance)],
            # Category relevance (20%)
            else_=0
        )
        
        # Add category relevance if available
        if recommended_categories:
            relevance_score = relevance_score + case(
                [(self.model.category.in_([cat.value for cat in recommended_categories]), category_relevance)],
                else_=0
            )
        
        # Adjust for intensity - different tools are better for different intensity levels
        if intensity >= 7:
            # For high intensity emotions, prioritize calming tools
            relevance_score = relevance_score + case(
                [(self.model.category == ToolCategory.BREATHING.value, 0.1)],
                [(self.model.category == ToolCategory.MEDITATION.value, 0.1)],
                else_=0
            )
        elif intensity <= 3:
            # For low intensity emotions, prioritize different types of tools
            relevance_score = relevance_score + case(
                [(self.model.category == ToolCategory.JOURNALING.value, 0.1)],
                [(self.model.category == ToolCategory.GRATITUDE.value, 0.1)],
                else_=0
            )
        
        # Add the relevance score to the query
        query = (
            base_query
            .add_columns(relevance_score.label('relevance_score'))
            .order_by(desc('relevance_score'))
        )
        
        # If user_id is provided, factor in user preferences
        if user_id:
            # Get user's tool usage history
            usage_subquery = (
                select(ToolUsage.tool_id, func.count().label('usage_count'))
                .where(ToolUsage.user_id == user_id)
                .group_by(ToolUsage.tool_id)
                .subquery()
            )
            
            # Get user's favorites
            favorite_subquery = (
                select(ToolFavorite.tool_id)
                .where(ToolFavorite.user_id == user_id)
                .subquery()
            )
            
            # Add user preference factors
            user_preference_weight = TOOL_RECOMMENDATION_WEIGHTS['user_preferences']
            diversity_weight = TOOL_RECOMMENDATION_WEIGHTS['diversity']
            
            # Join with usage and favorites
            query = (
                query
                .outerjoin(usage_subquery, self.model.id == usage_subquery.c.tool_id)
                .outerjoin(favorite_subquery, self.model.id == favorite_subquery.c.tool_id)
                .add_columns(
                    case(
                        [(usage_subquery.c.usage_count.is_not(None), 
                          user_preference_weight * func.least(usage_subquery.c.usage_count / 10, 0.5))],
                        else_=0
                    ).label('usage_score'),
                    case(
                        [(favorite_subquery.c.tool_id.is_not(None), user_preference_weight * 0.5)],
                        else_=0
                    ).label('favorite_score'),
                    case(
                        [(usage_subquery.c.usage_count.is_(None), diversity_weight)],
                        else_=0
                    ).label('diversity_score')
                )
            )
            
            # Update order by to include all factors
            query = query.order_by(desc(
                relevance_score + 
                case(
                    [(usage_subquery.c.usage_count.is_not(None), 
                      user_preference_weight * func.least(usage_subquery.c.usage_count / 10, 0.5))],
                    else_=0
                ) +
                case(
                    [(favorite_subquery.c.tool_id.is_not(None), user_preference_weight * 0.5)],
                    else_=0
                ) +
                case(
                    [(usage_subquery.c.usage_count.is_(None), diversity_weight)],
                    else_=0
                )
            ))
        
        # Apply limit
        if limit:
            query = query.limit(limit)
        
        # Execute query and format results
        try:
            if user_id:
                results = db.execute(query).all()
                
                # Format results with all relevance factors
                recommendations = []
                for row in results:
                    tool = row[0]
                    relevance_score = row[1]
                    usage_score = row[2] if len(row) > 2 else 0
                    favorite_score = row[3] if len(row) > 3 else 0
                    diversity_score = row[4] if len(row) > 4 else 0
                    
                    total_score = relevance_score + usage_score + favorite_score + diversity_score
                    
                    recommendations.append({
                        'tool': tool,
                        'relevance_score': round(total_score, 2),
                        'emotion_relevance': emotion_type.value in tool.target_emotions,
                        'is_favorited': favorite_score > 0,
                        'category_match': tool.category in [c.value for c in recommended_categories]
                    })
            else:
                results = db.execute(query).all()
                
                # Format results with basic relevance
                recommendations = []
                for row in results:
                    tool = row[0]
                    relevance_score = row[1]
                    
                    recommendations.append({
                        'tool': tool,
                        'relevance_score': round(relevance_score, 2),
                        'emotion_relevance': emotion_type.value in tool.target_emotions,
                        'is_favorited': False,
                        'category_match': tool.category in [c.value for c in recommended_categories]
                    })
                    
            return recommendations
        
        except Exception as e:
            logger.error(f"Error getting recommended tools: {str(e)}")
            return []
    
    def get_tool_statistics(self, db: Session) -> Dict[str, Any]:
        """
        Get usage statistics for tools.
        
        Args:
            db: Database session
            
        Returns:
            Dictionary with tool usage statistics
        """
        try:
            # Get total number of tools
            total_tools_query = select(func.count()).select_from(self.model)
            total_tools = db.execute(total_tools_query).scalar_one()
            
            # Get total number of premium tools
            premium_tools_query = select(func.count()).select_from(self.model).where(self.model.is_premium.is_(True))
            premium_tools = db.execute(premium_tools_query).scalar_one()
            
            # Get tools by category with counts
            category_counts_query = (
                select(self.model.category, func.count().label('count'))
                .group_by(self.model.category)
            )
            category_counts = {
                str(category): count for category, count in db.execute(category_counts_query).all()
            }
            
            # Get most popular tools by usage count
            popular_tools_query = (
                select(
                    self.model, 
                    func.count(ToolUsage.id).label('usage_count')
                )
                .join(ToolUsage, ToolUsage.tool_id == self.model.id)
                .group_by(self.model.id)
                .order_by(desc('usage_count'))
                .limit(10)
            )
            popular_tools = [
                {'tool': tool.to_dict(), 'usage_count': count}
                for tool, count in db.execute(popular_tools_query).all()
            ]
            
            # Get most effective tools by emotional improvement
            # This is simplified and would need to be expanded based on actual data model
            effective_tools_query = (
                select(
                    self.model,
                    func.avg(ToolUsage.duration_seconds).label('avg_duration')
                )
                .join(ToolUsage, ToolUsage.tool_id == self.model.id)
                .group_by(self.model.id)
                .order_by(desc('avg_duration'))
                .limit(10)
            )
            effective_tools = [
                {'tool': tool.to_dict(), 'avg_duration': round(float(duration), 2)}
                for tool, duration in db.execute(effective_tools_query).all()
            ]
            
            # Compile statistics
            statistics = {
                'total_tools': total_tools,
                'premium_tools': premium_tools,
                'tools_by_category': category_counts,
                'popular_tools': popular_tools,
                'effective_tools': effective_tools
            }
            
            return statistics
            
        except Exception as e:
            logger.error(f"Error getting tool statistics: {str(e)}")
            return {
                'total_tools': 0,
                'premium_tools': 0,
                'tools_by_category': {},
                'popular_tools': [],
                'effective_tools': []
            }


class CRUDToolFavorite(CRUDBase[ToolFavorite, Any, Any]):
    """
    CRUD operations for the ToolFavorite model.
    """
    
    def __init__(self):
        """Initialize the CRUD operations for the ToolFavorite model."""
        super().__init__(ToolFavorite)
    
    def get_by_user_and_tool(self, db: Session, user_id: uuid.UUID, tool_id: uuid.UUID) -> Optional[ToolFavorite]:
        """
        Get a favorite by user ID and tool ID.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            
        Returns:
            The favorite if found, None otherwise
        """
        query = (
            select(self.model)
            .where(
                self.model.user_id == user_id,
                self.model.tool_id == tool_id
            )
        )
        result = db.execute(query).scalars().first()
        return result
    
    def get_by_user(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[ToolFavorite]:
        """
        Get all favorites for a user.
        
        Args:
            db: Database session
            user_id: ID of the user
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of favorites for the user
        """
        query = (
            select(self.model)
            .where(self.model.user_id == user_id)
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_favorite_tools(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[List[Tool], int]:
        """
        Get all tools favorited by a user.
        
        Args:
            db: Database session
            user_id: ID of the user
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (tools, total_count)
        """
        # Join with Tool to get the tool objects
        join_query = (
            select(Tool)
            .join(ToolFavorite, ToolFavorite.tool_id == Tool.id)
            .where(ToolFavorite.user_id == user_id)
        )
        
        # Get total count
        count_query = select(func.count()).select_from(join_query.subquery())
        total_count = db.execute(count_query).scalar_one()
        
        # Apply pagination
        paginated_query = join_query.offset(skip).limit(limit)
        tools = db.execute(paginated_query).scalars().all()
        
        return list(tools), total_count
    
    def toggle_favorite(self, db: Session, user_id: uuid.UUID, tool_id: uuid.UUID) -> bool:
        """
        Toggle favorite status for a tool.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            
        Returns:
            True if favorited, False if unfavorited
            
        Raises:
            ResourceNotFoundException: If the tool does not exist
        """
        # Check if the tool exists
        tool_exists = db.execute(
            select(func.count()).select_from(Tool).where(Tool.id == tool_id)
        ).scalar_one()
        
        if not tool_exists:
            raise ResourceNotFoundException(resource_type="tool", resource_id=tool_id)
        
        # Check if the favorite already exists
        existing_favorite = self.get_by_user_and_tool(db, user_id, tool_id)
        
        if existing_favorite:
            # If favorite exists, remove it
            db.delete(existing_favorite)
            db.commit()
            return False
        else:
            # If favorite doesn't exist, create it
            new_favorite = ToolFavorite(user_id=user_id, tool_id=tool_id)
            db.add(new_favorite)
            db.commit()
            return True
    
    def is_tool_favorited(self, db: Session, user_id: uuid.UUID, tool_id: uuid.UUID) -> bool:
        """
        Check if a tool is favorited by a user.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            
        Returns:
            True if favorited, False otherwise
        """
        query = (
            select(func.count())
            .select_from(self.model)
            .where(
                self.model.user_id == user_id,
                self.model.tool_id == tool_id
            )
        )
        result = db.execute(query).scalar_one()
        return result > 0
    
    def get_favorite_count(self, db: Session, tool_id: uuid.UUID) -> int:
        """
        Get the number of users who favorited a tool.
        
        Args:
            db: Database session
            tool_id: ID of the tool
            
        Returns:
            Number of users who favorited the tool
        """
        query = (
            select(func.count())
            .select_from(self.model)
            .where(self.model.tool_id == tool_id)
        )
        result = db.execute(query).scalar_one()
        return result


class CRUDToolUsage(CRUDBase[ToolUsage, Any, Any]):
    """
    CRUD operations for the ToolUsage model.
    """
    
    def __init__(self):
        """Initialize the CRUD operations for the ToolUsage model."""
        super().__init__(ToolUsage)
    
    def get_by_user(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[ToolUsage]:
        """
        Get all tool usage records for a user.
        
        Args:
            db: Database session
            user_id: ID of the user
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of tool usage records for the user
        """
        query = (
            select(self.model)
            .where(self.model.user_id == user_id)
            .order_by(self.model.completed_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_tool(self, db: Session, tool_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[ToolUsage]:
        """
        Get all usage records for a tool.
        
        Args:
            db: Database session
            tool_id: ID of the tool
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of usage records for the tool
        """
        query = (
            select(self.model)
            .where(self.model.tool_id == tool_id)
            .order_by(self.model.completed_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_user_and_tool(self, db: Session, user_id: uuid.UUID, tool_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[ToolUsage]:
        """
        Get usage records for a specific user and tool.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of usage records for the user and tool
        """
        query = (
            select(self.model)
            .where(
                self.model.user_id == user_id,
                self.model.tool_id == tool_id
            )
            .order_by(self.model.completed_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def filter_usage_records(
        self,
        db: Session,
        user_id: uuid.UUID,
        tool_id: Optional[uuid.UUID] = None,
        categories: Optional[List[ToolCategory]] = None,
        completion_statuses: Optional[List[str]] = None,
        min_duration: Optional[int] = None,
        max_duration: Optional[int] = None,
        start_date: Optional[datetime.datetime] = None,
        end_date: Optional[datetime.datetime] = None,
        skip: int = 0,
        limit: int = 100
    ) -> Tuple[List[ToolUsage], int]:
        """
        Filter tool usage records by multiple criteria.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: Optional ID of the tool to filter by
            categories: Optional list of tool categories to filter by
            completion_statuses: Optional list of completion statuses to filter by
            min_duration: Optional minimum duration in seconds
            max_duration: Optional maximum duration in seconds
            start_date: Optional start date for date range filter
            end_date: Optional end date for date range filter
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (usage_records, total_count)
        """
        # Start with base query
        query = (
            select(self.model)
            .join(Tool, Tool.id == self.model.tool_id)
            .where(self.model.user_id == user_id)
        )
        
        # Apply tool_id filter if provided
        if tool_id is not None:
            query = query.where(self.model.tool_id == tool_id)
        
        # Apply categories filter if provided
        if categories:
            query = query.where(Tool.category.in_([cat for cat in categories]))
        
        # Apply completion_statuses filter if provided
        if completion_statuses:
            query = query.where(self.model.completion_status.in_(completion_statuses))
        
        # Apply duration filters if provided
        if min_duration is not None:
            query = query.where(self.model.duration_seconds >= min_duration)
        
        if max_duration is not None:
            query = query.where(self.model.duration_seconds <= max_duration)
        
        # Apply date range filters if provided
        if start_date is not None:
            query = query.where(self.model.completed_at >= start_date)
        
        if end_date is not None:
            query = query.where(self.model.completed_at <= end_date)
            
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        total_count = db.execute(count_query).scalar_one()
        
        # Apply sorting and pagination
        query = (
            query
            .order_by(self.model.completed_at.desc())
            .offset(skip)
            .limit(limit)
        )
        
        result = db.execute(query).scalars().all()
        
        return list(result), total_count
    
    def get_usage_statistics(
        self,
        db: Session,
        user_id: uuid.UUID,
        start_date: Optional[datetime.datetime] = None,
        end_date: Optional[datetime.datetime] = None
    ) -> Dict[str, Any]:
        """
        Get usage statistics for a user.
        
        Args:
            db: Database session
            user_id: ID of the user
            start_date: Optional start date for date range filter
            end_date: Optional end date for date range filter
            
        Returns:
            Dictionary with usage statistics
        """
        try:
            # Base filters for all queries
            filters = [self.model.user_id == user_id]
            
            if start_date is not None:
                filters.append(self.model.completed_at >= start_date)
            
            if end_date is not None:
                filters.append(self.model.completed_at <= end_date)
                
            # Get total number of tool usages
            total_usages_query = (
                select(func.count())
                .select_from(self.model)
                .where(*filters)
            )
            total_usages = db.execute(total_usages_query).scalar_one()
            
            # Get total duration of tool usage
            total_duration_query = (
                select(func.sum(self.model.duration_seconds))
                .select_from(self.model)
                .where(*filters)
            )
            total_duration = db.execute(total_duration_query).scalar_one() or 0
            
            # Get usage by tool category
            usage_by_category_query = (
                select(
                    Tool.category,
                    func.count().label('count'),
                    func.sum(self.model.duration_seconds).label('total_duration')
                )
                .join(Tool, Tool.id == self.model.tool_id)
                .where(*filters)
                .group_by(Tool.category)
            )
            usage_by_category = [
                {
                    'category': str(category),
                    'count': count,
                    'total_duration': duration or 0
                }
                for category, count, duration in db.execute(usage_by_category_query).all()
            ]
            
            # Get usage by completion status
            usage_by_status_query = (
                select(
                    self.model.completion_status,
                    func.count().label('count')
                )
                .where(*filters)
                .group_by(self.model.completion_status)
            )
            usage_by_status = {
                status: count for status, count in db.execute(usage_by_status_query).all()
            }
            
            # Get most used tools
            most_used_tools_query = (
                select(
                    Tool,
                    func.count().label('usage_count'),
                    func.sum(self.model.duration_seconds).label('total_duration')
                )
                .join(Tool, Tool.id == self.model.tool_id)
                .where(*filters)
                .group_by(Tool.id)
                .order_by(desc('usage_count'))
                .limit(10)
            )
            most_used_tools = [
                {
                    'tool': tool.to_dict(),
                    'usage_count': count,
                    'total_duration': duration or 0
                }
                for tool, count, duration in db.execute(most_used_tools_query).all()
            ]
            
            # Get usage by time of day
            usage_by_time_query = (
                select(
                    func.extract('hour', self.model.completed_at).label('hour'),
                    func.count().label('count')
                )
                .where(*filters)
                .group_by('hour')
                .order_by('hour')
            )
            
            usage_by_time = {
                int(hour): count for hour, count in db.execute(usage_by_time_query).all()
            }
            
            # Get usage by day of week
            usage_by_day_query = (
                select(
                    func.extract('dow', self.model.completed_at).label('day'),
                    func.count().label('count')
                )
                .where(*filters)
                .group_by('day')
                .order_by('day')
            )
            
            usage_by_day = {
                int(day): count for day, count in db.execute(usage_by_day_query).all()
            }
            
            # Compile statistics
            statistics = {
                'total_usages': total_usages,
                'total_duration_seconds': total_duration,
                'average_duration_seconds': round(total_duration / total_usages) if total_usages > 0 else 0,
                'usage_by_category': usage_by_category,
                'usage_by_status': usage_by_status,
                'most_used_tools': most_used_tools,
                'usage_by_time_of_day': usage_by_time,
                'usage_by_day_of_week': usage_by_day
            }
            
            return statistics
            
        except Exception as e:
            logger.error(f"Error getting usage statistics: {str(e)}")
            return {
                'total_usages': 0,
                'total_duration_seconds': 0,
                'average_duration_seconds': 0,
                'usage_by_category': [],
                'usage_by_status': {},
                'most_used_tools': [],
                'usage_by_time_of_day': {},
                'usage_by_day_of_week': {}
            }
    
    def get_emotional_impact(
        self,
        db: Session,
        tool_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None
    ) -> Dict[str, Any]:
        """
        Get emotional impact statistics for tools.
        
        Args:
            db: Database session
            tool_id: Optional ID of the tool to analyze
            user_id: Optional ID of the user to analyze
            
        Returns:
            Dictionary with emotional impact statistics
        """
        try:
            # Start with base query - only include records with both pre and post check-ins
            filters = [
                self.model.pre_checkin_id.is_not(None),
                self.model.post_checkin_id.is_not(None)
            ]
            
            if tool_id is not None:
                filters.append(self.model.tool_id == tool_id)
                
            if user_id is not None:
                filters.append(self.model.user_id == user_id)
                
            # Get tool usage records with both pre and post check-ins
            query = select(self.model).where(*filters).limit(1000)  # Limit for performance
            results = db.execute(query).scalars().all()
            
            # Calculate statistics using the get_emotional_shift method
            if results:
                shifts = [usage.get_emotional_shift() for usage in results if usage.get_emotional_shift()]
                
                if shifts:
                    # Calculate average intensity change
                    intensity_changes = [shift['intensity_change'] for shift in shifts]
                    avg_intensity_change = sum(intensity_changes) / len(intensity_changes)
                    
                    # Calculate percentage of positive shifts
                    positive_shifts = sum(1 for shift in shifts if shift['intensity_change'] > 0)
                    positive_shift_percentage = (positive_shifts / len(shifts)) * 100
                    
                    # Calculate most common emotion transitions
                    emotion_transitions = {}
                    for shift in shifts:
                        transition_key = f"{shift['pre_emotion']} -> {shift['post_emotion']}"
                        emotion_transitions[transition_key] = emotion_transitions.get(transition_key, 0) + 1
                    
                    # Get top 5 transitions
                    top_transitions = sorted(
                        [{'transition': k, 'count': v} for k, v in emotion_transitions.items()],
                        key=lambda x: x['count'],
                        reverse=True
                    )[:5]
                    
                    return {
                        'total_records': len(shifts),
                        'average_intensity_change': round(avg_intensity_change, 2),
                        'positive_shift_percentage': round(positive_shift_percentage, 2),
                        'top_emotion_transitions': top_transitions
                    }
            
            # Default empty response
            return {
                'total_records': 0,
                'average_intensity_change': 0,
                'positive_shift_percentage': 0,
                'top_emotion_transitions': []
            }
            
        except Exception as e:
            logger.error(f"Error calculating emotional impact: {str(e)}")
            return {
                'total_records': 0,
                'average_intensity_change': 0,
                'positive_shift_percentage': 0,
                'top_emotion_transitions': []
            }


# Create singleton instances for export
tool = CRUDTool()
tool_favorite = CRUDToolFavorite()
tool_usage = CRUDToolUsage()