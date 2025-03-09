#!/usr/bin/env python3
"""
A utility script for generating test data for the Amira Wellness application.
Creates realistic test data for users, voice journals, emotional check-ins, tools,
achievements, and streaks to support development and testing environments.
"""

import argparse
import json
import os
import sys
import random
import datetime
from datetime import date, timedelta
import uuid
from faker import Faker  # version: 14.0.0
from tqdm import tqdm  # version: 4.64.0
import bcrypt  # version: 4.0.0
import sqlalchemy  # version: 2.0+

# Import models from the application
from app.models.user import User
from app.models.journal import Journal
from app.models.emotion import EmotionalCheckin, EmotionalTrend
from app.models.tool import Tool, ToolFavorite, ToolUsage
from app.models.achievement import Achievement
from app.models.streak import Streak

# Import constants
from app.constants.emotions import EmotionType, EmotionContext, PeriodType, TrendDirection
from app.constants.tools import ToolCategory, ToolContentType, ToolDifficulty
from app.constants.achievements import AchievementType, AchievementCategory

# Import database session
from app.db.session import get_db, Base, engine

# Default configuration values
DEFAULT_NUM_USERS = 50
DEFAULT_NUM_JOURNALS_PER_USER = 10
DEFAULT_NUM_CHECKINS_PER_USER = 30
DEFAULT_NUM_TOOL_USAGES_PER_USER = 20
DEFAULT_PASSWORD = "password123"

# Emotion distribution for more realistic data generation
EMOTION_DISTRIBUTION = {
    'JOY': 0.15,
    'SADNESS': 0.1,
    'ANGER': 0.08,
    'FEAR': 0.07,
    'DISGUST': 0.05,
    'SURPRISE': 0.05,
    'TRUST': 0.08,
    'ANTICIPATION': 0.07,
    'GRATITUDE': 0.08,
    'CONTENTMENT': 0.07,
    'ANXIETY': 0.1,
    'FRUSTRATION': 0.05,
    'OVERWHELM': 0.05,
    'CALM': 0.1,
    'HOPE': 0.05,
    'LONELINESS': 0.05
}

# Path to tool templates directory
TOOL_TEMPLATES_DIR = '../data/tool_templates/'

def setup_argparse():
    """Sets up command line argument parsing for the script."""
    parser = argparse.ArgumentParser(
        description="Generate test data for Amira Wellness application"
    )
    
    parser.add_argument(
        "-u", "--users",
        type=int,
        default=DEFAULT_NUM_USERS,
        help=f"Number of test users to create (default: {DEFAULT_NUM_USERS})"
    )
    
    parser.add_argument(
        "-j", "--journals",
        type=int,
        default=DEFAULT_NUM_JOURNALS_PER_USER,
        help=f"Number of journals per user (default: {DEFAULT_NUM_JOURNALS_PER_USER})"
    )
    
    parser.add_argument(
        "-c", "--checkins",
        type=int,
        default=DEFAULT_NUM_CHECKINS_PER_USER,
        help=f"Number of emotional check-ins per user (default: {DEFAULT_NUM_CHECKINS_PER_USER})"
    )
    
    parser.add_argument(
        "-t", "--tool-usages",
        type=int,
        default=DEFAULT_NUM_TOOL_USAGES_PER_USER,
        help=f"Number of tool usages per user (default: {DEFAULT_NUM_TOOL_USAGES_PER_USER})"
    )
    
    parser.add_argument(
        "--db",
        type=str,
        help="Database connection string (overrides environment variable)"
    )
    
    parser.add_argument(
        "--clear",
        action="store_true",
        help="Clear existing data before generating new data"
    )
    
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output with progress bars"
    )
    
    return parser.parse_args()

def create_test_users(db_session, num_users, default_password, verbose=False):
    """
    Creates test user accounts with realistic data.
    
    Args:
        db_session: SQLAlchemy database session
        num_users: Number of users to create
        default_password: Default password for test users
        verbose: Whether to show progress bar
        
    Returns:
        List of created User objects
    """
    # Initialize Faker with Spanish locale for realistic Spanish names and emails
    fake = Faker(['es'])
    users = []
    
    # Create progress bar if verbose
    iterator = tqdm(range(num_users), desc="Creating users") if verbose else range(num_users)
    
    # Hash the default password
    password_hash = bcrypt.hashpw(default_password.encode(), bcrypt.gensalt()).decode()
    
    for _ in iterator:
        # Generate a realistic Spanish name
        first_name = fake.first_name()
        last_name = fake.last_name()
        
        # Generate email with realistic Spanish domains
        email_domains = ['gmail.com', 'hotmail.com', 'yahoo.es', 'outlook.com', 'protonmail.com']
        email = f"{first_name.lower()}.{last_name.lower()}@{random.choice(email_domains)}"
        
        # Create user
        user = User()
        user.email = email
        user.set_password(password_hash)
        user.email_verified = random.choice([True, True, False])  # 2/3 chance of being verified
        user.account_status = 'active'
        
        # Set random subscription tier (mostly free, some premium)
        user.subscription_tier = random.choices(['free', 'premium'], weights=[0.9, 0.1])[0]
        
        # Set Spanish as default language
        user.language_preference = 'es'
        
        users.append(user)
        db_session.add(user)
    
    # Commit users to database
    db_session.commit()
    
    return users

