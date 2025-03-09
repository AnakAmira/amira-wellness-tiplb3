"""
tools.py

This module defines tool-related constants for the Amira Wellness application,
including tool categories, content types, difficulty levels, and metadata. It provides 
standardized tool definitions used throughout the application for the tool library feature.
"""

from enum import Enum  # standard library
from .emotions import EmotionType  # Internal import


class ToolCategory(Enum):
    """Enumeration of tool categories supported in the application."""
    BREATHING = "BREATHING"
    MEDITATION = "MEDITATION"
    SOMATIC = "SOMATIC"
    JOURNALING = "JOURNALING"
    GRATITUDE = "GRATITUDE"


class ToolContentType(Enum):
    """Enumeration of tool content types supported in the application."""
    TEXT = "TEXT"
    AUDIO = "AUDIO"
    VIDEO = "VIDEO"
    INTERACTIVE = "INTERACTIVE"
    GUIDED_EXERCISE = "GUIDED_EXERCISE"


class ToolDifficulty(Enum):
    """Enumeration of tool difficulty levels."""
    BEGINNER = "BEGINNER"
    INTERMEDIATE = "INTERMEDIATE"
    ADVANCED = "ADVANCED"


# Tool duration constants
TOOL_DURATION_MIN = 1
TOOL_DURATION_MAX = 60
TOOL_DURATION_DEFAULT = 5

# Tool category metadata
TOOL_CATEGORY_METADATA = {
    ToolCategory.BREATHING: {
        'display_name': 'Respiración',
        'display_name_en': 'Breathing',
        'description': 'Ejercicios de respiración para reducir la ansiedad y promover la calma',
        'description_en': 'Breathing exercises to reduce anxiety and promote calm',
        'icon': 'breathing.png',
        'color': '#A7D2E8'
    },
    ToolCategory.MEDITATION: {
        'display_name': 'Meditación',
        'display_name_en': 'Meditation',
        'description': 'Prácticas de meditación para cultivar la atención plena',
        'description_en': 'Meditation practices to cultivate mindfulness',
        'icon': 'meditation.png',
        'color': '#C8A2C8'
    },
    ToolCategory.SOMATIC: {
        'display_name': 'Ejercicios Somáticos',
        'display_name_en': 'Somatic Exercises',
        'description': 'Ejercicios físicos para liberar tensión y conectar con el cuerpo',
        'description_en': 'Physical exercises to release tension and connect with the body',
        'icon': 'somatic.png',
        'color': '#FFDAB9'
    },
    ToolCategory.JOURNALING: {
        'display_name': 'Journaling',
        'display_name_en': 'Journaling',
        'description': 'Prompts de escritura para la reflexión y expresión emocional',
        'description_en': 'Writing prompts for reflection and emotional expression',
        'icon': 'journaling.png',
        'color': '#B0E0E6'
    },
    ToolCategory.GRATITUDE: {
        'display_name': 'Gratitud',
        'display_name_en': 'Gratitude',
        'description': 'Prácticas para cultivar la gratitud y apreciación',
        'description_en': 'Practices to cultivate gratitude and appreciation',
        'icon': 'gratitude.png',
        'color': '#FFD700'
    }
}

# Tool content type metadata
TOOL_CONTENT_TYPE_METADATA = {
    ToolContentType.TEXT: {
        'display_name': 'Texto',
        'display_name_en': 'Text',
        'icon': 'text.png'
    },
    ToolContentType.AUDIO: {
        'display_name': 'Audio',
        'display_name_en': 'Audio',
        'icon': 'audio.png'
    },
    ToolContentType.VIDEO: {
        'display_name': 'Video',
        'display_name_en': 'Video',
        'icon': 'video.png'
    },
    ToolContentType.INTERACTIVE: {
        'display_name': 'Interactivo',
        'display_name_en': 'Interactive',
        'icon': 'interactive.png'
    },
    ToolContentType.GUIDED_EXERCISE: {
        'display_name': 'Ejercicio Guiado',
        'display_name_en': 'Guided Exercise',
        'icon': 'guided.png'
    }
}

# Tool difficulty metadata
TOOL_DIFFICULTY_METADATA = {
    ToolDifficulty.BEGINNER: {
        'display_name': 'Principiante',
        'display_name_en': 'Beginner',
        'icon': 'beginner.png'
    },
    ToolDifficulty.INTERMEDIATE: {
        'display_name': 'Intermedio',
        'display_name_en': 'Intermediate',
        'icon': 'intermediate.png'
    },
    ToolDifficulty.ADVANCED: {
        'display_name': 'Avanzado',
        'display_name_en': 'Advanced',
        'icon': 'advanced.png'
    }
}

