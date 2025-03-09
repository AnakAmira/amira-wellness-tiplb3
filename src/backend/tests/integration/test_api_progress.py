import json
from datetime import datetime, timedelta
import uuid

import pytest  # pytest==7.4.0

from src.backend.app.schemas.progress import ActivityType, StreakUpdate  # Internal import
from src.backend.app.services.progress import record_user_activity  # Internal import

BASE_URL = "/progress"


@pytest.mark.integration
def test_get_user_streak(app_client, auth_headers):
    """Test getting a user's streak information"""
    response = app_client.get(f"{BASE_URL}/streak", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "current_streak" in data
    assert "longest_streak" in data
    assert "last_activity_date" in data
    assert "total_days_active" in data
    assert "next_milestone" in data
    assert isinstance(data["next_milestone"], int)
    assert "milestone_progress" in data
    assert isinstance(data["milestone_progress"], float)


@pytest.mark.integration
def test_update_user_streak(app_client, auth_headers):
    """Test updating a user's streak with activity"""
    today = datetime.now().date()
    update_data = {"activity_date": today.isoformat()}
    response = app_client.post(f"{BASE_URL}/streak", headers=auth_headers, json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert "current_streak" in data
    assert "longest_streak" in data
    assert "last_activity_date" in data
    assert "total_days_active" in data
    assert data["current_streak"] >= 0


@pytest.mark.integration
def test_reset_user_streak(app_client, auth_headers):
    """Test resetting a user's streak to zero"""
    response = app_client.delete(f"{BASE_URL}/streak", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "current_streak" in data
    assert "longest_streak" in data
    assert "last_activity_date" in data
    assert "total_days_active" in data
    assert data["current_streak"] == 0


@pytest.mark.integration
def test_use_grace_period(app_client, auth_headers):
    """Test using a grace period for a user's streak"""
    response = app_client.post(f"{BASE_URL}/streak/grace-period", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert data["success"] is True

    # Verify grace period limit
    response = app_client.post(f"{BASE_URL}/streak/grace-period", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert data["success"] is False


@pytest.mark.integration
def test_get_next_streak_milestone(app_client, auth_headers):
    """Test getting the next milestone for a user's streak"""
    response = app_client.get(f"{BASE_URL}/streak/next-milestone", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "milestone" in data
    milestone = data["milestone"]
    assert milestone in [3, 7, 14, 30, 60, 90]


@pytest.mark.integration
def test_get_user_achievements(app_client, auth_headers, test_db, regular_user, earned_achievement):
    """Test getting a user's achievements"""
    response = app_client.get(f"{BASE_URL}/achievements", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert "page_size" in data
    assert len(data["items"]) > 0
    achievement = data["items"][0]
    assert "name" in achievement
    assert "description" in achievement
    assert "icon_url" in achievement
    assert "category" in achievement


@pytest.mark.integration
def test_get_user_activities(app_client, auth_headers, test_db, regular_user):
    """Test getting a user's activity history"""
    # Create test activity
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE)

    response = app_client.get(f"{BASE_URL}/activities", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert "page_size" in data
    assert len(data["items"]) > 0
    activity = data["items"][0]
    assert "activity_type" in activity
    assert "timestamp" in activity


@pytest.mark.integration
def test_get_user_activities_by_date_range(app_client, auth_headers, test_db, regular_user):
    """Test getting a user's activities within a date range"""
    # Create test activities with different dates
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)
    yesterday = today - timedelta(days=1)
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.VOICE_JOURNAL, activity_date=yesterday)

    # Set start_date and end_date for query parameters
    start_date = yesterday.isoformat()
    end_date = today.isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/activities/date-range", params=params, headers=auth_headers)
    assert response.status_code == 200
    activities = response.json()
    assert isinstance(activities, list)
    for activity in activities:
        activity_date = datetime.fromisoformat(activity["timestamp"])
        assert yesterday <= activity_date <= today


@pytest.mark.integration
def test_record_user_activity(app_client, auth_headers):
    """Test recording a user activity"""
    activity_data = {"activity_type": ActivityType.APP_USAGE.value}
    response = app_client.post(f"{BASE_URL}/activities", headers=auth_headers, json=activity_data)
    assert response.status_code == 200
    data = response.json()
    assert "activity" in data
    assert data["activity"]["activity_type"] == ActivityType.APP_USAGE.value
    assert "user_id" in data["activity"]


@pytest.mark.integration
def test_get_activity_distribution_by_day(app_client, auth_headers, test_db, regular_user):
    """Test getting activity distribution by day of week"""
    # Create test activities on different days
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)
    yesterday = today - timedelta(days=1)
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.VOICE_JOURNAL, activity_date=yesterday)

    # Set start_date and end_date for query parameters
    start_date = yesterday.isoformat()
    end_date = today.isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/activities/distribution/day", params=params, headers=auth_headers)
    assert response.status_code == 200
    distribution = response.json()
    assert isinstance(distribution, dict)
    assert "Monday" in distribution or "Tuesday" in distribution or "Wednesday" in distribution or "Thursday" in distribution or "Friday" in distribution or "Saturday" in distribution or "Sunday" in distribution
    for day, count in distribution.items():
        assert isinstance(count, int)
        assert count >= 0


@pytest.mark.integration
def test_get_activity_distribution_by_time(app_client, auth_headers, test_db, regular_user):
    """Test getting activity distribution by time of day"""
    # Create test activities at different times
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today.replace(hour=9, minute=0, second=0))
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.VOICE_JOURNAL, activity_date=today.replace(hour=15, minute=0, second=0))

    # Set start_date and end_date for query parameters
    start_date = today.isoformat()
    end_date = today.isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/activities/distribution/time", params=params, headers=auth_headers)
    assert response.status_code == 200
    distribution = response.json()
    assert isinstance(distribution, dict)
    assert "MORNING" in distribution or "AFTERNOON" in distribution or "EVENING" in distribution or "NIGHT" in distribution
    for time, count in distribution.items():
        assert isinstance(count, int)
        assert count >= 0


@pytest.mark.integration
def test_get_usage_statistics(app_client, auth_headers, test_db, regular_user):
    """Test getting usage statistics for a period"""
    # Create test activities of different types
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.VOICE_JOURNAL, activity_date=today)

    response = app_client.get(f"{BASE_URL}/statistics/week/current", headers=auth_headers)
    assert response.status_code == 200
    statistics = response.json()
    assert "total_journal_entries" in statistics
    assert "total_journaling_minutes" in statistics
    assert "total_checkins" in statistics
    assert "total_tool_usage" in statistics


