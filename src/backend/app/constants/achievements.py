from enum import Enum
from typing import Dict, List, Any

# Default values for achievements
ACHIEVEMENT_POINTS_DEFAULT = 50
ACHIEVEMENT_HIDDEN_DEFAULT = False

class AchievementCategory(Enum):
    """Enumeration of achievement categories for grouping related achievements"""
    MILESTONE = "MILESTONE"
    STREAK = "STREAK"
    JOURNALING = "JOURNALING"
    EMOTIONAL_AWARENESS = "EMOTIONAL_AWARENESS"
    TOOL_USAGE = "TOOL_USAGE"

class AchievementType(Enum):
    """Enumeration of achievement types available in the system"""
    FIRST_STEP = "FIRST_STEP"
    STREAK_3_DAYS = "STREAK_3_DAYS"
    STREAK_7_DAYS = "STREAK_7_DAYS"
    STREAK_14_DAYS = "STREAK_14_DAYS"
    STREAK_30_DAYS = "STREAK_30_DAYS"
    STREAK_60_DAYS = "STREAK_60_DAYS"
    STREAK_90_DAYS = "STREAK_90_DAYS"
    FIRST_JOURNAL = "FIRST_JOURNAL"
    JOURNAL_MASTER = "JOURNAL_MASTER"
    EMOTIONAL_EXPLORER = "EMOTIONAL_EXPLORER"
    EMOTIONAL_INSIGHT = "EMOTIONAL_INSIGHT"
    TOOL_EXPLORER = "TOOL_EXPLORER"
    BREATHING_MASTER = "BREATHING_MASTER"
    MEDITATION_MASTER = "MEDITATION_MASTER"
    SOMATIC_MASTER = "SOMATIC_MASTER"
    JOURNALING_MASTER = "JOURNALING_MASTER"
    GRATITUDE_MASTER = "GRATITUDE_MASTER"
    WELLNESS_JOURNEY = "WELLNESS_JOURNEY"

class CriteriaType(Enum):
    """Enumeration of criteria types for achievement requirements"""
    COUNT = "COUNT"
    STREAK = "STREAK"
    UNIQUE_COUNT = "UNIQUE_COUNT"
    COMPLETION = "COMPLETION"

class ActionType(Enum):
    """Enumeration of action types that can trigger achievements"""
    APP_USAGE = "APP_USAGE"
    VOICE_JOURNAL = "VOICE_JOURNAL"
    EMOTIONAL_CHECK_IN = "EMOTIONAL_CHECK_IN"
    TOOL_USAGE = "TOOL_USAGE"
    EMOTION_TYPES = "EMOTION_TYPES"
    ACTIVE_DAYS = "ACTIVE_DAYS"

