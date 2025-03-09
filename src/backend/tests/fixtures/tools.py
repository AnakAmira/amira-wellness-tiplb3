"""
Test fixture module that provides tool-related fixtures for unit and integration tests in the Amira Wellness application.
Creates various tool test objects with different categories, content types, and difficulty levels to support
comprehensive testing of the tool library functionality.
"""

import pytest  # pytest v7.x
import datetime  # standard library
import uuid  # standard library

from ...app.constants.tools import (
    ToolCategory,
    ToolContentType,
    ToolDifficulty
)
from ...app.constants.emotions import EmotionType
from ...app.models.tool import Tool, ToolFavorite, ToolUsage
from .database import test_db
from .users import regular_user
from .emotions import joy_emotion, calm_emotion

# Sample tool data for creating fixtures
TOOL_DATA = [
    {
        'name': 'Respiración 4-7-8',
        'description': 'Técnica de respiración para reducir la ansiedad',
        'category': ToolCategory.BREATHING,
        'content_type': ToolContentType.GUIDED_EXERCISE,
        'content': {
            'steps': [
                {'title': 'Preparación', 'description': 'Siéntate cómodamente con la espalda recta', 'duration': 30},
                {'title': 'Inhala', 'description': 'Inhala por la nariz durante 4 segundos', 'duration': 4},
                {'title': 'Mantén', 'description': 'Mantén la respiración durante 7 segundos', 'duration': 7},
                {'title': 'Exhala', 'description': 'Exhala por la boca durante 8 segundos', 'duration': 8},
                {'title': 'Repite', 'description': 'Repite el ciclo 5 veces', 'duration': 95}
            ]
        },
        'estimated_duration': 5,
        'difficulty': ToolDifficulty.BEGINNER,
        'target_emotions': [EmotionType.ANXIETY, EmotionType.ANGER],
        'icon_url': 'breathing.png',
        'is_active': True,
        'is_premium': False
    },
    {
        'name': 'Meditación de atención plena',
        'description': 'Meditación guiada para cultivar la atención plena',
        'category': ToolCategory.MEDITATION,
        'content_type': ToolContentType.AUDIO,
        'content': {
            'audio_url': 'meditations/mindfulness.mp3',
            'transcript': 'Transcripción de la meditación guiada...'
        },
        'estimated_duration': 10,
        'difficulty': ToolDifficulty.INTERMEDIATE,
        'target_emotions': [EmotionType.ANXIETY, EmotionType.SADNESS],
        'icon_url': 'meditation.png',
        'is_active': True,
        'is_premium': False
    },
    {
        'name': 'Ejercicio de enraizamiento',
        'description': 'Ejercicio somático para conectar con el cuerpo',
        'category': ToolCategory.SOMATIC,
        'content_type': ToolContentType.GUIDED_EXERCISE,
        'content': {
            'steps': [
                {'title': 'Posición', 'description': 'Ponte de pie con los pies separados al ancho de los hombros', 'duration': 30},
                {'title': 'Respiración', 'description': 'Respira profundamente mientras sientes tus pies en el suelo', 'duration': 60},
                {'title': 'Movimiento', 'description': 'Balancea suavemente tu peso de un pie al otro', 'duration': 90},
                {'title': 'Cierre', 'description': 'Respira profundamente y nota cómo te sientes', 'duration': 30}
            ]
        },
        'estimated_duration': 4,
        'difficulty': ToolDifficulty.BEGINNER,
        'target_emotions': [EmotionType.ANXIETY, EmotionType.ANGER],
        'icon_url': 'somatic.png',
        'is_active': True,
        'is_premium': False
    },
    {
        'name': 'Prompts de gratitud',
        'description': 'Preguntas para reflexionar sobre la gratitud',
        'category': ToolCategory.GRATITUDE,
        'content_type': ToolContentType.TEXT,
        'content': {
            'text': '1. ¿Qué tres cosas agradeces hoy?\n2. ¿Quién te ha ayudado recientemente y cómo?\n3. ¿Qué es algo que das por sentado pero por lo que estás realmente agradecido?'
        },
        'estimated_duration': 5,
        'difficulty': ToolDifficulty.BEGINNER,
        'target_emotions': [EmotionType.SADNESS, EmotionType.GRATITUDE],
        'icon_url': 'gratitude.png',
        'is_active': True,
        'is_premium': False
    },
    {
        'name': 'Visualización guiada',
        'description': 'Visualización para cultivar la calma y la paz interior',
        'category': ToolCategory.MEDITATION,
        'content_type': ToolContentType.VIDEO,
        'content': {
            'video_url': 'meditations/visualization.mp4',
            'transcript': 'Transcripción de la visualización guiada...'
        },
        'estimated_duration': 15,
        'difficulty': ToolDifficulty.INTERMEDIATE,
        'target_emotions': [EmotionType.ANXIETY, EmotionType.SADNESS],
        'icon_url': 'visualization.png',
        'is_active': True,
        'is_premium': True
    },
    {
        'name': 'Prompts de journaling emocional',
        'description': 'Preguntas para explorar tus emociones a través de la escritura',
        'category': ToolCategory.JOURNALING,
        'content_type': ToolContentType.TEXT,
        'content': {
            'text': '1. ¿Qué emoción estás sintiendo con más fuerza ahora mismo?\n2. ¿Dónde sientes esta emoción en tu cuerpo?\n3. ¿Qué te está diciendo esta emoción?\n4. ¿Qué necesitas en este momento?'
        },
        'estimated_duration': 10,
        'difficulty': ToolDifficulty.BEGINNER,
        'target_emotions': [EmotionType.ANXIETY, EmotionType.SADNESS, EmotionType.ANGER],
        'icon_url': 'journaling.png',
        'is_active': True,
        'is_premium': False
    }
]