def create_test_journals(db_session, users, journals_per_user, verbose=False):
    """
    Creates test voice journal entries for users.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        journals_per_user: Number of journals to create per user
        verbose: Whether to show progress bar
        
    Returns:
        List of created Journal objects
    """
    journals = []
    fake = Faker(['es'])
    
    # Create progress bar if verbose
    total_journals = len(users) * journals_per_user
    iterator = tqdm(range(total_journals), desc="Creating journals") if verbose else range(total_journals)
    
    # Journal title templates in Spanish
    journal_titles = [
        "Mi día de hoy",
        "Reflexiones sobre {topic}",
        "Pensamientos sobre mi {emotion}",
        "Notas personales: {date}",
        "Lo que siento ahora",
        "Reflexión diaria",
        "Momentos importantes",
        "Mi viaje emocional",
        "Procesando mis emociones",
        "Diario de gratitud"
    ]
    
    # Common topics in Spanish
    topics = [
        "trabajo", "familia", "amigos", "salud", "relaciones", 
        "futuro", "pasado", "metas", "éxitos", "desafíos"
    ]
    
    # Emotions in Spanish
    emotions = [
        "alegría", "tristeza", "frustración", "esperanza", 
        "ansiedad", "calma", "gratitud", "confusión"
    ]
    
    count = 0
    for user in users:
        # Generate journals for each user
        for _ in range(journals_per_user):
            # Create journal with random properties
            journal = Journal()
            journal.user_id = user.id
            
            # Generate realistic title
            title_template = random.choice(journal_titles)
            if "{topic}" in title_template:
                title = title_template.format(topic=random.choice(topics))
            elif "{emotion}" in title_template:
                title = title_template.format(emotion=random.choice(emotions))
            elif "{date}" in title_template:
                # Random date in the past 90 days
                past_date = datetime.datetime.now() - datetime.timedelta(days=random.randint(1, 90))
                formatted_date = past_date.strftime("%d de %B")
                title = title_template.format(date=formatted_date)
            else:
                title = title_template
                
            journal.title = title
            
            # Set random duration between 60 seconds and 10 minutes
            journal.duration_seconds = random.randint(60, 600)
            
            # Generate fake storage path and S3 key
            journal.storage_path = f"tmp/journals/{user.id}/{uuid.uuid4()}.aac"
            journal.s3_key = f"journals/{user.id}/{uuid.uuid4()}.aac"
            
            # Generate random encryption IV and tag
            journal.encryption_iv = os.urandom(16).hex()
            journal.encryption_tag = os.urandom(16).hex()
            
            # Set audio format and file size
            journal.audio_format = "AAC"
            journal.file_size_bytes = random.randint(500000, 2000000)  # 500KB - 2MB
            
            # Set status flags
            journal.is_favorite = random.random() < 0.2  # 20% chance of being favorited
            journal.is_uploaded = random.random() < 0.95  # 95% chance of being uploaded
            journal.is_deleted = False  # No deleted journals in test data
            
            # Set created_at to a random time in the past 90 days
            journal.created_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 90),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )
            
            journals.append(journal)
            db_session.add(journal)
            
            # Update progress bar
            if verbose:
                iterator.update(1)
            count += 1
    
    # Commit journals to database
    db_session.commit()
    
    return journals

def create_test_emotional_checkins(db_session, users, journals, checkins_per_user, verbose=False):
    """
    Creates test emotional check-ins for users.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        journals: List of Journal objects
        checkins_per_user: Number of emotional check-ins per user
        verbose: Whether to show progress bar
        
    Returns:
        List of created EmotionalCheckin objects
    """
    checkins = []
    
    # Create progress bar if verbose
    total_checkins = len(users) * checkins_per_user
    iterator = tqdm(range(total_checkins), desc="Creating emotional check-ins") if verbose else range(total_checkins)
    
    # Group journals by user for easier access
    user_journals = {}
    for journal in journals:
        if journal.user_id not in user_journals:
            user_journals[journal.user_id] = []
        user_journals[journal.user_id].append(journal)
    
    count = 0
    for user in users:
        # Generate emotional check-ins for each user
        for _ in range(checkins_per_user):
            # Create emotional check-in with random properties
            checkin = EmotionalCheckin()
            checkin.user_id = user.id
            
            # Select random context
            context = random.choices(
                [
                    EmotionContext.PRE_JOURNALING,
                    EmotionContext.POST_JOURNALING,
                    EmotionContext.STANDALONE,
                    EmotionContext.TOOL_USAGE,
                    EmotionContext.DAILY_CHECK_IN
                ],
                weights=[0.2, 0.2, 0.3, 0.2, 0.1]
            )[0]
            
            checkin.context = context
            
            # Link to journal if applicable
            if context in [EmotionContext.PRE_JOURNALING, EmotionContext.POST_JOURNALING]:
                # Only link if the user has journals
                if user.id in user_journals and user_journals[user.id]:
                    journal = random.choice(user_journals[user.id])
                    checkin.related_journal_id = journal.id
            
            # Select random emotion based on distribution
            checkin.emotion_type = random.choices(
                list(EmotionType),
                weights=[EMOTION_DISTRIBUTION[e.name] for e in EmotionType]
            )[0]
            
            # Set random intensity between 1 and 10
            checkin.intensity = random.randint(1, 10)
            
            # Add optional notes 30% of the time
            if random.random() < 0.3:
                notes_templates = [
                    "Me siento así por {reason}",
                    "Esto se debe a {reason}",
                    "Creo que {reason} me está afectando",
                    "Hoy {reason} y eso influye en mi estado",
                    "Reflexionando sobre {reason}"
                ]
                
                reasons = [
                    "mi trabajo", "mi familia", "mis amigos", "mi salud", 
                    "mis relaciones", "acontecimientos recientes", 
                    "mis pensamientos", "mis preocupaciones", "mi futuro",
                    "lo que pasó hoy", "mis logros", "mis desafíos"
                ]
                
                template = random.choice(notes_templates)
                checkin.notes = template.format(reason=random.choice(reasons))
            
            # Set created_at to a random time in the past 90 days
            checkin.created_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 90),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )
            
            # If linked to a journal, set date close to journal date
            if hasattr(checkin, 'related_journal_id') and checkin.related_journal_id:
                journal_date = None
                for j in journals:
                    if j.id == checkin.related_journal_id:
                        journal_date = j.created_at
                        break
                        
                if journal_date:
                    # Pre-journaling is before journal (0-10 minutes)
                    if context == EmotionContext.PRE_JOURNALING:
                        checkin.created_at = journal_date - datetime.timedelta(
                            minutes=random.randint(0, 10)
                        )
                    # Post-journaling is after journal (0-10 minutes)
                    elif context == EmotionContext.POST_JOURNALING:
                        checkin.created_at = journal_date + datetime.timedelta(
                            minutes=random.randint(0, 10)
                        )
            
            checkins.append(checkin)
            db_session.add(checkin)
            
            # Update progress bar
            if verbose:
                iterator.update(1)
            count += 1
    
    # Commit emotional check-ins to database
    db_session.commit()
    
    return checkins