# Mapping between emotions and recommended tool categories
TOOL_EMOTION_MAPPING = {
    EmotionType.ANXIETY: [ToolCategory.BREATHING, ToolCategory.MEDITATION, ToolCategory.SOMATIC],
    EmotionType.STRESS: [ToolCategory.BREATHING, ToolCategory.MEDITATION, ToolCategory.SOMATIC],
    EmotionType.OVERWHELM: [ToolCategory.BREATHING, ToolCategory.SOMATIC],
    EmotionType.ANGER: [ToolCategory.BREATHING, ToolCategory.SOMATIC],
    EmotionType.FEAR: [ToolCategory.BREATHING, ToolCategory.MEDITATION],
    EmotionType.SADNESS: [ToolCategory.JOURNALING, ToolCategory.GRATITUDE],
    EmotionType.FRUSTRATION: [ToolCategory.SOMATIC, ToolCategory.JOURNALING],
    EmotionType.LONELINESS: [ToolCategory.JOURNALING, ToolCategory.GRATITUDE],
    EmotionType.JOY: [ToolCategory.GRATITUDE],
    EmotionType.GRATITUDE: [ToolCategory.GRATITUDE],
    EmotionType.CONTENTMENT: [ToolCategory.MEDITATION, ToolCategory.GRATITUDE],
    EmotionType.CALM: [ToolCategory.MEDITATION],
    EmotionType.HOPE: [ToolCategory.JOURNALING, ToolCategory.GRATITUDE],
    EmotionType.TRUST: [ToolCategory.MEDITATION, ToolCategory.GRATITUDE],
    EmotionType.ANTICIPATION: [ToolCategory.JOURNALING],
    EmotionType.SURPRISE: [ToolCategory.JOURNALING],
    EmotionType.DISGUST: [ToolCategory.SOMATIC, ToolCategory.JOURNALING]
}

# Weights for different factors in the tool recommendation algorithm
TOOL_RECOMMENDATION_WEIGHTS = {
    'emotional_relevance': 0.4,
    'user_preferences': 0.3,
    'contextual_factors': 0.2,
    'diversity': 0.1
}


def get_tool_category_display_name(category: ToolCategory, use_english: bool = False) -> str:
    """
    Returns the localized display name for a tool category.
    
    Args:
        category (ToolCategory): The tool category to get the display name for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized display name for the tool category
        
    Raises:
        ValueError: If the category is not valid
    """
    if category not in TOOL_CATEGORY_METADATA:
        raise ValueError(f"Invalid tool category: {category}")
    
    if use_english:
        return TOOL_CATEGORY_METADATA[category]['display_name_en']
    return TOOL_CATEGORY_METADATA[category]['display_name']


def get_tool_category_description(category: ToolCategory, use_english: bool = False) -> str:
    """
    Returns the localized description for a tool category.
    
    Args:
        category (ToolCategory): The tool category to get the description for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized description for the tool category
        
    Raises:
        ValueError: If the category is not valid
    """
    if category not in TOOL_CATEGORY_METADATA:
        raise ValueError(f"Invalid tool category: {category}")
    
    if use_english:
        return TOOL_CATEGORY_METADATA[category]['description_en']
    return TOOL_CATEGORY_METADATA[category]['description']


def get_tool_content_type_display_name(content_type: ToolContentType, use_english: bool = False) -> str:
    """
    Returns the localized display name for a tool content type.
    
    Args:
        content_type (ToolContentType): The tool content type to get the display name for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized display name for the tool content type
        
    Raises:
        ValueError: If the content type is not valid
    """
    if content_type not in TOOL_CONTENT_TYPE_METADATA:
        raise ValueError(f"Invalid tool content type: {content_type}")
    
    if use_english:
        return TOOL_CONTENT_TYPE_METADATA[content_type]['display_name_en']
    return TOOL_CONTENT_TYPE_METADATA[content_type]['display_name']


def get_tool_difficulty_display_name(difficulty: ToolDifficulty, use_english: bool = False) -> str:
    """
    Returns the localized display name for a tool difficulty level.
    
    Args:
        difficulty (ToolDifficulty): The tool difficulty level to get the display name for
        use_english (bool, optional): Whether to use English instead of Spanish. Defaults to False.
    
    Returns:
        str: Localized display name for the tool difficulty level
        
    Raises:
        ValueError: If the difficulty is not valid
    """
    if difficulty not in TOOL_DIFFICULTY_METADATA:
        raise ValueError(f"Invalid tool difficulty: {difficulty}")
    
    if use_english:
        return TOOL_DIFFICULTY_METADATA[difficulty]['display_name_en']
    return TOOL_DIFFICULTY_METADATA[difficulty]['display_name']


def get_tool_category_color(category: ToolCategory) -> str:
    """
    Returns the color code associated with a tool category.
    
    Args:
        category (ToolCategory): The tool category to get the color for
    
    Returns:
        str: Hex color code for the tool category
        
    Raises:
        ValueError: If the category is not valid
    """
    if category not in TOOL_CATEGORY_METADATA:
        raise ValueError(f"Invalid tool category: {category}")
    
    return TOOL_CATEGORY_METADATA[category]['color']


def get_tool_categories_for_emotion(emotion: EmotionType) -> list:
    """
    Returns recommended tool categories for a specific emotion.
    
    Args:
        emotion (EmotionType): The emotion to get recommended tool categories for
    
    Returns:
        List[ToolCategory]: List of tool categories recommended for the emotion
    """
    if emotion not in TOOL_EMOTION_MAPPING:
        return []
    
    return TOOL_EMOTION_MAPPING[emotion]


def validate_tool_duration(duration: int) -> bool:
    """
    Validates that a tool duration value is within the allowed range.
    
    Args:
        duration (int): The duration value to validate
    
    Returns:
        bool: True if duration is valid, False otherwise
    """
    return TOOL_DURATION_MIN <= duration <= TOOL_DURATION_MAX