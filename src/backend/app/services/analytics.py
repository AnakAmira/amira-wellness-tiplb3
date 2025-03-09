"""
Analytics service for the Amira Wellness application.

This module provides functionality for analyzing user emotional data,
generating insights, and providing personalized recommendations while
maintaining privacy and data protection.
"""

# Standard library imports
from typing import List, Dict, Any, Optional, Tuple, Union
from datetime import datetime, timedelta
import uuid
from collections import Counter, defaultdict

# External library imports
import sqlalchemy  # sqlalchemy 2.0+
import pandas as pd  # pandas 2.1+
import numpy as np  # numpy 1.24+
import scipy.stats as stats  # scipy 1.10+

# Internal imports
from ..core.config import settings, ENVIRONMENT
from ..core.logging import get_logger, sanitize_log_data
from ..models.user import User
from ..models.journal import Journal
from ..models.emotion import EmotionalCheckin, EmotionalTrend, EmotionalInsight
from ..models.tool import Tool, ToolUsage
from ..models.progress import UserActivity, UsageStatistics, ProgressInsight
from ..constants.emotions import EmotionType, PeriodType, TrendDirection
from ..constants.tools import ToolCategory, ToolDifficulty
from ..utils.date_helpers import (
    get_current_date, get_date_n_days_ago,
    group_by_day, group_by_week, group_by_month
)

# Set up logger
logger = get_logger(__name__)

# Constants
DEFAULT_ANALYSIS_PERIOD_DAYS = 30
MINIMUM_DATA_POINTS_FOR_TREND = 5
MINIMUM_DATA_POINTS_FOR_INSIGHT = 10
MINIMUM_DATA_POINTS_FOR_PATTERN = 7
MINIMUM_DATA_POINTS_FOR_CORRELATION = 7
INSIGHT_CONFIDENCE_THRESHOLD = 0.7