def create_test_emotional_trends(db_session, users, checkins, verbose=False):
    """
    Creates test emotional trend data based on check-ins.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        checkins: List of EmotionalCheckin objects
        verbose: Whether to show progress bar
        
    Returns:
        List of created EmotionalTrend objects
    """
    trends = []
    
    # Create progress bar if verbose
    iterator = tqdm(users, desc="Creating emotional trends") if verbose else users
    
    # Group check-ins by user
    user_checkins = {}
    for checkin in checkins:
        if checkin.user_id not in user_checkins:
            user_checkins[checkin.user_id] = []
        user_checkins[checkin.user_id].append(checkin)
    
    for user in iterator:
        # Skip users with no check-ins
        if user.id not in user_checkins or not user_checkins[user.id]:
            continue
            
        user_emotion_checkins = user_checkins[user.id]
        
        # Group check-ins by date for daily trends
        daily_checkins = {}
        for checkin in user_emotion_checkins:
            date_key = checkin.created_at.date().isoformat()
            if date_key not in daily_checkins:
                daily_checkins[date_key] = []
            daily_checkins[date_key].append(checkin)
            
        # Create daily trends
        for date_str, day_checkins in daily_checkins.items():
            # Group by emotion type
            emotion_groups = {}
            for checkin in day_checkins:
                emotion_type = checkin.emotion_type
                if emotion_type not in emotion_groups:
                    emotion_groups[emotion_type] = []
                emotion_groups[emotion_type].append(checkin)
                
            # Create trend for each emotion that appears in the day
            for emotion_type, emotion_checkins in emotion_groups.items():
                # Calculate statistics
                intensities = [c.intensity for c in emotion_checkins]
                avg_intensity = sum(intensities) / len(intensities)
                min_intensity = min(intensities)
                max_intensity = max(intensities)
                
                # Sort by time to determine trend direction
                sorted_checkins = sorted(emotion_checkins, key=lambda c: c.created_at)
                
                trend_direction = None
                if len(sorted_checkins) >= 2:
                    first = sorted_checkins[0].intensity
                    last = sorted_checkins[-1].intensity
                    
                    # Simple trend calculation
                    if last - first > 1:
                        trend_direction = TrendDirection.INCREASING
                    elif first - last > 1:
                        trend_direction = TrendDirection.DECREASING
                    else:
                        trend_direction = TrendDirection.STABLE
                        
                    # Check for fluctuation
                    changes = [sorted_checkins[i].intensity - sorted_checkins[i-1].intensity 
                               for i in range(1, len(sorted_checkins))]
                    if any(c > 2 for c in changes) and any(c < -2 for c in changes):
                        trend_direction = TrendDirection.FLUCTUATING
                
                # Create trend record
                trend = EmotionalTrend()
                trend.user_id = user.id
                trend.period_type = PeriodType.DAY
                trend.period_value = date_str
                trend.emotion_type = emotion_type
                trend.occurrence_count = len(emotion_checkins)
                trend.average_intensity = avg_intensity
                trend.min_intensity = min_intensity
                trend.max_intensity = max_intensity
                trend.trend_direction = trend_direction
                
                # Set created_at to end of the day
                date_obj = datetime.date.fromisoformat(date_str)
                trend.created_at = datetime.datetime.combine(
                    date_obj, 
                    datetime.time(23, 59, 59)
                )
                
                trends.append(trend)
                db_session.add(trend)
        
        # Also create weekly and monthly trends
        weekly_checkins = {}
        monthly_checkins = {}
        
        for checkin in user_emotion_checkins:
            # Format: "2023-W01" for weeks, "2023-01" for months
            week_key = f"{checkin.created_at.year}-W{checkin.created_at.isocalendar()[1]:02d}"
            month_key = f"{checkin.created_at.year}-{checkin.created_at.month:02d}"
            
            if week_key not in weekly_checkins:
                weekly_checkins[week_key] = []
            weekly_checkins[week_key].append(checkin)
            
            if month_key not in monthly_checkins:
                monthly_checkins[month_key] = []
            monthly_checkins[month_key].append(checkin)
        
        # Create weekly trends
        for week_str, week_checkins in weekly_checkins.items():
            # Group by emotion type
            emotion_groups = {}
            for checkin in week_checkins:
                emotion_type = checkin.emotion_type
                if emotion_type not in emotion_groups:
                    emotion_groups[emotion_type] = []
                emotion_groups[emotion_type].append(checkin)
                
            # Create trend for each emotion that appears in the week
            for emotion_type, emotion_checkins in emotion_groups.items():
                # Calculate statistics
                intensities = [c.intensity for c in emotion_checkins]
                avg_intensity = sum(intensities) / len(intensities)
                min_intensity = min(intensities)
                max_intensity = max(intensities)
                
                # Calculate trend direction
                sorted_checkins = sorted(emotion_checkins, key=lambda c: c.created_at)
                
                trend_direction = None
                if len(sorted_checkins) >= 2:
                    first = sorted_checkins[0].intensity
                    last = sorted_checkins[-1].intensity
                    
                    # Simple trend calculation
                    if last - first > 1:
                        trend_direction = TrendDirection.INCREASING
                    elif first - last > 1:
                        trend_direction = TrendDirection.DECREASING
                    else:
                        trend_direction = TrendDirection.STABLE
                        
                    # Check for fluctuation
                    changes = [sorted_checkins[i].intensity - sorted_checkins[i-1].intensity 
                               for i in range(1, len(sorted_checkins))]
                    if any(c > 2 for c in changes) and any(c < -2 for c in changes):
                        trend_direction = TrendDirection.FLUCTUATING
                
                # Create trend record
                trend = EmotionalTrend()
                trend.user_id = user.id
                trend.period_type = PeriodType.WEEK
                trend.period_value = week_str
                trend.emotion_type = emotion_type
                trend.occurrence_count = len(emotion_checkins)
                trend.average_intensity = avg_intensity
                trend.min_intensity = min_intensity
                trend.max_intensity = max_intensity
                trend.trend_direction = trend_direction
                
                # Set created_at to the last check-in date
                trend.created_at = max(c.created_at for c in emotion_checkins)
                
                trends.append(trend)
                db_session.add(trend)
        
        # Create monthly trends
        for month_str, month_checkins in monthly_checkins.items():
            # Group by emotion type
            emotion_groups = {}
            for checkin in month_checkins:
                emotion_type = checkin.emotion_type
                if emotion_type not in emotion_groups:
                    emotion_groups[emotion_type] = []
                emotion_groups[emotion_type].append(checkin)
                
            # Create trend for each emotion that appears in the month
            for emotion_type, emotion_checkins in emotion_groups.items():
                # Calculate statistics
                intensities = [c.intensity for c in emotion_checkins]
                avg_intensity = sum(intensities) / len(intensities)
                min_intensity = min(intensities)
                max_intensity = max(intensities)
                
                # Calculate trend direction
                sorted_checkins = sorted(emotion_checkins, key=lambda c: c.created_at)
                
                trend_direction = None
                if len(sorted_checkins) >= 2:
                    first = sorted_checkins[0].intensity
                    last = sorted_checkins[-1].intensity
                    
                    # Simple trend calculation
                    if last - first > 1:
                        trend_direction = TrendDirection.INCREASING
                    elif first - last > 1:
                        trend_direction = TrendDirection.DECREASING
                    else:
                        trend_direction = TrendDirection.STABLE
                        
                    # Check for fluctuation
                    changes = [sorted_checkins[i].intensity - sorted_checkins[i-1].intensity 
                               for i in range(1, len(sorted_checkins))]
                    if any(c > 2 for c in changes) and any(c < -2 for c in changes):
                        trend_direction = TrendDirection.FLUCTUATING
                
                # Create trend record
                trend = EmotionalTrend()
                trend.user_id = user.id
                trend.period_type = PeriodType.MONTH
                trend.period_value = month_str
                trend.emotion_type = emotion_type
                trend.occurrence_count = len(emotion_checkins)
                trend.average_intensity = avg_intensity
                trend.min_intensity = min_intensity
                trend.max_intensity = max_intensity
                trend.trend_direction = trend_direction
                
                # Set created_at to the last check-in date
                trend.created_at = max(c.created_at for c in emotion_checkins)
                
                trends.append(trend)
                db_session.add(trend)
    
    # Commit trends to database
    db_session.commit()
    
    return trends

