"""
emotions.py

This module defines emotion-related constants for the Amira Wellness application,
including emotion types, categories, intensity ranges, and metadata. It provides 
standardized emotion definitions used throughout the application for emotional 
check-ins, analysis, and visualization.
"""

from enum import Enum  # standard library


class EmotionType(Enum):
    """Enumeration of emotion types supported in the application."""
    JOY = "JOY"
    SADNESS = "SADNESS"
    ANGER = "ANGER"
    FEAR = "FEAR"
    DISGUST = "DISGUST"
    SURPRISE = "SURPRISE"
    TRUST = "TRUST"
    ANTICIPATION = "ANTICIPATION"
    GRATITUDE = "GRATITUDE"
    CONTENTMENT = "CONTENTMENT"
    ANXIETY = "ANXIETY"
    FRUSTRATION = "FRUSTRATION"
    OVERWHELM = "OVERWHELM"
    CALM = "CALM"
    HOPE = "HOPE"
    LONELINESS = "LONELINESS"


class EmotionCategory(Enum):
    """Enumeration of emotion categories for grouping and analysis."""
    POSITIVE = "POSITIVE"
    NEGATIVE = "NEGATIVE"
    NEUTRAL = "NEUTRAL"


class InsightType(Enum):
    """Enumeration of insight types for emotional analysis."""
    PATTERN = "PATTERN"
    TRIGGER = "TRIGGER"
    IMPROVEMENT = "IMPROVEMENT"
    CORRELATION = "CORRELATION"
    RECOMMENDATION = "RECOMMENDATION"


class TrendDirection(Enum):
    """Enumeration of trend directions for emotional analysis."""
    INCREASING = "INCREASING"
    DECREASING = "DECREASING"
    STABLE = "STABLE"
    FLUCTUATING = "FLUCTUATING"


class PeriodType(Enum):
    """Enumeration of period types for emotional trend analysis."""
    DAY = "DAY"
    WEEK = "WEEK"
    MONTH = "MONTH"


class EmotionContext(Enum):
    """Enumeration of contexts for emotional check-ins."""
    PRE_JOURNALING = "PRE_JOURNALING"
    POST_JOURNALING = "POST_JOURNALING"
    STANDALONE = "STANDALONE"
    TOOL_USAGE = "TOOL_USAGE"
    DAILY_CHECK_IN = "DAILY_CHECK_IN"


# Emotion intensity constants
EMOTION_INTENSITY_MIN = 1
EMOTION_INTENSITY_MAX = 10
EMOTION_INTENSITY_DEFAULT = 5

# Emotion metadata dictionary
EMOTION_METADATA = {
    EmotionType.JOY: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Alegría',
        'display_name_en': 'Joy',
        'description': 'Sentimiento de felicidad y placer',
        'description_en': 'Feeling of happiness and pleasure',
        'color': '#FFD700',
        'icon': 'joy.png'
    },
    EmotionType.SADNESS: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Tristeza',
        'display_name_en': 'Sadness',
        'description': 'Sentimiento de pena o melancolía',
        'description_en': 'Feeling of sorrow or melancholy',
        'color': '#4682B4',
        'icon': 'sadness.png'
    },
    EmotionType.ANGER: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Enojo',
        'display_name_en': 'Anger',
        'description': 'Sentimiento de irritación o furia',
        'description_en': 'Feeling of irritation or rage',
        'color': '#FF4500',
        'icon': 'anger.png'
    },
    EmotionType.FEAR: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Miedo',
        'display_name_en': 'Fear',
        'description': 'Sentimiento de alarma o preocupación',
        'description_en': 'Feeling of alarm or worry',
        'color': '#800080',
        'icon': 'fear.png'
    },
    EmotionType.DISGUST: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Asco',
        'display_name_en': 'Disgust',
        'description': 'Sentimiento de repulsión',
        'description_en': 'Feeling of repulsion',
        'color': '#006400',
        'icon': 'disgust.png'
    },
    EmotionType.SURPRISE: {
        'category': EmotionCategory.NEUTRAL,
        'display_name': 'Sorpresa',
        'display_name_en': 'Surprise',
        'description': 'Sentimiento de asombro o impresión',
        'description_en': 'Feeling of astonishment or shock',
        'color': '#FFA500',
        'icon': 'surprise.png'
    },
    EmotionType.TRUST: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Confianza',
        'display_name_en': 'Trust',
        'description': 'Sentimiento de seguridad y fe',
        'description_en': 'Feeling of security and faith',
        'color': '#4169E1',
        'icon': 'trust.png'
    },
    EmotionType.ANTICIPATION: {
        'category': EmotionCategory.NEUTRAL,
        'display_name': 'Anticipación',
        'display_name_en': 'Anticipation',
        'description': 'Sentimiento de expectativa',
        'description_en': 'Feeling of expectation',
        'color': '#FF8C00',
        'icon': 'anticipation.png'
    },
    EmotionType.GRATITUDE: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Gratitud',
        'display_name_en': 'Gratitude',
        'description': 'Sentimiento de aprecio y agradecimiento',
        'description_en': 'Feeling of appreciation and thankfulness',
        'color': '#9370DB',
        'icon': 'gratitude.png'
    },
    EmotionType.CONTENTMENT: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Satisfacción',
        'display_name_en': 'Contentment',
        'description': 'Sentimiento de paz y satisfacción',
        'description_en': 'Feeling of peace and satisfaction',
        'color': '#20B2AA',
        'icon': 'contentment.png'
    },
    EmotionType.ANXIETY: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Ansiedad',
        'display_name_en': 'Anxiety',
        'description': 'Sentimiento de nerviosismo o preocupación',
        'description_en': 'Feeling of nervousness or worry',
        'color': '#8B0000',
        'icon': 'anxiety.png'
    },
    EmotionType.FRUSTRATION: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Frustración',
        'display_name_en': 'Frustration',
        'description': 'Sentimiento de decepción o impotencia',
        'description_en': 'Feeling of disappointment or helplessness',
        'color': '#B22222',
        'icon': 'frustration.png'
    },
    EmotionType.OVERWHELM: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Agobio',
        'display_name_en': 'Overwhelm',
        'description': 'Sentimiento de estar sobrecargado',
        'description_en': 'Feeling of being overloaded',
        'color': '#4B0082',
        'icon': 'overwhelm.png'
    },
    EmotionType.CALM: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Calma',
        'display_name_en': 'Calm',
        'description': 'Sentimiento de tranquilidad y serenidad',
        'description_en': 'Feeling of tranquility and serenity',
        'color': '#5F9EA0',
        'icon': 'calm.png'
    },
    EmotionType.HOPE: {
        'category': EmotionCategory.POSITIVE,
        'display_name': 'Esperanza',
        'display_name_en': 'Hope',
        'description': 'Sentimiento de optimismo y expectativa positiva',
        'description_en': 'Feeling of optimism and positive expectation',
        'color': '#00BFFF',
        'icon': 'hope.png'
    },
    EmotionType.LONELINESS: {
        'category': EmotionCategory.NEGATIVE,
        'display_name': 'Soledad',
        'display_name_en': 'Loneliness',
        'description': 'Sentimiento de aislamiento o desconexión',
        'description_en': 'Feeling of isolation or disconnection',
        'color': '#708090',
        'icon': 'loneliness.png'
    }
}