class EmotionalPatternAnalyzer:
    """
    Specialized class for analyzing emotional patterns and trends.
    
    This class provides methods for detecting patterns, correlations,
    and trends in emotional data to generate meaningful insights.
    """
    
    def __init__(self):
        """Initialize the emotional pattern analyzer"""
        self.logger = logger
        self.logger.info("Emotional pattern analyzer initialized")
    
    def detect_patterns(self, checkins: List[EmotionalCheckin]) -> Dict:
        """
        Detects patterns in emotional data.
        
        Args:
            checkins: List of emotional check-ins to analyze
            
        Returns:
            Dictionary of detected patterns in the emotional data
        """
        self.logger.info(f"Detecting patterns in {len(checkins)} emotional check-ins")
        
        patterns = {}
        
        if len(checkins) < MINIMUM_DATA_POINTS_FOR_PATTERN:
            return patterns
        
        # Sort check-ins by timestamp
        sorted_checkins = sorted(checkins, key=lambda c: c.created_at)
        
        # Group check-ins by time of day
        time_of_day_groups = defaultdict(list)
        for checkin in sorted_checkins:
            hour = checkin.created_at.hour
            
            # Assign time of day
            if 5 <= hour < 12:
                time_of_day = "MORNING"
            elif 12 <= hour < 17:
                time_of_day = "AFTERNOON"
            elif 17 <= hour < 21:
                time_of_day = "EVENING"
            else:
                time_of_day = "NIGHT"
                
            time_of_day_groups[time_of_day].append(checkin)
        
        # Group check-ins by day of week
        day_of_week_groups = defaultdict(list)
        for checkin in sorted_checkins:
            day_of_week = checkin.created_at.strftime("%A").upper()
            day_of_week_groups[day_of_week].append(checkin)
        
        # Detect time of day patterns
        time_patterns = self._detect_time_patterns(time_of_day_groups)
        if time_patterns:
            patterns["TIME_OF_DAY"] = time_patterns
        
        # Detect day of week patterns
        day_patterns = self._detect_day_patterns(day_of_week_groups)
        if day_patterns:
            patterns["DAY_OF_WEEK"] = day_patterns
        
        # Detect emotion cycles
        cycle_patterns = self._detect_emotion_cycles(sorted_checkins)
        if cycle_patterns:
            patterns["EMOTION_CYCLE"] = cycle_patterns
        
        # Detect intensity patterns
        intensity_patterns = self._detect_intensity_patterns(sorted_checkins)
        if intensity_patterns:
            patterns["INTENSITY"] = intensity_patterns
        
        self.logger.info(f"Detected {len(patterns)} pattern types")
        return patterns
    
    def _detect_time_patterns(self, time_of_day_groups: Dict) -> Dict:
        """
        Detects patterns related to time of day.
        
        Args:
            time_of_day_groups: Check-ins grouped by time of day
            
        Returns:
            Dictionary with time of day pattern data
        """
        # Count emotions by time of day
        time_emotions = defaultdict(Counter)
        for time_of_day, checkins in time_of_day_groups.items():
            for checkin in checkins:
                time_emotions[time_of_day][checkin.emotion_type] += 1
        
        # Find dominant emotion for each time of day
        dominant_emotions = {}
        for time_of_day, emotions in time_emotions.items():
            if emotions:
                dominant_emotion = emotions.most_common(1)[0][0]
                count = emotions[dominant_emotion]
                total = sum(emotions.values())
                confidence = count / total if total > 0 else 0
                
                if confidence >= 0.6 and count >= 3:  # Minimum threshold
                    dominant_emotions[time_of_day] = {
                        "emotion": dominant_emotion,
                        "count": count,
                        "total": total,
                        "confidence": confidence
                    }
        
        if not dominant_emotions:
            return None
        
        # Translate time of day into human-readable descriptions
        time_descriptions = {
            "MORNING": "mañanas",
            "AFTERNOON": "tardes",
            "EVENING": "noches",
            "NIGHT": "noches tardías"
        }
        
        # Create pattern description
        strongest_pattern = max(dominant_emotions.items(), key=lambda x: x[1]["confidence"])
        time_of_day = strongest_pattern[0]
        pattern_data = strongest_pattern[1]
        
        pattern = {
            "description": f"Tiendes a sentir {pattern_data['emotion'].value.lower()} por las {time_descriptions[time_of_day]}",
            "emotions": [pattern_data["emotion"]],
            "confidence": pattern_data["confidence"],
            "data": dominant_emotions
        }
        
        return pattern
    
    def _detect_day_patterns(self, day_of_week_groups: Dict) -> Dict:
        """
        Detects patterns related to day of week.
        
        Args:
            day_of_week_groups: Check-ins grouped by day of week
            
        Returns:
            Dictionary with day of week pattern data
        """
        # Count emotions by day of week
        day_emotions = defaultdict(Counter)
        for day_of_week, checkins in day_of_week_groups.items():
            for checkin in checkins:
                day_emotions[day_of_week][checkin.emotion_type] += 1
        
        # Find dominant emotion for each day of week
        dominant_emotions = {}
        for day_of_week, emotions in day_emotions.items():
            if emotions:
                dominant_emotion = emotions.most_common(1)[0][0]
                count = emotions[dominant_emotion]
                total = sum(emotions.values())
                confidence = count / total if total > 0 else 0
                
                if confidence >= 0.6 and count >= 3:  # Minimum threshold
                    dominant_emotions[day_of_week] = {
                        "emotion": dominant_emotion,
                        "count": count,
                        "total": total,
                        "confidence": confidence
                    }
        
        if not dominant_emotions:
            return None
        
        # Translate days of week into Spanish
        day_translations = {
            "MONDAY": "lunes",
            "TUESDAY": "martes",
            "WEDNESDAY": "miércoles",
            "THURSDAY": "jueves",
            "FRIDAY": "viernes",
            "SATURDAY": "sábados",
            "SUNDAY": "domingos"
        }
        
        # Create pattern description
        strongest_pattern = max(dominant_emotions.items(), key=lambda x: x[1]["confidence"])
        day_of_week = strongest_pattern[0]
        pattern_data = strongest_pattern[1]
        
        pattern = {
            "description": f"Tiendes a sentir {pattern_data['emotion'].value.lower()} los {day_translations[day_of_week]}",
            "emotions": [pattern_data["emotion"]],
            "confidence": pattern_data["confidence"],
            "data": dominant_emotions
        }
        
        return pattern
    
    def _detect_emotion_cycles(self, sorted_checkins: List[EmotionalCheckin]) -> Dict:
        """
        Detects cyclical patterns in emotions.
        
        Args:
            sorted_checkins: List of check-ins sorted by timestamp
            
        Returns:
            Dictionary with emotion cycle pattern data
        """
        if len(sorted_checkins) < 10:  # Need sufficient data for cycle detection
            return None
        
        # Extract timestamps and emotions
        timestamps = [c.created_at for c in sorted_checkins]
        emotions = [c.emotion_type for c in sorted_checkins]
        
        # Look for repeating patterns of emotions
        emotion_sequences = []
        
        # Try different window sizes (2-5 emotions in a sequence)
        for window_size in range(2, 6):
            if len(emotions) < window_size * 2:
                continue
                
            # Slide window and look for repeating patterns
            for i in range(len(emotions) - window_size * 2 + 1):
                # Define the potential pattern
                pattern = emotions[i:i+window_size]
                pattern_vals = [e.value for e in pattern]
                
                # Look for occurrences of this pattern
                occurrences = []
                for j in range(i, len(emotions) - window_size + 1, 1):
                    window = emotions[j:j+window_size]
                    window_vals = [e.value for e in window]
                    
                    if window_vals == pattern_vals:
                        occurrences.append(j)
                
                # If pattern occurs multiple times and hasn't been recorded yet
                if len(occurrences) >= 2 and pattern_vals not in [seq["pattern"] for seq in emotion_sequences]:
                    # Calculate average time between occurrences
                    if len(occurrences) >= 2:
                        time_diffs = []
                        for j in range(1, len(occurrences)):
                            time_diff = timestamps[occurrences[j]] - timestamps[occurrences[j-1]]
                            time_diffs.append(time_diff.total_seconds() / 3600)  # Convert to hours
                        
                        avg_time_diff = sum(time_diffs) / len(time_diffs)
                        
                        emotion_sequences.append({
                            "pattern": pattern_vals,
                            "emotions": pattern,
                            "occurrences": occurrences,
                            "avg_time_diff": avg_time_diff,
                            "confidence": len(occurrences) / (len(emotions) - window_size + 1)
                        })
        
        if not emotion_sequences:
            return None
        
        # Sort by confidence
        emotion_sequences.sort(key=lambda x: x["confidence"], reverse=True)
        best_sequence = emotion_sequences[0]
        
        # Create pattern description
        emotion_names = [e.value.lower() for e in best_sequence["emotions"]]
        
        # Format cycle time in a readable way
        hours = best_sequence["avg_time_diff"]
        if hours < 24:
            time_str = f"{int(hours)} horas"
        else:
            days = hours / 24
            time_str = f"{int(days)} días"
        
        pattern = {
            "description": f"Tiendes a experimentar un ciclo de emociones: {', '.join(emotion_names)} cada {time_str}",
            "emotions": best_sequence["emotions"],
            "confidence": best_sequence["confidence"],
            "data": best_sequence
        }
        
        return pattern
    
    def _detect_intensity_patterns(self, sorted_checkins: List[EmotionalCheckin]) -> Dict:
        """
        Detects patterns in emotion intensity.
        
        Args:
            sorted_checkins: List of check-ins sorted by timestamp
            
        Returns:
            Dictionary with intensity pattern data
        """
        if len(sorted_checkins) < MINIMUM_DATA_POINTS_FOR_TREND:
            return None
        
        # Extract intensities and timestamps
        intensities = [c.intensity for c in sorted_checkins]
        timestamps = [c.created_at for c in sorted_checkins]
        emotions = [c.emotion_type for c in sorted_checkins]
        
        # Check for time-based intensity patterns
        try:
            # Convert timestamps to numeric values (days since first timestamp)
            days = [(t - timestamps[0]).total_seconds() / 86400 for t in timestamps]
            
            # Look for correlation between time and intensity
            slope, intercept, r_value, p_value, std_err = stats.linregress(days, intensities)
            r_squared = r_value ** 2
            
            # Check if there's a significant correlation
            if p_value < 0.05 and abs(r_value) >= 0.3:
                # Determine if intensities are increasing or decreasing
                if slope > 0:
                    direction = "aumentado"
                    emotion_type = max(Counter(emotions)).value.lower()
                else:
                    direction = "disminuido"
                    emotion_type = max(Counter(emotions)).value.lower()
                
                pattern = {
                    "description": f"La intensidad de tus emociones ha {direction} con el tiempo",
                    "emotions": list(set(emotions)),
                    "confidence": min(1.0, abs(r_value)),
                    "data": {
                        "slope": slope,
                        "r_squared": r_squared,
                        "p_value": p_value,
                        "emotion_type": emotion_type
                    }
                }
                
                return pattern
        except Exception as e:
            self.logger.error(f"Error detecting intensity patterns: {str(e)}")
        
        # If no time-based pattern, check for emotion-specific intensity patterns
        emotion_intensities = defaultdict(list)
        for checkin in sorted_checkins:
            emotion_intensities[checkin.emotion_type].append(checkin.intensity)
        
        # Find emotions with consistently high or low intensity
        significant_intensities = {}
        for emotion, intensities in emotion_intensities.items():
            if len(intensities) < 3:
                continue
            
            avg_intensity = sum(intensities) / len(intensities)
            
            if avg_intensity >= 7.5:
                significant_intensities[emotion.value] = {
                    "average": avg_intensity,
                    "count": len(intensities),
                    "type": "alta"
                }
            elif avg_intensity <= 3.5:
                significant_intensities[emotion.value] = {
                    "average": avg_intensity,
                    "count": len(intensities),
                    "type": "baja"
                }
        
        if not significant_intensities:
            return None
        
        # Create pattern description for the most significant intensity
        most_significant = max(significant_intensities.items(), key=lambda x: x[1]["count"])
        emotion = most_significant[0]
        intensity_data = most_significant[1]
        
        pattern = {
            "description": f"Sueles experimentar {emotion.lower()} con intensidad {intensity_data['type']}",
            "emotions": [EmotionType(emotion)],
            "confidence": min(1.0, intensity_data["count"] / 10),  # Scale with number of occurrences, max at 10
            "data": significant_intensities
        }
        
        return pattern
    
    def detect_correlations(self, checkins: List[EmotionalCheckin], 
                          activities: List[UserActivity]) -> Dict:
        """
        Detects correlations between emotions and activities.
        
        Args:
            checkins: List of emotional check-ins
            activities: List of user activities
            
        Returns:
            Dictionary of detected correlations between emotions and activities
        """
        self.logger.info(f"Detecting correlations between {len(checkins)} check-ins and {len(activities)} activities")
        
        correlations = {}
        
        if len(checkins) < MINIMUM_DATA_POINTS_FOR_CORRELATION or len(activities) < MINIMUM_DATA_POINTS_FOR_CORRELATION:
            return correlations
        
        # Align emotional check-ins and activities by timestamp
        aligned_data = self._align_checkins_and_activities(checkins, activities)
        
        # Calculate correlation coefficients
        emotion_activity_correlations = self._calculate_correlations(aligned_data)
        
        # Find significant correlations
        significant_correlations = self._filter_significant_correlations(emotion_activity_correlations)
        
        # Format correlations as insights
        for corr_type, corr_data in significant_correlations.items():
            correlations[corr_type] = {
                "description": corr_data["description"],
                "emotions": corr_data["emotions"],
                "confidence": corr_data["confidence"],
                "data": corr_data["data"],
                "recommendations": corr_data.get("recommendations", [])
            }
        
        self.logger.info(f"Detected {len(correlations)} correlation types")
        return correlations
    
    def _align_checkins_and_activities(self, checkins: List[EmotionalCheckin], 
                                    activities: List[UserActivity]) -> List[Dict]:
        """
        Aligns emotional check-ins with activities based on timestamps.
        
        Args:
            checkins: List of emotional check-ins
            activities: List of user activities
            
        Returns:
            List of aligned data points with emotions and activities
        """
        # Sort by timestamp
        sorted_checkins = sorted(checkins, key=lambda c: c.created_at)
        sorted_activities = sorted(activities, key=lambda a: a.activity_date)
        
        aligned_data = []
        
        # For each check-in, find activities within a time window
        for checkin in sorted_checkins:
            # Define a time window around the check-in (e.g., 6 hours before and after)
            window_start = checkin.created_at - timedelta(hours=6)
            window_end = checkin.created_at + timedelta(hours=6)
            
            # Find activities within this window
            window_activities = [
                a for a in sorted_activities 
                if window_start <= a.activity_date <= window_end
            ]
            
            # Add to aligned data if there are activities in the window
            if window_activities:
                aligned_data.append({
                    "checkin": checkin,
                    "activities": window_activities,
                    "timestamp": checkin.created_at
                })
        
        return aligned_data
    
    def _calculate_correlations(self, aligned_data: List[Dict]) -> Dict:
        """
        Calculates correlation coefficients between activities and emotions.
        
        Args:
            aligned_data: List of aligned data points
            
        Returns:
            Dictionary of correlation coefficients
        """
        if not aligned_data:
            return {}
        
        # Count co-occurrences of emotions and activities
        emotion_activity_counts = defaultdict(Counter)
        emotion_counts = Counter()
        activity_counts = Counter()
        
        for data_point in aligned_data:
            emotion = data_point["checkin"].emotion_type
            emotion_counts[emotion] += 1
            
            for activity in data_point["activities"]:
                activity_type = activity.activity_type
                activity_counts[activity_type] += 1
                emotion_activity_counts[emotion][activity_type] += 1
        
        # Calculate correlation coefficients
        correlations = {}
        
        for emotion, activities in emotion_activity_counts.items():
            emotion_correlations = {}
            
            for activity_type, count in activities.items():
                # Calculate expected count under independence assumption
                expected = (emotion_counts[emotion] * activity_counts[activity_type]) / len(aligned_data)
                
                # Calculate phi coefficient (similar to correlation coefficient)
                if expected > 0:
                    lift = count / expected
                    
                    if lift > 1.5:  # Significant positive correlation
                        emotion_correlations[activity_type.value] = {
                            "count": count,
                            "expected": expected,
                            "lift": lift,
                            "strength": min(1.0, (lift - 1) / 2)  # Normalize to 0-1 scale
                        }
            
            if emotion_correlations:
                correlations[emotion.value] = emotion_correlations
        
        return correlations
    
    def _filter_significant_correlations(self, correlations: Dict) -> Dict:
        """
        Filters correlations to identify significant ones.
        
        Args:
            correlations: Dictionary of correlation coefficients
            
        Returns:
            Dictionary of significant correlations
        """
        significant = {}
        
        for emotion, activities in correlations.items():
            # Find the strongest correlation for this emotion
            if not activities:
                continue
                
            strongest_activity = max(activities.items(), key=lambda x: x[1]["strength"])
            activity_type = strongest_activity[0]
            corr_data = strongest_activity[1]
            
            if corr_data["strength"] >= 0.3:  # Minimum threshold for significance
                # Create an insight about this correlation
                emotion_name = EmotionType(emotion).value.lower()
                activity_desc = self._get_activity_description(activity_type)
                
                insight_type = "ACTIVITY_EMOTION_CORRELATION"
                description = f"Tiendes a sentir {emotion_name} después de {activity_desc}"
                
                recommendations = []
                if corr_data["strength"] >= 0.5:
                    if emotion in ["ANXIETY", "SADNESS", "ANGER", "FEAR", "FRUSTRATION"]:
                        # For negative emotions
                        recommendations.append(f"Considera tomar un breve descanso antes de {activity_desc}")
                        recommendations.append(f"Prueba un ejercicio de respiración antes de {activity_desc}")
                    elif emotion in ["JOY", "CALM", "CONTENTMENT", "HOPE"]:
                        # For positive emotions
                        recommendations.append(f"Continúa incorporando {activity_desc} en tu rutina")
                
                significant[insight_type] = {
                    "description": description,
                    "emotions": [EmotionType(emotion)],
                    "confidence": corr_data["strength"],
                    "data": {emotion: activities},
                    "recommendations": recommendations
                }
        
        return significant
    
    def _get_activity_description(self, activity_type: str) -> str:
        """
        Returns a human-readable description of an activity type.
        
        Args:
            activity_type: The activity type
            
        Returns:
            Human-readable description
        """
        descriptions = {
            "VOICE_JOURNAL": "hacer un diario de voz",
            "EMOTIONAL_CHECK_IN": "hacer un check-in emocional",
            "TOOL_USAGE": "usar una herramienta de bienestar",
            "APP_USAGE": "usar la aplicación"
        }
        
        return descriptions.get(activity_type, activity_type.lower().replace("_", " "))
    
    def calculate_trend_direction(self, intensity_values: List[int], 
                               timestamps: List[datetime]) -> TrendDirection:
        """
        Calculates the direction of an emotional trend.
        
        Args:
            intensity_values: List of emotion intensity values
            timestamps: List of corresponding timestamps
            
        Returns:
            Direction of the emotional trend
        """
        self.logger.info(f"Calculating trend direction from {len(intensity_values)} data points")
        
        if len(intensity_values) < MINIMUM_DATA_POINTS_FOR_TREND:
            return None
        
        # Convert to numpy arrays for calculations
        y = np.array(intensity_values)
        x = np.array([(t - timestamps[0]).total_seconds() / 86400 for t in timestamps])  # Convert to days
        
        try:
            # Calculate slope using linear regression
            if len(x) > 1 and len(y) > 1:
                slope, _, r_value, _, _ = stats.linregress(x, y)
                r_squared = r_value ** 2
                
                # Calculate variance to determine stability
                variance = np.var(y)
                
                # Determine trend direction based on slope and r-squared
                if r_squared < 0.3:  # Weak correlation
                    if variance > 2.0:  # High variance
                        return TrendDirection.FLUCTUATING
                    else:
                        return TrendDirection.STABLE
                else:  # Stronger correlation
                    if slope > 0.1:  # Positive trend
                        return TrendDirection.INCREASING
                    elif slope < -0.1:  # Negative trend
                        return TrendDirection.DECREASING
                    else:  # Flat trend
                        return TrendDirection.STABLE
            else:
                return None
        except Exception as e:
            self.logger.error(f"Error calculating trend direction: {str(e)}")
            return None