def load_tool_templates(templates_dir):
    """
    Loads tool templates from JSON files.
    
    Args:
        templates_dir: Directory containing tool templates
        
    Returns:
        List of tool template dictionaries
    """
    templates = []
    
    # Get list of JSON files in templates directory
    if not os.path.exists(templates_dir):
        return []
        
    json_files = [f for f in os.listdir(templates_dir) if f.endswith('.json')]
    
    for filename in json_files:
        file_path = os.path.join(templates_dir, filename)
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                template = json.load(f)
                
                # Validate required fields
                required_fields = ['name', 'description', 'category', 'content_type', 'content']
                if all(field in template for field in required_fields):
                    templates.append(template)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error loading template {filename}: {e}")
    
    return templates

def create_test_tools(db_session, templates_dir, verbose=False):
    """
    Creates test tools based on templates.
    
    Args:
        db_session: SQLAlchemy database session
        templates_dir: Directory containing tool templates
        verbose: Whether to show progress bar
        
    Returns:
        List of created Tool objects
    """
    # Load tool templates
    templates = load_tool_templates(templates_dir)
    
    # If no templates found, create some default tools
    if not templates:
        print("No tool templates found. Creating default tools.")
        templates = [
            {
                "name": "Respiración 4-7-8",
                "description": "Una técnica de respiración para reducir la ansiedad y promover la calma.",
                "category": "BREATHING",
                "content_type": "GUIDED_EXERCISE",
                "estimated_duration": 5,
                "difficulty": "BEGINNER",
                "target_emotions": ["ANXIETY", "STRESS", "OVERWHELM"],
                "content": {
                    "instructions": "1. Inhala por la nariz durante 4 segundos.\n2. Mantén la respiración durante 7 segundos.\n3. Exhala lentamente por la boca durante 8 segundos.\n4. Repite el ciclo 5 veces.",
                    "steps": [
                        {"order": 1, "title": "Preparación", "description": "Siéntate en una posición cómoda con la espalda recta.", "duration": 30},
                        {"order": 2, "title": "Inhala", "description": "Inhala por la nariz durante 4 segundos.", "duration": 4},
                        {"order": 3, "title": "Mantén", "description": "Mantén la respiración durante 7 segundos.", "duration": 7},
                        {"order": 4, "title": "Exhala", "description": "Exhala lentamente por la boca durante 8 segundos.", "duration": 8},
                        {"order": 5, "title": "Repite", "description": "Repite el ciclo 4 veces más.", "duration": 4*19}
                    ]
                }
            },
            {
                "name": "Meditación para la ansiedad",
                "description": "Una meditación guiada para aliviar la ansiedad y encontrar calma.",
                "category": "MEDITATION",
                "content_type": "AUDIO",
                "estimated_duration": 10,
                "difficulty": "BEGINNER",
                "target_emotions": ["ANXIETY", "FEAR", "OVERWHELM"],
                "content": {
                    "instructions": "Encuentra un lugar tranquilo, siéntate o recuéstate cómodamente, y sigue la meditación guiada.",
                    "audio_url": "meditations/anxiety_relief.mp3"
                }
            },
            {
                "name": "Ejercicio de enraizamiento",
                "description": "Una técnica para reconectar con el presente cuando te sientes abrumado o ansioso.",
                "category": "SOMATIC",
                "content_type": "GUIDED_EXERCISE",
                "estimated_duration": 3,
                "difficulty": "BEGINNER",
                "target_emotions": ["ANXIETY", "FEAR", "OVERWHELM"],
                "content": {
                    "instructions": "Este ejercicio utiliza tus sentidos para reconectar con el momento presente.",
                    "steps": [
                        {"order": 1, "title": "5 cosas que puedes ver", "description": "Nombra 5 cosas que puedes ver a tu alrededor.", "duration": 30},
                        {"order": 2, "title": "4 cosas que puedes tocar", "description": "Nombra 4 cosas que puedes tocar o sentir.", "duration": 30},
                        {"order": 3, "title": "3 cosas que puedes oír", "description": "Nombra 3 cosas que puedes oír.", "duration": 30},
                        {"order": 4, "title": "2 cosas que puedes oler", "description": "Nombra 2 cosas que puedes oler.", "duration": 30},
                        {"order": 5, "title": "1 cosa que puedes saborear", "description": "Nombra 1 cosa que puedes saborear.", "duration": 30}
                    ]
                }
            },
            {
                "name": "Diario de gratitud",
                "description": "Práctica para cultivar la gratitud y cambiar el enfoque hacia lo positivo.",
                "category": "GRATITUDE",
                "content_type": "TEXT",
                "estimated_duration": 5,
                "difficulty": "BEGINNER",
                "target_emotions": ["SADNESS", "ANXIETY", "FRUSTRATION"],
                "content": {
                    "instructions": "Reflexiona y escribe sobre estas preguntas.",
                    "prompts": [
                        "¿Por qué tres cosas te sientes agradecido/a hoy?",
                        "¿Qué persona te ha impactado positivamente? ¿Por qué?",
                        "¿Qué oportunidad o experiencia te ha enriquecido últimamente?"
                    ]
                }
            },
            {
                "name": "Escaneo corporal",
                "description": "Una práctica para reconectar con tu cuerpo y liberar tensiones.",
                "category": "SOMATIC",
                "content_type": "GUIDED_EXERCISE",
                "estimated_duration": 8,
                "difficulty": "BEGINNER",
                "target_emotions": ["ANXIETY", "STRESS", "OVERWHELM"],
                "content": {
                    "instructions": "Recuéstate en una posición cómoda y sigue las instrucciones para escanear tu cuerpo.",
                    "steps": [
                        {"order": 1, "title": "Preparación", "description": "Recuéstate cómodamente y cierra los ojos. Toma varias respiraciones profundas.", "duration": 60},
                        {"order": 2, "title": "Pies y piernas", "description": "Lleva tu atención a los pies. Observa las sensaciones presentes. Luego sube a las piernas.", "duration": 120},
                        {"order": 3, "title": "Torso", "description": "Lleva la atención a tu abdomen, pecho y espalda. Observa las sensaciones.", "duration": 120},
                        {"order": 4, "title": "Brazos", "description": "Escanea tus brazos desde los hombros hasta las manos.", "duration": 60},
                        {"order": 5, "title": "Cuello y cabeza", "description": "Finaliza con el cuello, rostro y cabeza.", "duration": 60},
                        {"order": 6, "title": "Cuerpo completo", "description": "Observa tu cuerpo completo y las sensaciones presentes.", "duration": 60}
                    ]
                }
            }
        ]
    
    tools = []
    
    # Create progress bar if verbose
    iterator = tqdm(templates, desc="Creating tools") if verbose else templates
    
    for template in iterator:
        # Create tool from template
        tool = Tool()
        tool.name = template["name"]
        tool.description = template["description"]
        
        # Convert string to enum for category
        tool.category = getattr(ToolCategory, template["category"]) if isinstance(template["category"], str) else template["category"]
        
        # Convert string to enum for content_type
        tool.content_type = getattr(ToolContentType, template["content_type"]) if isinstance(template["content_type"], str) else template["content_type"]
        
        # Set content JSON
        tool.content = template["content"]
        
        # Set estimated duration
        tool.estimated_duration = template.get("estimated_duration", 5)
        
        # Convert string to enum for difficulty
        difficulty = template.get("difficulty", "BEGINNER")
        tool.difficulty = getattr(ToolDifficulty, difficulty) if isinstance(difficulty, str) else difficulty
        
        # Set target emotions
        if "target_emotions" in template:
            # Convert emotion names to enum values if strings
            target_emotions = []
            for emotion in template["target_emotions"]:
                if isinstance(emotion, str):
                    try:
                        target_emotions.append(getattr(EmotionType, emotion).value)
                    except AttributeError:
                        # Skip invalid emotions
                        pass
                else:
                    target_emotions.append(emotion)
            
            tool.target_emotions = target_emotions
        
        # Set other fields
        tool.icon_url = template.get("icon_url", None)
        tool.is_active = True
        tool.is_premium = template.get("is_premium", False)
        
        tools.append(tool)
        db_session.add(tool)
    
    # Commit tools to database
    db_session.commit()
    
    return tools