# Possible tool usage status values
TOOL_USAGE_STATUSES = ['COMPLETED', 'PARTIAL', 'ABANDONED']

@pytest.fixture
def breathing_tool(test_db):
    """
    Creates a breathing exercise tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Breathing exercise tool instance
    """
    tool_data = TOOL_DATA[0]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def meditation_tool(test_db):
    """
    Creates a meditation tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Meditation tool instance
    """
    tool_data = TOOL_DATA[1]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def somatic_tool(test_db):
    """
    Creates a somatic exercise tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Somatic exercise tool instance
    """
    tool_data = TOOL_DATA[2]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def gratitude_tool(test_db):
    """
    Creates a gratitude tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Gratitude tool instance
    """
    tool_data = TOOL_DATA[3]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def journaling_tool(test_db):
    """
    Creates a journaling tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Journaling tool instance
    """
    tool_data = TOOL_DATA[5]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def premium_tool(test_db):
    """
    Creates a premium tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Premium tool instance
    """
    tool_data = TOOL_DATA[4]
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def beginner_tool(test_db):
    """
    Creates a beginner difficulty tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Beginner difficulty tool instance
    """
    tool_data = TOOL_DATA[0]  # Breathing tool is a beginner tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=ToolDifficulty.BEGINNER,
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def intermediate_tool(test_db):
    """
    Creates an intermediate difficulty tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Intermediate difficulty tool instance
    """
    tool_data = TOOL_DATA[1]  # Meditation tool is an intermediate tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=tool_data['content_type'],
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=ToolDifficulty.INTERMEDIATE,
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def text_tool(test_db):
    """
    Creates a text content type tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Text content type tool instance
    """
    tool_data = TOOL_DATA[3]  # Gratitude tool is a text tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=ToolContentType.TEXT,
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def audio_tool(test_db):
    """
    Creates an audio content type tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Audio content type tool instance
    """
    tool_data = TOOL_DATA[1]  # Meditation tool is an audio tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=ToolContentType.AUDIO,
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def video_tool(test_db):
    """
    Creates a video content type tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Video content type tool instance
    """
    tool_data = TOOL_DATA[4]  # Visualization tool is a video tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=ToolContentType.VIDEO,
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def guided_exercise_tool(test_db):
    """
    Creates a guided exercise content type tool for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Tool: Guided exercise content type tool instance
    """
    tool_data = TOOL_DATA[0]  # Breathing tool is a guided exercise tool
    tool = Tool(
        name=tool_data['name'],
        description=tool_data['description'],
        category=tool_data['category'],
        content_type=ToolContentType.GUIDED_EXERCISE,
        content=tool_data['content'],
        estimated_duration=tool_data['estimated_duration'],
        difficulty=tool_data['difficulty'],
        target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
        icon_url=tool_data['icon_url'],
        is_active=tool_data['is_active'],
        is_premium=tool_data['is_premium']
    )
    test_db.add(tool)
    test_db.commit()
    test_db.refresh(tool)
    return tool