class RecommendationEngine:
    """
    Engine for generating personalized tool recommendations.
    
    This class provides methods for recommending appropriate tools
    based on emotional state, user preferences, and historical effectiveness.
    """
    
    def __init__(self):
        """Initialize the recommendation engine"""
        self.logger = logger
        self.logger.info("Recommendation engine initialized")
    
    def generate_recommendations(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                              current_emotion: EmotionType, intensity: int, 
                              limit: int = 5) -> List[Dict]:
        """
        Generates personalized tool recommendations.
        
        Args:
            db: Database session
            user_id: ID of the user
            current_emotion: Current emotional state
            intensity: Intensity of the current emotion (1-10)
            limit: Maximum number of recommendations to return
            
        Returns:
            List of recommended tools with relevance scores
        """
        self.logger.info(f"Generating recommendations for user {user_id} with emotion {current_emotion.value}")
        
        # Get tools that target the current emotion
        relevant_tools = db.query(Tool).filter(
            Tool.is_active == True,
            Tool.target_emotions.contains([current_emotion.value])
        ).all()
        
        if not relevant_tools:
            self.logger.info(f"No relevant tools found for emotion {current_emotion.value}")
            
            # Fall back to all active tools
            relevant_tools = db.query(Tool).filter(
                Tool.is_active == True
            ).limit(10).all()
        
        # Get user's tool usage history
        tool_usage = db.query(ToolUsage).filter(
            ToolUsage.user_id == user_id
        ).all()
        
        # Get user's favorite tools
        favorites = db.query(Tool).join(
            "favorites"
        ).filter(
            Tool.favorites.user_id == user_id
        ).all()
        favorite_tool_ids = [f.id for f in favorites]
        
        # Calculate scores for each tool
        recommendations = []
        
        for tool in relevant_tools:
            # Calculate targeting score
            targeting_score = self.calculate_targeting_score(tool, current_emotion, intensity)
            
            # Calculate effectiveness score
            effectiveness_score = self.calculate_effectiveness_score(db, user_id, tool.id)
            
            # Calculate personalization score
            personalization_score = self.calculate_personalization_score(db, user_id, tool.id)
            
            # Calculate diversity score
            usage_count = len([u for u in tool_usage if u.tool_id == tool.id])
            diversity_score = 1.0 if usage_count == 0 else max(0.1, 1.0 - (usage_count * 0.1))
            
            # Calculate final relevance score with weighted components
            weights = {
                'targeting': 0.4,
                'effectiveness': 0.3,
                'personalization': 0.2,
                'diversity': 0.1
            }
            
            relevance_score = (
                weights['targeting'] * targeting_score +
                weights['effectiveness'] * effectiveness_score +
                weights['personalization'] * personalization_score +
                weights['diversity'] * diversity_score
            )
            
            # Add to recommendations
            recommendations.append({
                'tool_id': str(tool.id),
                'tool_name': tool.name,
                'tool_category': tool.category.value,
                'relevance_score': float(relevance_score),
                'is_favorite': tool.id in favorite_tool_ids,
                'duration': tool.estimated_duration,
                'targeting_score': float(targeting_score),
                'effectiveness_score': float(effectiveness_score),
                'personalization_score': float(personalization_score),
                'diversity_score': float(diversity_score)
            })
        
        # Sort by relevance score and limit the results
        recommendations.sort(key=lambda x: x['relevance_score'], reverse=True)
        top_recommendations = recommendations[:limit]
        
        self.logger.info(f"Generated {len(top_recommendations)} recommendations for user {user_id}")
        return top_recommendations
    
    def calculate_targeting_score(self, tool: Tool, current_emotion: EmotionType, 
                               intensity: int) -> float:
        """
        Calculates how well a tool targets the current emotion.
        
        Args:
            tool: Tool to evaluate
            current_emotion: Current emotional state
            intensity: Intensity of the current emotion (1-10)
            
        Returns:
            Targeting score between 0 and 1
        """
        # Base score if the tool targets this emotion
        base_score = 1.0 if tool.is_targeted_for_emotion(current_emotion) else 0.3
        
        # Factor in emotion intensity and tool difficulty
        if intensity <= 3:  # Low intensity
            if tool.difficulty == ToolDifficulty.BEGINNER:
                difficulty_multiplier = 1.0
            elif tool.difficulty == ToolDifficulty.INTERMEDIATE:
                difficulty_multiplier = 0.8
            else:  # Advanced
                difficulty_multiplier = 0.6
        elif 4 <= intensity <= 7:  # Medium intensity
            if tool.difficulty == ToolDifficulty.BEGINNER:
                difficulty_multiplier = 0.8
            elif tool.difficulty == ToolDifficulty.INTERMEDIATE:
                difficulty_multiplier = 1.0
            else:  # Advanced
                difficulty_multiplier = 0.8
        else:  # High intensity (8-10)
            if tool.difficulty == ToolDifficulty.BEGINNER:
                difficulty_multiplier = 0.7
            elif tool.difficulty == ToolDifficulty.INTERMEDIATE:
                difficulty_multiplier = 0.9
            else:  # Advanced
                difficulty_multiplier = 1.0
        
        # Calculate final targeting score
        targeting_score = base_score * difficulty_multiplier
        
        return min(1.0, max(0.0, targeting_score))
    
    def calculate_effectiveness_score(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                                  tool_id: uuid.UUID) -> float:
        """
        Calculates tool effectiveness based on historical usage.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            
        Returns:
            Effectiveness score between 0 and 1
        """
        # Query tool usage records with pre and post emotional check-ins
        usage_records = db.query(ToolUsage).filter(
            ToolUsage.user_id == user_id,
            ToolUsage.tool_id == tool_id,
            ToolUsage.pre_checkin_id != None,
            ToolUsage.post_checkin_id != None
        ).all()
        
        if not usage_records:
            # No historical data, return neutral score
            return 0.5
        
        # Calculate emotional shifts
        shifts = []
        
        for usage in usage_records:
            emotional_shift = usage.get_emotional_shift()
            if emotional_shift:
                # Simple approach: positive change in intensity is good
                # Could be more sophisticated based on emotion categories
                intensity_change = emotional_shift["intensity_change"]
                
                # If emotion changed from negative to positive category
                pre_emotion_positive = emotional_shift["pre_emotion"].get_emotion_category() == "POSITIVE"
                post_emotion_positive = emotional_shift["post_emotion"].get_emotion_category() == "POSITIVE"
                
                if not pre_emotion_positive and post_emotion_positive:
                    # Big positive shift
                    shifts.append(1.0)
                elif pre_emotion_positive and not post_emotion_positive:
                    # Big negative shift
                    shifts.append(0.0)
                else:
                    # Normalize intensity change to 0-1 range
                    normalized_shift = (intensity_change + 9) / 18  # Range from -9 to +9
                    shifts.append(min(1.0, max(0.0, normalized_shift)))
        
        if not shifts:
            return 0.5
        
        # Calculate average shift
        effectiveness_score = sum(shifts) / len(shifts)
        
        return min(1.0, max(0.0, effectiveness_score))
    
    def calculate_personalization_score(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                                     tool_id: uuid.UUID) -> float:
        """
        Calculates personalization score based on user preferences.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool
            
        Returns:
            Personalization score between 0 and 1
        """
        # Check if tool is in user's favorites
        is_favorite = db.query(ToolFavorite).filter(
            ToolFavorite.user_id == user_id,
            ToolFavorite.tool_id == tool_id
        ).first() is not None
        
        # Count how often user has used the tool
        usage_count = db.query(ToolUsage).filter(
            ToolUsage.user_id == user_id,
            ToolUsage.tool_id == tool_id
        ).count()
        
        # Check completion rate
        completed_count = db.query(ToolUsage).filter(
            ToolUsage.user_id == user_id,
            ToolUsage.tool_id == tool_id,
            ToolUsage.completion_status == "COMPLETED"
        ).count()
        
        completion_rate = completed_count / usage_count if usage_count > 0 else 0.5
        
        # Get tool category
        tool = db.query(Tool).filter(Tool.id == tool_id).first()
        if not tool:
            return 0.5
        
        # Check category preferences based on usage history
        category_usage = db.query(ToolUsage).join(Tool).filter(
            ToolUsage.user_id == user_id,
            Tool.category == tool.category
        ).count()
        
        # Calculate scores for different factors
        favorite_score = 1.0 if is_favorite else 0.0
        usage_score = min(1.0, usage_count / 10)  # Max out at 10 usages
        completion_score = completion_rate
        category_score = min(1.0, category_usage / 20)  # Max out at 20 category usages
        
        # Weighted combination of factors
        weights = {
            'favorite': 0.4,
            'usage': 0.2,
            'completion': 0.2,
            'category': 0.2
        }
        
        personalization_score = (
            weights['favorite'] * favorite_score +
            weights['usage'] * usage_score +
            weights['completion'] * completion_score +
            weights['category'] * category_score
        )
        
        return min(1.0, max(0.0, personalization_score))