def create_test_tool_favorites(db_session, users, tools, verbose=False):
    """
    Creates test tool favorites for users.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        tools: List of Tool objects
        verbose: Whether to show progress bar
        
    Returns:
        List of created ToolFavorite objects
    """
    favorites = []
    
    # Create progress bar if verbose
    iterator = tqdm(users, desc="Creating tool favorites") if verbose else users
    
    for user in iterator:
        # Randomly select 1-5 tools to favorite
        num_favorites = random.randint(1, min(5, len(tools)))
        favorite_tools = random.sample(tools, num_favorites)
        
        for tool in favorite_tools:
            # Create tool favorite
            favorite = ToolFavorite()
            favorite.user_id = user.id
            favorite.tool_id = tool.id
            
            favorites.append(favorite)
            db_session.add(favorite)
    
    # Commit tool favorites to database
    db_session.commit()
    
    return favorites

def create_test_tool_usages(db_session, users, tools, checkins, usages_per_user, verbose=False):
    """
    Creates test tool usage records for users.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        tools: List of Tool objects
        checkins: List of EmotionalCheckin objects
        usages_per_user: Number of tool usages per user
        verbose: Whether to show progress bar
        
    Returns:
        List of created ToolUsage objects
    """
    usages = []
    
    # Create progress bar if verbose
    total_usages = len(users) * usages_per_user
    iterator = tqdm(range(total_usages), desc="Creating tool usages") if verbose else range(total_usages)
    
    # Group check-ins by user for easier access
    user_checkins = {}
    for checkin in checkins:
        if checkin.user_id not in user_checkins:
            user_checkins[checkin.user_id] = []
        user_checkins[checkin.user_id].append(checkin)
    
    # Group check-ins by context to find tool usage context
    tool_usage_checkins = {}
    for checkin in checkins:
        if checkin.context == EmotionContext.TOOL_USAGE:
            if checkin.user_id not in tool_usage_checkins:
                tool_usage_checkins[checkin.user_id] = []
            tool_usage_checkins[checkin.user_id].append(checkin)
    
    # Get user emotions for tool selection
    user_emotions = {}
    for checkin in checkins:
        if checkin.user_id not in user_emotions:
            user_emotions[checkin.user_id] = {}
        
        emotion = checkin.emotion_type
        if emotion not in user_emotions[checkin.user_id]:
            user_emotions[checkin.user_id][emotion] = 0
        user_emotions[checkin.user_id][emotion] += 1
    
    # Completion status options
    completion_statuses = ["COMPLETED", "PARTIAL", "ABANDONED"]
    completion_weights = [0.8, 0.15, 0.05]  # Most usages should be completed
    
    count = 0
    for user in users:
        # Generate tool usages for each user
        for _ in range(usages_per_user):
            # Select tool based on user's emotional profile
            selected_tool = None
            
            # If user has emotional data, prefer tools that match their emotions
            if user.id in user_emotions and user_emotions[user.id]:
                # Find the user's most common emotions
                common_emotions = sorted(
                    user_emotions[user.id].items(), 
                    key=lambda x: x[1], 
                    reverse=True
                )[:3]
                
                # Find tools that target these emotions
                matching_tools = []
                for tool in tools:
                    if tool.target_emotions:
                        for emotion, _ in common_emotions:
                            if emotion.value in tool.target_emotions:
                                matching_tools.append(tool)
                                break
                
                if matching_tools:
                    selected_tool = random.choice(matching_tools)
            
            # If no matching tool found, select random tool
            if not selected_tool:
                selected_tool = random.choice(tools)
            
            # Create tool usage record
            usage = ToolUsage()
            usage.user_id = user.id
            usage.tool_id = selected_tool.id
            
            # Set duration based on tool's estimated duration with some variation
            estimated_minutes = selected_tool.estimated_duration
            actual_minutes = max(1, round(estimated_minutes * random.uniform(0.7, 1.3)))
            usage.duration_seconds = actual_minutes * 60
            
            # Set completion status
            usage.completion_status = random.choices(
                completion_statuses,
                weights=completion_weights
            )[0]
            
            # Set completed_at to a random time in the past 90 days
            usage.completed_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 90),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )
            
            # Link to emotional check-ins if available
            if user.id in tool_usage_checkins and tool_usage_checkins[user.id]:
                # Try to find a check-in close to this usage date
                best_checkin = None
                best_diff = datetime.timedelta(days=365)  # Start with a large difference
                
                for checkin in tool_usage_checkins[user.id]:
                    diff = abs(checkin.created_at - usage.completed_at)
                    if diff < best_diff:
                        best_diff = diff
                        best_checkin = checkin
                
                # If we found a check-in within a reasonable time window (1 hour)
                if best_checkin and best_diff < datetime.timedelta(hours=1):
                    # Set it as post-checkin and adjust dates to be consistent
                    usage.post_checkin_id = best_checkin.id
                    
                    # Ensure the check-in is after the tool usage
                    if best_checkin.created_at < usage.completed_at:
                        best_checkin.created_at = usage.completed_at + datetime.timedelta(
                            minutes=random.randint(0, 10)
                        )
            
            usages.append(usage)
            db_session.add(usage)
            
            # Update progress bar
            if verbose:
                iterator.update(1)
            count += 1
    
    # Commit tool usages to database
    db_session.commit()
    
    return usages