# Lists of valid values
EMOTION_CONTEXTS = [
    EmotionContext.PRE_JOURNALING,
    EmotionContext.POST_JOURNALING,
    EmotionContext.STANDALONE,
    EmotionContext.TOOL_USAGE,
    EmotionContext.DAILY_CHECK_IN
]

TREND_DIRECTIONS = [
    TrendDirection.INCREASING,
    TrendDirection.DECREASING,
    TrendDirection.STABLE,
    TrendDirection.FLUCTUATING
]

PERIOD_TYPES = [
    PeriodType.DAY,
    PeriodType.WEEK,
    PeriodType.MONTH
]

INSIGHT_TYPES = [
    InsightType.PATTERN,
    InsightType.TRIGGER,
    InsightType.IMPROVEMENT,
    InsightType.CORRELATION,
    InsightType.RECOMMENDATION
]


def get_emotion_display_name(emotion_type: EmotionType, use_english: bool = False) -> str:
    """
    Returns the localized display name for an emotion type.
    
    Args:
        emotion_type (EmotionType): The emotion type to get the display name for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized display name for the emotion
        
    Raises:
        ValueError: If the emotion type is not valid
    """
    if emotion_type not in EMOTION_METADATA:
        raise ValueError(f"Invalid emotion type: {emotion_type}")
    
    if use_english:
        return EMOTION_METADATA[emotion_type]['display_name_en']
    return EMOTION_METADATA[emotion_type]['display_name']


def get_emotion_description(emotion_type: EmotionType, use_english: bool = False) -> str:
    """
    Returns the localized description for an emotion type.
    
    Args:
        emotion_type (EmotionType): The emotion type to get the description for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized description for the emotion
        
    Raises:
        ValueError: If the emotion type is not valid
    """
    if emotion_type not in EMOTION_METADATA:
        raise ValueError(f"Invalid emotion type: {emotion_type}")
    
    if use_english:
        return EMOTION_METADATA[emotion_type]['description_en']
    return EMOTION_METADATA[emotion_type]['description']


def get_emotion_category(emotion_type: EmotionType) -> EmotionCategory:
    """
    Returns the category for an emotion type.
    
    Args:
        emotion_type (EmotionType): The emotion type to get the category for
    
    Returns:
        EmotionCategory: Category of the emotion (POSITIVE, NEGATIVE, NEUTRAL)
        
    Raises:
        ValueError: If the emotion type is not valid
    """
    if emotion_type not in EMOTION_METADATA:
        raise ValueError(f"Invalid emotion type: {emotion_type}")
    
    return EMOTION_METADATA[emotion_type]['category']


def get_emotions_by_category(category: EmotionCategory) -> list:
    """
    Returns all emotion types in a specific category.
    
    Args:
        category (EmotionCategory): The category to filter emotions by
    
    Returns:
        list: List of EmotionType in the specified category
    """
    matching_emotions = []
    for emotion_type, metadata in EMOTION_METADATA.items():
        if metadata['category'] == category:
            matching_emotions.append(emotion_type)
    
    return matching_emotions


def validate_emotion_intensity(intensity: int) -> bool:
    """
    Validates that an emotion intensity value is within the allowed range.
    
    Args:
        intensity (int): The intensity value to validate
    
    Returns:
        bool: True if intensity is valid, False otherwise
    """
    return EMOTION_INTENSITY_MIN <= intensity <= EMOTION_INTENSITY_MAX


def get_emotion_color(emotion_type: EmotionType) -> str:
    """
    Returns the color code associated with an emotion type.
    
    Args:
        emotion_type (EmotionType): The emotion type to get the color for
    
    Returns:
        str: Hex color code for the emotion
        
    Raises:
        ValueError: If the emotion type is not valid
    """
    if emotion_type not in EMOTION_METADATA:
        raise ValueError(f"Invalid emotion type: {emotion_type}")
    
    return EMOTION_METADATA[emotion_type]['color']