class AnalyticsService:
    """
    Service class for analytics operations and data processing.
    
    This class provides methods for analyzing emotional data, generating insights,
    and producing personalized recommendations while respecting user privacy.
    """
    
    def __init__(self):
        """Initialize the analytics service"""
        self.logger = logger
        self.pattern_analyzer = EmotionalPatternAnalyzer()
        self.recommendation_engine = RecommendationEngine()
        self.logger.info("Analytics service initialized")
    
    def analyze_emotional_trends(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                               days: int = DEFAULT_ANALYSIS_PERIOD_DAYS) -> List[EmotionalTrend]:
        """
        Analyzes emotional check-in data to identify trends over time.
        
        Args:
            db: Database session
            user_id: ID of the user to analyze
            days: Number of days to analyze
            
        Returns:
            List of emotional trends identified in the data
        """
        self.logger.info(f"Analyzing emotional trends for user {user_id} over {days} days")
        
        # Get start date by subtracting days from current date
        start_date = get_date_n_days_ago(days)
        
        # Query emotional check-ins for the user within the date range
        checkins = db.query(EmotionalCheckin).filter(
            EmotionalCheckin.user_id == user_id,
            EmotionalCheckin.created_at >= start_date
        ).order_by(EmotionalCheckin.created_at).all()
        
        # Check if there are enough data points for analysis
        if len(checkins) < MINIMUM_DATA_POINTS_FOR_TREND:
            self.logger.info(f"Not enough data points for trend analysis. Found {len(checkins)}, need {MINIMUM_DATA_POINTS_FOR_TREND}")
            return []
        
        # Group check-ins by emotion type
        emotion_groups = defaultdict(list)
        for checkin in checkins:
            emotion_groups[checkin.emotion_type].append(checkin)
        
        trends = []
        
        # For each emotion type, calculate statistics and trend direction
        for emotion_type, emotion_checkins in emotion_groups.items():
            # Skip emotions with too few data points
            if len(emotion_checkins) < MINIMUM_DATA_POINTS_FOR_TREND:
                continue
            
            # Calculate statistics
            intensities = [c.intensity for c in emotion_checkins]
            timestamps = [c.created_at for c in emotion_checkins]
            
            # Calculate trend direction
            trend_direction = self.pattern_analyzer.calculate_trend_direction(intensities, timestamps)
            
            # Create trend object
            trend = EmotionalTrend(
                user_id=user_id,
                period_type=PeriodType.DAY,
                period_value=start_date.strftime("%Y-%m-%d"),
                emotion_type=emotion_type,
                occurrence_count=len(emotion_checkins),
                average_intensity=sum(intensities) / len(intensities),
                min_intensity=min(intensities),
                max_intensity=max(intensities),
                trend_direction=trend_direction
            )
            
            # Add to database
            db.add(trend)
            trends.append(trend)
        
        # Commit the transaction
        db.commit()
        
        self.logger.info(f"Generated {len(trends)} emotional trends for user {user_id}")
        return trends
    
    def generate_emotional_insights(self, db: sqlalchemy.Session, user_id: uuid.UUID) -> List[EmotionalInsight]:
        """
        Generates insights based on emotional trends and patterns.
        
        Args:
            db: Database session
            user_id: ID of the user to analyze
            
        Returns:
            List of insights generated from emotional data
        """
        self.logger.info(f"Generating emotional insights for user {user_id}")
        
        # Get emotional trends for the user
        trends = db.query(EmotionalTrend).filter(
            EmotionalTrend.user_id == user_id
        ).order_by(EmotionalTrend.created_at.desc()).limit(30).all()
        
        # Get emotional check-ins for the user
        checkins = db.query(EmotionalCheckin).filter(
            EmotionalCheckin.user_id == user_id
        ).order_by(EmotionalCheckin.created_at.desc()).limit(100).all()
        
        # Get user activities
        activities = db.query(UserActivity).filter(
            UserActivity.user_id == user_id
        ).order_by(UserActivity.activity_date.desc()).limit(100).all()
        
        # Check if there are enough data points for insight generation
        if len(checkins) < MINIMUM_DATA_POINTS_FOR_INSIGHT:
            self.logger.info(f"Not enough data points for insight generation. Found {len(checkins)}, need {MINIMUM_DATA_POINTS_FOR_INSIGHT}")
            return []
        
        # Analyze patterns in emotional data
        patterns = self.pattern_analyzer.detect_patterns(checkins)
        
        # Identify correlations between emotions and activities
        correlations = self.pattern_analyzer.detect_correlations(checkins, activities)
        
        insights = []
        
        # Generate pattern-based insights
        for pattern_type, pattern_data in patterns.items():
            if pattern_data['confidence'] >= INSIGHT_CONFIDENCE_THRESHOLD:
                insight = EmotionalInsight(
                    user_id=user_id,
                    type=pattern_type,
                    description=pattern_data['description'],
                    related_emotions=",".join([e.value for e in pattern_data['emotions']]),
                    confidence=pattern_data['confidence'],
                    recommended_actions=pattern_data.get('recommendations', None)
                )
                db.add(insight)
                insights.append(insight)
        
        # Generate correlation-based insights
        for correlation_type, correlation_data in correlations.items():
            if correlation_data['confidence'] >= INSIGHT_CONFIDENCE_THRESHOLD:
                insight = EmotionalInsight(
                    user_id=user_id,
                    type=correlation_type,
                    description=correlation_data['description'],
                    related_emotions=",".join([e.value for e in correlation_data['emotions']]),
                    confidence=correlation_data['confidence'],
                    recommended_actions=correlation_data.get('recommendations', None)
                )
                db.add(insight)
                insights.append(insight)
        
        # Commit the transaction
        db.commit()
        
        self.logger.info(f"Generated {len(insights)} emotional insights for user {user_id}")
        return insights
    
    def get_recommended_tools(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                           current_emotion: EmotionType, intensity: int, 
                           limit: int = 5) -> List[Dict]:
        """
        Recommends tools based on user's emotional state and history.
        
        Args:
            db: Database session
            user_id: ID of the user to recommend tools for
            current_emotion: Current emotional state of the user
            intensity: Intensity of the current emotion (1-10)
            limit: Maximum number of recommendations to return
            
        Returns:
            List of recommended tools with relevance scores
        """
        self.logger.info(f"Generating tool recommendations for user {user_id} with emotion {current_emotion}")
        
        return self.recommendation_engine.generate_recommendations(
            db, user_id, current_emotion, intensity, limit
        )
    
    def calculate_tool_effectiveness(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                                  tool_id: uuid.UUID) -> float:
        """
        Calculates the effectiveness of a tool based on emotional shifts.
        
        Args:
            db: Database session
            user_id: ID of the user
            tool_id: ID of the tool to evaluate
            
        Returns:
            Effectiveness score between 0 and 1
        """
        self.logger.info(f"Calculating tool effectiveness for user {user_id}, tool {tool_id}")
        
        return self.recommendation_engine.calculate_effectiveness_score(db, user_id, tool_id)
    
    def generate_usage_statistics(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                               period_type: PeriodType, period_value: str) -> UsageStatistics:
        """
        Generates usage statistics for a user over a specified period.
        
        Args:
            db: Database session
            user_id: ID of the user
            period_type: Type of period (DAY, WEEK, MONTH)
            period_value: Value of the period (e.g., "2023-01-15", "2023-W02")
            
        Returns:
            Usage statistics for the specified period
        """
        self.logger.info(f"Generating usage statistics for user {user_id} for period {period_type.value}:{period_value}")
        
        # Determine date range based on period type and value
        start_date = None
        end_date = None
        
        if period_type == PeriodType.DAY:
            start_date = datetime.strptime(period_value, "%Y-%m-%d").date()
            end_date = start_date
        elif period_type == PeriodType.WEEK:
            # Period value format is "2023-W02"
            year, week = period_value.split("-W")
            # This is a simplified version; in production code, you'd need a more robust solution
            # to convert ISO week to actual dates
            start_date = datetime.strptime(f"{year}-01-01", "%Y-%m-%d").date()
            start_date = start_date + timedelta(days=(int(week)-1)*7)
            end_date = start_date + timedelta(days=6)
        elif period_type == PeriodType.MONTH:
            # Period value format is "2023-01"
            year, month = period_value.split("-")
            start_date = datetime.strptime(f"{year}-{month}-01", "%Y-%m-%d").date()
            # Determine last day of month
            if int(month) == 12:
                end_date = datetime.strptime(f"{int(year)+1}-01-01", "%Y-%m-%d").date() - timedelta(days=1)
            else:
                end_date = datetime.strptime(f"{year}-{int(month)+1:02d}-01", "%Y-%m-%d").date() - timedelta(days=1)
        
        # Query user activities within the date range
        activities = db.query(UserActivity).filter(
            UserActivity.user_id == user_id,
            UserActivity.activity_date >= start_date,
            UserActivity.activity_date <= end_date
        ).all()
        
        # Look for existing statistics or create new one
        stats = db.query(UsageStatistics).filter(
            UsageStatistics.user_id == user_id,
            UsageStatistics.period_type == period_type,
            UsageStatistics.period_value == period_value
        ).first()
        
        if not stats:
            stats = UsageStatistics(
                user_id=user_id,
                period_type=period_type,
                period_value=period_value
            )
            db.add(stats)
        
        # Update statistics from activities
        stats.update_from_activities(activities)
        
        # Commit the transaction
        db.commit()
        
        self.logger.info(f"Generated usage statistics for user {user_id}")
        return stats
    
    def track_user_activity(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                         activity_type: 'ActionType', metadata: Dict = None) -> UserActivity:
        """
        Records a user activity for analytics purposes.
        
        Args:
            db: Database session
            user_id: ID of the user
            activity_type: Type of activity
            metadata: Additional activity metadata
            
        Returns:
            Created user activity record
        """
        self.logger.info(f"Tracking user activity {activity_type.value} for user {user_id}")
        
        # Get current date and time
        now = datetime.utcnow()
        
        # Create new activity record
        activity = UserActivity(
            user_id=user_id,
            activity_type=activity_type,
            activity_date=now,
            time_of_day=UserActivity.get_time_of_day(now),
            day_of_week=UserActivity.get_day_of_week(now),
            metadata=sanitize_log_data(metadata) if metadata else None
        )
        
        # Add to database
        db.add(activity)
        db.commit()
        
        self.logger.info(f"User activity recorded for user {user_id}")
        return activity
    
    def get_emotional_pattern_visualization_data(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                                            days: int = DEFAULT_ANALYSIS_PERIOD_DAYS) -> Dict:
        """
        Prepares emotional data for visualization in the frontend.
        
        Args:
            db: Database session
            user_id: ID of the user
            days: Number of days to include
            
        Returns:
            Visualization-ready data structure
        """
        self.logger.info(f"Preparing emotional pattern visualization for user {user_id} over {days} days")
        
        # Get start date by subtracting days from current date
        start_date = get_date_n_days_ago(days)
        
        # Query emotional check-ins for the user within the date range
        checkins = db.query(EmotionalCheckin).filter(
            EmotionalCheckin.user_id == user_id,
            EmotionalCheckin.created_at >= start_date
        ).order_by(EmotionalCheckin.created_at).all()
        
        if not checkins:
            return {"data": [], "emotions": {}, "period": {"start": start_date.isoformat(), "end": get_current_date().isoformat()}}
        
        # Group data by day and emotion type
        checkins_by_day = group_by_day([c.created_at for c in checkins])
        
        # Prepare emotion metadata
        emotions = {}
        
        # Prepare time series data
        time_series = []
        
        # Process each day
        all_dates = pd.date_range(start=start_date, end=get_current_date())
        
        for day in all_dates:
            day_date = day.date()
            day_data = {"date": day_date.isoformat()}
            
            # Find check-ins for this day
            day_checkins = checkins_by_day.get(day_date, [])
            
            # Group by emotion type
            day_emotions = defaultdict(list)
            for c in checkins:
                if c.created_at.date() == day_date:
                    day_emotions[c.emotion_type].append(c.intensity)
                    
                    # Add emotion metadata if not already added
                    if c.emotion_type.value not in emotions:
                        emotions[c.emotion_type.value] = {
                            "name": c.get_emotion_metadata()["display_name"],
                            "color": c.get_emotion_metadata()["color"],
                            "description": c.get_emotion_metadata()["description"]
                        }
            
            # Calculate average intensity for each emotion
            for emotion_type, intensities in day_emotions.items():
                day_data[emotion_type.value] = sum(intensities) / len(intensities)
            
            time_series.append(day_data)
        
        result = {
            "data": time_series,
            "emotions": emotions,
            "period": {
                "start": start_date.isoformat(),
                "end": get_current_date().isoformat()
            }
        }
        
        self.logger.info(f"Prepared visualization data with {len(time_series)} data points")
        return result
    
    def get_activity_visualization_data(self, db: sqlalchemy.Session, user_id: uuid.UUID, 
                                     days: int = DEFAULT_ANALYSIS_PERIOD_DAYS) -> Dict:
        """
        Prepares activity data for visualization in the frontend.
        
        Args:
            db: Database session
            user_id: ID of the user
            days: Number of days to include
            
        Returns:
            Visualization-ready data structure
        """
        self.logger.info(f"Preparing activity visualization for user {user_id} over {days} days")
        
        # Get start date by subtracting days from current date
        start_date = get_date_n_days_ago(days)
        
        # Query user activities within the date range
        activities = db.query(UserActivity).filter(
            UserActivity.user_id == user_id,
            UserActivity.activity_date >= start_date
        ).order_by(UserActivity.activity_date).all()
        
        if not activities:
            return {"data": [], "activities": {}, "period": {"start": start_date.isoformat(), "end": get_current_date().isoformat()}}
        
        # Group activities by day and activity type
        activities_by_day = defaultdict(lambda: defaultdict(int))
        
        for activity in activities:
            day = activity.activity_date.date()
            activities_by_day[day][activity.activity_type.value] += 1
        
        # Prepare activity metadata
        activity_types = {
            "VOICE_JOURNAL": {"name": "Voice Journal", "color": "#1E90FF"},
            "EMOTIONAL_CHECK_IN": {"name": "Emotional Check-in", "color": "#FF6347"},
            "TOOL_USAGE": {"name": "Tool Usage", "color": "#32CD32"}
        }
        
        # Prepare bar chart data
        bar_chart = []
        
        # Process each day
        all_dates = pd.date_range(start=start_date, end=get_current_date())
        
        for day in all_dates:
            day_date = day.date()
            day_data = {"date": day_date.isoformat()}
            
            # Add activity counts for this day
            for activity_type, count in activities_by_day.get(day_date, {}).items():
                day_data[activity_type] = count
            
            bar_chart.append(day_data)
        
        result = {
            "data": bar_chart,
            "activities": activity_types,
            "period": {
                "start": start_date.isoformat(),
                "end": get_current_date().isoformat()
            }
        }
        
        self.logger.info(f"Prepared activity visualization data with {len(bar_chart)} data points")
        return result
    
    def anonymize_data_for_research(self, db: sqlalchemy.Session, user_ids: List[uuid.UUID]) -> pd.DataFrame:
        """
        Anonymizes user data for research purposes while preserving patterns.
        
        Args:
            db: Database session
            user_ids: List of user IDs to include in the anonymized dataset
            
        Returns:
            Anonymized dataset for research
        """
        self.logger.info(f"Anonymizing data for research from {len(user_ids)} users")
        
        # Query emotional and activity data for specified users
        checkins = db.query(EmotionalCheckin).filter(
            EmotionalCheckin.user_id.in_(user_ids)
        ).all()
        
        activities = db.query(UserActivity).filter(
            UserActivity.user_id.in_(user_ids)
        ).all()
        
        # Create dataframes
        checkins_df = pd.DataFrame([{
            "timestamp": c.created_at,
            "emotion_type": c.emotion_type.value,
            "intensity": c.intensity,
            "context": c.context.value,
            "original_user_id": str(c.user_id)
        } for c in checkins])
        
        activities_df = pd.DataFrame([{
            "timestamp": a.activity_date,
            "activity_type": a.activity_type.value,
            "time_of_day": a.time_of_day,
            "day_of_week": a.day_of_week,
            "original_user_id": str(a.user_id)
        } for a in activities])
        
        if checkins_df.empty or activities_df.empty:
            self.logger.warning("Insufficient data for anonymization")
            return pd.DataFrame()
        
        # Create anonymous user IDs
        user_id_mapping = {str(user_id): f"user_{i}" for i, user_id in enumerate(set(user_ids))}
        
        # Replace original user IDs with anonymous IDs
        checkins_df["user_id"] = checkins_df["original_user_id"].map(user_id_mapping)
        activities_df["user_id"] = activities_df["original_user_id"].map(user_id_mapping)
        
        # Remove original user IDs
        checkins_df = checkins_df.drop("original_user_id", axis=1)
        activities_df = activities_df.drop("original_user_id", axis=1)
        
        # Merge dataframes
        merged_df = pd.merge(
            checkins_df, 
            activities_df, 
            how="outer", 
            on=["user_id", "timestamp"]
        )
        
        # Apply differential privacy techniques
        # Note: For full implementation, would use libraries like diffprivlib or opendp
        # This is a simplified approach
        
        # Add small random noise to intensity (preserving range 1-10)
        if "intensity" in merged_df.columns:
            noise = np.random.normal(0, 0.5, size=len(merged_df))
            merged_df["intensity"] = np.clip(
                merged_df["intensity"] + noise, 
                1, 
                10
            ).round().astype(int)
        
        # Aggregate timestamps to reduce identifiability
        if "timestamp" in merged_df.columns:
            merged_df["date"] = merged_df["timestamp"].dt.date
            merged_df["hour"] = merged_df["timestamp"].dt.hour
            merged_df = merged_df.drop("timestamp", axis=1)
        
        self.logger.info(f"Generated anonymized dataset with {len(merged_df)} records")
        return merged_df
    
    def run_scheduled_analytics(self, db: sqlalchemy.Session) -> Dict:
        """
        Runs scheduled analytics tasks for all users.
        
        Args:
            db: Database session
            
        Returns:
            Summary of analytics processing results
        """
        self.logger.info("Running scheduled analytics tasks")
        
        # Get list of active users
        users = db.query(User).filter(User.account_status == 'active').all()
        
        results = {
            "total_users": len(users),
            "trend_analysis": 0,
            "insight_generation": 0,
            "usage_statistics": 0,
            "errors": 0
        }
        
        for user in users:
            try:
                # Run trend analysis
                trends = self.analyze_emotional_trends(db, user.id)
                if trends:
                    results["trend_analysis"] += 1
                
                # Generate insights
                insights = self.generate_emotional_insights(db, user.id)
                if insights:
                    results["insight_generation"] += 1
                
                # Update usage statistics for current month
                current_month = datetime.utcnow().strftime("%Y-%m")
                stats = self.generate_usage_statistics(
                    db, user.id, PeriodType.MONTH, current_month
                )
                if stats:
                    results["usage_statistics"] += 1
                
            except Exception as e:
                self.logger.error(f"Error processing analytics for user {user.id}: {str(e)}")
                results["errors"] += 1
        
        self.logger.info(f"Scheduled analytics completed: {results}")
        return results


# Singleton instance of the analytics service
analytics_service = AnalyticsService()