def create_test_achievements(db_session, verbose=False):
    """
    Creates test achievements based on achievement types.
    
    Args:
        db_session: SQLAlchemy database session
        verbose: Whether to show progress bar
        
    Returns:
        List of created Achievement objects
    """
    achievements = []
    
    # Create progress bar if verbose
    iterator = tqdm(AchievementType, desc="Creating achievements") if verbose else AchievementType
    
    for achievement_type in iterator:
        # Create achievement from type
        achievement = Achievement.from_achievement_type(achievement_type)
        achievements.append(achievement)
        db_session.add(achievement)
    
    # Commit achievements to database
    db_session.commit()
    
    return achievements

def create_test_user_achievements(db_session, users, achievements, journals, tool_usages, verbose=False):
    """
    Creates test user achievement records.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        achievements: List of Achievement objects
        journals: List of Journal objects
        tool_usages: List of ToolUsage objects
        verbose: Whether to show progress bar
        
    Returns:
        List of created UserAchievement objects
    """
    user_achievements = []
    
    # Create progress bar if verbose
    iterator = tqdm(users, desc="Creating user achievements") if verbose else users
    
    # Group journals by user
    user_journals = {}
    for journal in journals:
        if journal.user_id not in user_journals:
            user_journals[journal.user_id] = []
        user_journals[journal.user_id].append(journal)
    
    # Group tool usages by user
    user_tool_usages = {}
    for usage in tool_usages:
        if usage.user_id not in user_tool_usages:
            user_tool_usages[usage.user_id] = []
        user_tool_usages[usage.user_id].append(usage)
    
    # Create UserAchievement model if it doesn't exist in imported models
    class UserAchievement(Base):
        __tablename__ = "user_achievements"
        
        id = sqlalchemy.Column(sqlalchemy.UUID, primary_key=True, default=uuid.uuid4)
        user_id = sqlalchemy.Column(sqlalchemy.ForeignKey("users.id"), nullable=False)
        achievement_id = sqlalchemy.Column(sqlalchemy.ForeignKey("achievements.id"), nullable=False)
        earned_at = sqlalchemy.Column(sqlalchemy.DateTime, nullable=False)
        created_at = sqlalchemy.Column(sqlalchemy.DateTime, default=sqlalchemy.func.now())
        updated_at = sqlalchemy.Column(sqlalchemy.DateTime, default=sqlalchemy.func.now(), onupdate=sqlalchemy.func.now())
    
    # Create achievement map for easier lookup
    achievement_map = {a.achievement_type: a for a in achievements}
    
    for user in iterator:
        # Determine which achievements the user has earned
        user_journal_count = len(user_journals.get(user.id, []))
        user_tool_usage_count = len(user_tool_usages.get(user.id, []))
        
        # Dictionary to store tool usages by category
        category_usage_counts = {}
        
        # Count tool usages by category
        for usage in user_tool_usages.get(user.id, []):
            # Find the tool
            tool = None
            for t in tools:
                if t.id == usage.tool_id:
                    tool = t
                    break
            
            if tool and tool.category:
                category = tool.category
                if category not in category_usage_counts:
                    category_usage_counts[category] = 0
                category_usage_counts[category] += 1
        
        # Calculate unique tools used
        unique_tools = set()
        for usage in user_tool_usages.get(user.id, []):
            unique_tools.add(usage.tool_id)
        unique_tool_count = len(unique_tools)
        
        # Award FIRST_STEP achievement to everyone
        if AchievementType.FIRST_STEP in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.FIRST_STEP].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(30, 90)
            )
            user_achievements.append(ua)
            db_session.add(ua)
        
        # Award FIRST_JOURNAL if they have journals
        if user_journal_count > 0 and AchievementType.FIRST_JOURNAL in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.FIRST_JOURNAL].id
            # Set earned_at to the date of their first journal
            if user.id in user_journals and user_journals[user.id]:
                earliest_journal = min(user_journals[user.id], key=lambda j: j.created_at)
                ua.earned_at = earliest_journal.created_at
            else:
                ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                    days=random.randint(15, 60)
                )
            user_achievements.append(ua)
            db_session.add(ua)
        
        # Award JOURNAL_MASTER if they have 25+ journals
        if user_journal_count >= 25 and AchievementType.JOURNAL_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.JOURNAL_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
        
        # Award TOOL_EXPLORER if they've used 5+ unique tools
        if unique_tool_count >= 5 and AchievementType.TOOL_EXPLORER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.TOOL_EXPLORER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 45)
            )
            user_achievements.append(ua)
            db_session.add(ua)
        
        # Award category-specific achievements
        if ToolCategory.BREATHING in category_usage_counts and category_usage_counts[ToolCategory.BREATHING] >= 10 and AchievementType.BREATHING_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.BREATHING_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
            
        if ToolCategory.MEDITATION in category_usage_counts and category_usage_counts[ToolCategory.MEDITATION] >= 10 and AchievementType.MEDITATION_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.MEDITATION_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
            
        if ToolCategory.SOMATIC in category_usage_counts and category_usage_counts[ToolCategory.SOMATIC] >= 10 and AchievementType.SOMATIC_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.SOMATIC_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
            
        if ToolCategory.JOURNALING in category_usage_counts and category_usage_counts[ToolCategory.JOURNALING] >= 10 and AchievementType.JOURNALING_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.JOURNALING_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
            
        if ToolCategory.GRATITUDE in category_usage_counts and category_usage_counts[ToolCategory.GRATITUDE] >= 10 and AchievementType.GRATITUDE_MASTER in achievement_map:
            ua = UserAchievement()
            ua.user_id = user.id
            ua.achievement_id = achievement_map[AchievementType.GRATITUDE_MASTER].id
            ua.earned_at = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(0, 30)
            )
            user_achievements.append(ua)
            db_session.add(ua)
    
    # Commit user achievements to database
    db_session.commit()
    
    return user_achievements