@pytest.fixture
def tool_favorite(test_db, regular_user, breathing_tool):
    """
    Creates a tool favorite for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        breathing_tool: Breathing tool fixture
        
    Returns:
        ToolFavorite: Tool favorite instance
    """
    favorite = ToolFavorite(
        user_id=regular_user.id,
        tool_id=breathing_tool.id
    )
    test_db.add(favorite)
    test_db.commit()
    test_db.refresh(favorite)
    return favorite

@pytest.fixture
def tool_usage_completed(test_db, regular_user, breathing_tool):
    """
    Creates a completed tool usage for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        breathing_tool: Breathing tool fixture
        
    Returns:
        ToolUsage: Completed tool usage instance
    """
    usage = ToolUsage(
        user_id=regular_user.id,
        tool_id=breathing_tool.id,
        duration_seconds=300,  # 5 minutes
        completed_at=datetime.datetime.utcnow(),
        completion_status='COMPLETED'
    )
    test_db.add(usage)
    test_db.commit()
    test_db.refresh(usage)
    return usage

@pytest.fixture
def tool_usage_partial(test_db, regular_user, meditation_tool):
    """
    Creates a partially completed tool usage for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        meditation_tool: Meditation tool fixture
        
    Returns:
        ToolUsage: Partially completed tool usage instance
    """
    usage = ToolUsage(
        user_id=regular_user.id,
        tool_id=meditation_tool.id,
        duration_seconds=240,  # 4 minutes (of 10 total)
        completed_at=datetime.datetime.utcnow(),
        completion_status='PARTIAL'
    )
    test_db.add(usage)
    test_db.commit()
    test_db.refresh(usage)
    return usage

@pytest.fixture
def tool_usage_abandoned(test_db, regular_user, somatic_tool):
    """
    Creates an abandoned tool usage for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        somatic_tool: Somatic tool fixture
        
    Returns:
        ToolUsage: Abandoned tool usage instance
    """
    usage = ToolUsage(
        user_id=regular_user.id,
        tool_id=somatic_tool.id,
        duration_seconds=45,  # Less than 1 minute
        completed_at=datetime.datetime.utcnow(),
        completion_status='ABANDONED'
    )
    test_db.add(usage)
    test_db.commit()
    test_db.refresh(usage)
    return usage

@pytest.fixture
def tool_usage_with_emotions(test_db, regular_user, meditation_tool, joy_emotion, calm_emotion):
    """
    Creates a tool usage with pre/post emotions for testing emotional shifts.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        meditation_tool: Meditation tool fixture
        joy_emotion: Joy emotion check-in fixture
        calm_emotion: Calm emotion check-in fixture
        
    Returns:
        ToolUsage: Tool usage with pre/post emotions
    """
    usage = ToolUsage(
        user_id=regular_user.id,
        tool_id=meditation_tool.id,
        duration_seconds=600,  # 10 minutes
        completed_at=datetime.datetime.utcnow(),
        completion_status='COMPLETED',
        pre_checkin_id=joy_emotion.id,
        post_checkin_id=calm_emotion.id
    )
    test_db.add(usage)
    test_db.commit()
    test_db.refresh(usage)
    return usage

@pytest.fixture
def multiple_tools(test_db):
    """
    Creates multiple tools for testing filtering and recommendations.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        list[Tool]: List of tool instances
    """
    tools = []
    
    # Create a tool instance for each tool in TOOL_DATA
    for tool_data in TOOL_DATA:
        tool = Tool(
            name=tool_data['name'],
            description=tool_data['description'],
            category=tool_data['category'],
            content_type=tool_data['content_type'],
            content=tool_data['content'],
            estimated_duration=tool_data['estimated_duration'],
            difficulty=tool_data['difficulty'],
            target_emotions=[emotion.value for emotion in tool_data['target_emotions']],
            icon_url=tool_data['icon_url'],
            is_active=tool_data['is_active'],
            is_premium=tool_data['is_premium']
        )
        test_db.add(tool)
        tools.append(tool)
    
    test_db.commit()
    
    # Refresh all tools to get their IDs
    for tool in tools:
        test_db.refresh(tool)
    
    return tools