@pytest.mark.integration
def test_update_usage_statistics(app_client, auth_headers, test_db, regular_user):
    """Test updating usage statistics for a period"""
    # Create test activities of different types
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.VOICE_JOURNAL, activity_date=today)

    response = app_client.post(f"{BASE_URL}/statistics/week/current", headers=auth_headers)
    assert response.status_code == 200
    statistics = response.json()
    assert "total_journal_entries" in statistics
    assert "total_journaling_minutes" in statistics
    assert "total_checkins" in statistics
    assert "total_tool_usage" in statistics


@pytest.mark.integration
def test_get_emotional_trends(app_client, auth_headers):
    """Test getting emotional trends for a date range"""
    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/emotional-trends", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "trends" in data
    assert "start_date" in data
    assert "end_date" in data
    assert isinstance(data["trends"], list)


@pytest.mark.integration
def test_generate_progress_insights(app_client, auth_headers, test_db, regular_user):
    """Test generating insights from progress data"""
    # Create test activities and emotional data
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for request body
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    request_body = {"start_date": start_date, "end_date": end_date}

    response = app_client.post(f"{BASE_URL}/insights", headers=auth_headers, json=request_body)
    assert response.status_code == 200
    data = response.json()
    assert "insights" in data
    assert isinstance(data["insights"], list)


@pytest.mark.integration
def test_get_progress_insights(app_client, auth_headers):
    """Test getting existing progress insights"""
    response = app_client.get(f"{BASE_URL}/insights", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "insights" in data
    assert isinstance(data["insights"], list)


@pytest.mark.integration
def test_get_progress_dashboard(app_client, auth_headers, test_db, regular_user, earned_achievement):
    """Test getting comprehensive progress dashboard data"""
    # Create test activities and emotional data
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/dashboard", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "streak_info" in data
    assert "emotional_trends" in data
    assert "most_frequent_emotions" in data
    assert "activity_by_day" in data
    assert "insights" in data


@pytest.mark.integration
def test_analyze_activity_patterns(app_client, auth_headers, test_db, regular_user):
    """Test analyzing patterns in user activities"""
    # Create test activities with different patterns
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/analysis/activity-patterns", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)


@pytest.mark.integration
def test_analyze_progress_trends(app_client, auth_headers, test_db, regular_user):
    """Test analyzing trends in user progress"""
    # Create test activities and emotional data with trends
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/analysis/progress-trends", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)


@pytest.mark.integration
def test_generate_personalized_recommendations(app_client, auth_headers, test_db, regular_user):
    """Test generating personalized recommendations"""
    # Create test activities and emotional data
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/recommendations", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.integration
def test_calculate_wellness_score(app_client, auth_headers, test_db, regular_user):
    """Test calculating overall wellness score"""
    # Create test activities and emotional data
    today = datetime.now()
    record_user_activity(db=test_db, user_id=regular_user.id, activity_type=ActivityType.APP_USAGE, activity_date=today)

    # Set start_date and end_date for query parameters
    start_date = (datetime.now() - timedelta(days=7)).isoformat()
    end_date = datetime.now().isoformat()
    params = {"start_date": start_date, "end_date": end_date}

    response = app_client.get(f"{BASE_URL}/wellness-score", params=params, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "overall_score" in data
    assert "component_scores" in data


@pytest.mark.integration
def test_unauthorized_access(app_client):
    """Test that unauthorized access is properly rejected"""
    response = app_client.get(f"{BASE_URL}/streak")
    assert response.status_code == 401

    response = app_client.get(f"{BASE_URL}/achievements")
    assert response.status_code == 401

    response = app_client.get(f"{BASE_URL}/dashboard")
    assert response.status_code == 401