def create_test_streaks(db_session, users, journals, checkins, tool_usages, verbose=False):
    """
    Creates test streak records for users.
    
    Args:
        db_session: SQLAlchemy database session
        users: List of User objects
        journals: List of Journal objects
        checkins: List of EmotionalCheckin objects
        tool_usages: List of ToolUsage objects
        verbose: Whether to show progress bar
        
    Returns:
        List of created Streak objects
    """
    streaks = []
    
    # Create progress bar if verbose
    iterator = tqdm(users, desc="Creating streaks") if verbose else users
    
    # Combine all user activity for streak calculation
    user_activity = {}
    
    # Add journals to user activity
    for journal in journals:
        user_id = journal.user_id
        date = journal.created_at.date()
        
        if user_id not in user_activity:
            user_activity[user_id] = {}
        
        if date not in user_activity[user_id]:
            user_activity[user_id][date] = []
            
        user_activity[user_id][date].append({
            "type": "journal",
            "id": journal.id,
            "created_at": journal.created_at
        })
    
    # Add check-ins to user activity
    for checkin in checkins:
        user_id = checkin.user_id
        date = checkin.created_at.date()
        
        if user_id not in user_activity:
            user_activity[user_id] = {}
        
        if date not in user_activity[user_id]:
            user_activity[user_id][date] = []
            
        user_activity[user_id][date].append({
            "type": "checkin",
            "id": checkin.id,
            "created_at": checkin.created_at
        })
    
    # Add tool usages to user activity
    for usage in tool_usages:
        user_id = usage.user_id
        date = usage.completed_at.date()
        
        if user_id not in user_activity:
            user_activity[user_id] = {}
        
        if date not in user_activity[user_id]:
            user_activity[user_id][date] = []
            
        user_activity[user_id][date].append({
            "type": "tool_usage",
            "id": usage.id,
            "created_at": usage.completed_at
        })
    
    for user in iterator:
        # Skip users with no activity
        if user.id not in user_activity or not user_activity[user.id]:
            continue
            
        # Calculate user's current streak
        dates = sorted(user_activity[user.id].keys())
        
        # Find current streak (consecutive days from the most recent activity date)
        current_streak = 1
        for i in range(len(dates)-1, 0, -1):
            if (dates[i] - dates[i-1]).days == 1:
                current_streak += 1
            else:
                break
        
        # Find longest streak
        longest_streak = 1
        current_run = 1
        
        for i in range(1, len(dates)):
            if (dates[i] - dates[i-1]).days == 1:
                current_run += 1
            else:
                current_run = 1
            
            if current_run > longest_streak:
                longest_streak = current_run
        
        # Create streak record
        streak = Streak()
        streak.user_id = user.id
        streak.current_streak = current_streak
        streak.longest_streak = longest_streak
        streak.total_days_active = len(dates)
        streak.last_activity_date = max(dates)
        
        # Create streak history
        streak_history = []
        
        for date in dates:
            streak_history.append({
                "date": date.isoformat(),
                "type": "activity",
                "activities": [a["type"] for a in user_activity[user.id][date]]
            })
        
        streak.streak_history = streak_history
        
        # Set realistic grace period usage
        if random.random() < 0.3:  # 30% chance of having used grace period
            streak.grace_period_used_count = random.randint(1, 3)
        else:
            streak.grace_period_used_count = 0
            
        streak.grace_period_reset_date = datetime.date.today() - datetime.timedelta(
            days=random.randint(0, 6)
        )
        streak.grace_period_active = False
        
        streaks.append(streak)
        db_session.add(streak)
    
    # Commit streaks to database
    db_session.commit()
    
    return streaks