# Dictionary mapping achievement types to their metadata
ACHIEVEMENT_METADATA: Dict[AchievementType, Dict[str, Any]] = {
    AchievementType.FIRST_STEP: {
        "category": AchievementCategory.MILESTONE,
        "name_es": "Primer paso",
        "name_en": "First step",
        "description_es": "Completar el primer check-in emocional",
        "description_en": "Complete your first emotional check-in",
        "icon_url": "/assets/images/achievements/first_step.svg",
        "points": 10,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 1,
            "action": ActionType.EMOTIONAL_CHECK_IN
        },
        "metadata": {
            "display_order": 1,
            "tags": ["beginner", "onboarding"]
        }
    },
    AchievementType.STREAK_3_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 3 días",
        "name_en": "3-day streak",
        "description_es": "Usar la aplicación durante 3 días consecutivos",
        "description_en": "Use the app for 3 consecutive days",
        "icon_url": "/assets/images/achievements/streak_3.svg",
        "points": 15,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 3,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 2,
            "next_achievement": AchievementType.STREAK_7_DAYS,
            "tags": ["streak", "consistency"]
        }
    },
    AchievementType.STREAK_7_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 7 días",
        "name_en": "7-day streak",
        "description_es": "Usar la aplicación durante 7 días consecutivos",
        "description_en": "Use the app for 7 consecutive days",
        "icon_url": "/assets/images/achievements/streak_7.svg",
        "points": 25,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 7,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 3,
            "next_achievement": AchievementType.STREAK_14_DAYS,
            "tags": ["streak", "consistency"]
        }
    },
    AchievementType.STREAK_14_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 14 días",
        "name_en": "14-day streak",
        "description_es": "Usar la aplicación durante 14 días consecutivos",
        "description_en": "Use the app for 14 consecutive days",
        "icon_url": "/assets/images/achievements/streak_14.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 14,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 4,
            "next_achievement": AchievementType.STREAK_30_DAYS,
            "tags": ["streak", "consistency"]
        }
    },
    AchievementType.STREAK_30_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 30 días",
        "name_en": "30-day streak",
        "description_es": "Usar la aplicación durante 30 días consecutivos",
        "description_en": "Use the app for 30 consecutive days",
        "icon_url": "/assets/images/achievements/streak_30.svg",
        "points": 100,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 30,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 5,
            "next_achievement": AchievementType.STREAK_60_DAYS,
            "tags": ["streak", "consistency", "dedication"]
        }
    },
    AchievementType.STREAK_60_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 60 días",
        "name_en": "60-day streak",
        "description_es": "Usar la aplicación durante 60 días consecutivos",
        "description_en": "Use the app for 60 consecutive days",
        "icon_url": "/assets/images/achievements/streak_60.svg",
        "points": 200,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 60,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 6,
            "next_achievement": AchievementType.STREAK_90_DAYS,
            "tags": ["streak", "consistency", "dedication"]
        }
    },
    AchievementType.STREAK_90_DAYS: {
        "category": AchievementCategory.STREAK,
        "name_es": "Racha de 90 días",
        "name_en": "90-day streak",
        "description_es": "Usar la aplicación durante 90 días consecutivos",
        "description_en": "Use the app for 90 consecutive days",
        "icon_url": "/assets/images/achievements/streak_90.svg",
        "points": 300,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.STREAK,
            "target": 90,
            "action": ActionType.APP_USAGE
        },
        "metadata": {
            "display_order": 7,
            "tags": ["streak", "consistency", "dedication", "mastery"]
        }
    },
    AchievementType.FIRST_JOURNAL: {
        "category": AchievementCategory.JOURNALING,
        "name_es": "Primera grabación",
        "name_en": "First recording",
        "description_es": "Completar tu primer diario de voz",
        "description_en": "Complete your first voice journal",
        "icon_url": "/assets/images/achievements/first_journal.svg",
        "points": 15,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 1,
            "action": ActionType.VOICE_JOURNAL
        },
        "metadata": {
            "display_order": 8,
            "tags": ["journaling", "beginner"]
        }
    },
    AchievementType.JOURNAL_MASTER: {
        "category": AchievementCategory.JOURNALING,
        "name_es": "Maestro del diario",
        "name_en": "Journal master",
        "description_es": "Completar 25 diarios de voz",
        "description_en": "Complete 25 voice journals",
        "icon_url": "/assets/images/achievements/journal_master.svg",
        "points": 100,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 25,
            "action": ActionType.VOICE_JOURNAL
        },
        "metadata": {
            "display_order": 9,
            "tags": ["journaling", "dedication"]
        }
    },
    AchievementType.EMOTIONAL_EXPLORER: {
        "category": AchievementCategory.EMOTIONAL_AWARENESS,
        "name_es": "Explorador emocional",
        "name_en": "Emotional explorer",
        "description_es": "Registrar 10 emociones diferentes en tus check-ins",
        "description_en": "Record 10 different emotions in your check-ins",
        "icon_url": "/assets/images/achievements/emotional_explorer.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.UNIQUE_COUNT,
            "target": 10,
            "action": ActionType.EMOTION_TYPES
        },
        "metadata": {
            "display_order": 10,
            "tags": ["emotions", "awareness", "exploration"]
        }
    },
    AchievementType.EMOTIONAL_INSIGHT: {
        "category": AchievementCategory.EMOTIONAL_AWARENESS,
        "name_es": "Conocimiento emocional",
        "name_en": "Emotional insight",
        "description_es": "Completar 30 check-ins emocionales",
        "description_en": "Complete 30 emotional check-ins",
        "icon_url": "/assets/images/achievements/emotional_insight.svg",
        "points": 75,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 30,
            "action": ActionType.EMOTIONAL_CHECK_IN
        },
        "metadata": {
            "display_order": 11,
            "tags": ["emotions", "awareness", "dedication"]
        }
    },
    AchievementType.TOOL_EXPLORER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Explorador de herramientas",
        "name_en": "Tool explorer",
        "description_es": "Probar 5 herramientas diferentes",
        "description_en": "Try 5 different tools",
        "icon_url": "/assets/images/achievements/tool_explorer.svg",
        "points": 25,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.UNIQUE_COUNT,
            "target": 5,
            "action": ActionType.TOOL_USAGE
        },
        "metadata": {
            "display_order": 12,
            "tags": ["tools", "exploration"]
        }
    },
    AchievementType.BREATHING_MASTER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Maestro de la respiración",
        "name_en": "Breathing master",
        "description_es": "Completar 10 ejercicios de respiración",
        "description_en": "Complete 10 breathing exercises",
        "icon_url": "/assets/images/achievements/breathing_master.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 10,
            "action": ActionType.TOOL_USAGE,
            "conditions": {
                "category": "BREATHING"
            }
        },
        "metadata": {
            "display_order": 13,
            "tags": ["breathing", "mastery"]
        }
    },
    AchievementType.MEDITATION_MASTER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Maestro de la meditación",
        "name_en": "Meditation master",
        "description_es": "Completar 10 meditaciones",
        "description_en": "Complete 10 meditations",
        "icon_url": "/assets/images/achievements/meditation_master.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 10,
            "action": ActionType.TOOL_USAGE,
            "conditions": {
                "category": "MEDITATION"
            }
        },
        "metadata": {
            "display_order": 14,
            "tags": ["meditation", "mastery"]
        }
    },
    AchievementType.SOMATIC_MASTER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Maestro somático",
        "name_en": "Somatic master",
        "description_es": "Completar 10 ejercicios somáticos",
        "description_en": "Complete 10 somatic exercises",
        "icon_url": "/assets/images/achievements/somatic_master.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 10,
            "action": ActionType.TOOL_USAGE,
            "conditions": {
                "category": "SOMATIC"
            }
        },
        "metadata": {
            "display_order": 15,
            "tags": ["somatic", "mastery"]
        }
    },
    AchievementType.JOURNALING_MASTER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Maestro del journaling",
        "name_en": "Journaling master",
        "description_es": "Completar 10 ejercicios de journaling",
        "description_en": "Complete 10 journaling exercises",
        "icon_url": "/assets/images/achievements/journaling_master.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 10,
            "action": ActionType.TOOL_USAGE,
            "conditions": {
                "category": "JOURNALING"
            }
        },
        "metadata": {
            "display_order": 16,
            "tags": ["journaling", "mastery"]
        }
    },
    AchievementType.GRATITUDE_MASTER: {
        "category": AchievementCategory.TOOL_USAGE,
        "name_es": "Maestro de la gratitud",
        "name_en": "Gratitude master",
        "description_es": "Completar 10 ejercicios de gratitud",
        "description_en": "Complete 10 gratitude exercises",
        "icon_url": "/assets/images/achievements/gratitude_master.svg",
        "points": 50,
        "is_hidden": False,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 10,
            "action": ActionType.TOOL_USAGE,
            "conditions": {
                "category": "GRATITUDE"
            }
        },
        "metadata": {
            "display_order": 17,
            "tags": ["gratitude", "mastery"]
        }
    },
    AchievementType.WELLNESS_JOURNEY: {
        "category": AchievementCategory.MILESTONE,
        "name_es": "Viaje de bienestar",
        "name_en": "Wellness journey",
        "description_es": "Usar la aplicación durante 100 días en total",
        "description_en": "Use the app for a total of 100 days",
        "icon_url": "/assets/images/achievements/wellness_journey.svg",
        "points": 200,
        "is_hidden": True,
        "criteria": {
            "type": CriteriaType.COUNT,
            "target": 100,
            "action": ActionType.ACTIVE_DAYS
        },
        "metadata": {
            "display_order": 18,
            "tags": ["milestone", "dedication", "journey"]
        }
    }
}