def clear_existing_data(db_session, verbose=False):
    """
    Clears existing data from the database.
    
    Args:
        db_session: SQLAlchemy database session
        verbose: Whether to show progress messages
    """
    if verbose:
        print("Clearing existing data...")
    
    try:
        # Delete data in the correct order to respect foreign key constraints
        
        # Delete UserAchievement records
        db_session.execute(sqlalchemy.text("DELETE FROM user_achievements"))
        
        # Delete ToolUsage records
        db_session.execute(sqlalchemy.text("DELETE FROM tool_usages"))
        
        # Delete ToolFavorite records
        db_session.execute(sqlalchemy.text("DELETE FROM tool_favorites"))
        
        # Delete EmotionalTrend records
        db_session.execute(sqlalchemy.text("DELETE FROM emotional_trends"))
        
        # Delete EmotionalCheckin records
        db_session.execute(sqlalchemy.text("DELETE FROM emotional_checkins"))
        
        # Delete Journal records
        db_session.execute(sqlalchemy.text("DELETE FROM journals"))
        
        # Delete Streak records
        db_session.execute(sqlalchemy.text("DELETE FROM streaks"))
        
        # Delete User records (except admin users)
        db_session.execute(sqlalchemy.text("DELETE FROM users WHERE email NOT LIKE '%admin%'"))
        
        # Delete Tool records
        db_session.execute(sqlalchemy.text("DELETE FROM tools"))
        
        # Delete Achievement records
        db_session.execute(sqlalchemy.text("DELETE FROM achievements"))
        
        # Commit changes
        db_session.commit()
        
        if verbose:
            print("Existing data cleared successfully")
    except Exception as e:
        db_session.rollback()
        print(f"Error clearing data: {e}")
        raise

def main():
    """
    Main function that orchestrates the test data generation process.
    """
    args = setup_argparse()
    
    # Set up database connection
    db_session = next(get_db())
    
    try:
        # Clear existing data if requested
        if args.clear:
            clear_existing_data(db_session, args.verbose)
        
        # Create test users
        print(f"Creating {args.users} test users...")
        users = create_test_users(db_session, args.users, DEFAULT_PASSWORD, args.verbose)
        
        # Create test tools from templates
        print("Creating test tools...")
        tools = create_test_tools(db_session, TOOL_TEMPLATES_DIR, args.verbose)
        
        # Create test achievements
        print("Creating test achievements...")
        achievements = create_test_achievements(db_session, args.verbose)
        
        # Create test journals for users
        print(f"Creating {len(users) * args.journals} test journals...")
        journals = create_test_journals(db_session, users, args.journals, args.verbose)
        
        # Create test emotional check-ins
        print(f"Creating {len(users) * args.checkins} test emotional check-ins...")
        checkins = create_test_emotional_checkins(db_session, users, journals, args.checkins, args.verbose)
        
        # Create test emotional trends
        print("Creating test emotional trends...")
        trends = create_test_emotional_trends(db_session, users, checkins, args.verbose)
        
        # Create test tool favorites
        print("Creating test tool favorites...")
        favorites = create_test_tool_favorites(db_session, users, tools, args.verbose)
        
        # Create test tool usages
        print(f"Creating {len(users) * args.tool_usages} test tool usages...")
        tool_usages = create_test_tool_usages(db_session, users, tools, checkins, args.tool_usages, args.verbose)
        
        # Create test user achievements
        print("Creating test user achievements...")
        user_achievements = create_test_user_achievements(db_session, users, achievements, journals, tool_usages, args.verbose)
        
        # Create test streaks
        print("Creating test streaks...")
        streaks = create_test_streaks(db_session, users, journals, checkins, tool_usages, args.verbose)
        
        # Print summary of created data
        print("\nTest data generated successfully:")
        print(f"- {len(users)} users")
        print(f"- {len(tools)} tools")
        print(f"- {len(achievements)} achievements")
        print(f"- {len(journals)} voice journals")
        print(f"- {len(checkins)} emotional check-ins")
        print(f"- {len(trends)} emotional trends")
        print(f"- {len(favorites)} tool favorites")
        print(f"- {len(tool_usages)} tool usages")
        print(f"- {len(user_achievements)} user achievements")
        print(f"- {len(streaks)} streaks")
        
        return 0
    except Exception as e:
        print(f"Error generating test data: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())