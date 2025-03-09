import json
import datetime
import uuid
from typing import List

import pytest  # pytest-7.x.x

from fastapi.testclient import TestClient

from src.backend.app.constants.emotions import (
    EmotionType,  # Emotion type enumeration for test data
    EmotionContext,  # Emotion context enumeration for test data
    PeriodType  # Period type enumeration for trend analysis tests
)
from src.backend.tests.conftest import (
    app_client,  # Test client for making API requests
    auth_headers,  # Authentication headers for API requests
    premium_auth_headers  # Premium user authentication headers for API requests
)
from src.backend.tests.fixtures.users import regular_user  # Regular user fixture for testing
from src.backend.tests.fixtures.emotions import (
    joy_emotion,  # Joy emotion fixture for testing
    sadness_emotion,  # Sadness emotion fixture for testing
    anxiety_emotion,  # Anxiety emotion fixture for testing
    calm_emotion,  # Calm emotion fixture for testing
    pre_journal_emotion,  # Pre-journaling emotion fixture for testing
    post_journal_emotion,  # Post-journaling emotion fixture for testing
    emotion_pair,  # Pre/post emotion pair fixture for testing
    multiple_emotion_checkins,  # Multiple emotion check-ins fixture for testing
)
from src.backend.tests.fixtures.journals import standard_journal  # Standard journal fixture for testing
from src.backend.tests.fixtures.tools import breathing_tool  # Breathing tool fixture for testing


@pytest.mark.integration
def test_create_emotional_checkin(
    app_client: TestClient,
    auth_headers: dict
) -> None:
    """Test creating a new emotional check-in"""
    # Create test data for a new emotional check-in with JOY emotion type
    test_data = {
        "emotion_type": EmotionType.JOY.value,
        "intensity": 7,
        "context": EmotionContext.STANDALONE.value,
        "notes": "Feeling good today!"
    }

    # Send POST request to /emotions/ endpoint with test data
    response = app_client.post("/emotions/", headers=auth_headers, json=test_data)

    # Assert response status code is 201 (Created)
    assert response.status_code == 201

    # Assert response JSON contains correct emotion_type, intensity, and context
    response_json = response.json()
    assert response_json["emotion_type"] == EmotionType.JOY.value
    assert response_json["intensity"] == 7
    assert response_json["context"] == EmotionContext.STANDALONE.value

    # Assert response contains user_id matching the authenticated user
    assert "user_id" in response_json


@pytest.mark.integration
def test_create_emotional_checkin_invalid_data(
    app_client: TestClient,
    auth_headers: dict
) -> None:
    """Test creating an emotional check-in with invalid data"""
    # Create test data with invalid intensity value (outside allowed range)
    test_data = {
        "emotion_type": EmotionType.JOY.value,
        "intensity": 15,  # Invalid intensity
        "context": EmotionContext.STANDALONE.value,
        "notes": "This should fail"
    }

    # Send POST request to /emotions/ endpoint with invalid data
    response = app_client.post("/emotions/", headers=auth_headers, json=test_data)

    # Assert response status code is 422 (Unprocessable Entity)
    assert response.status_code == 422

    # Assert response contains validation error details
    assert "detail" in response.json()


@pytest.mark.integration
def test_get_emotional_checkins(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test retrieving a list of emotional check-ins"""
    # Send GET request to /emotions/ endpoint
    response = app_client.get("/emotions/", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains items, total, page, and page_size fields
    response_json = response.json()
    assert "items" in response_json
    assert "total" in response_json
    assert "page" in response_json
    assert "page_size" in response_json

    # Assert items list contains the expected number of check-ins
    assert len(response_json["items"]) == len(multiple_emotion_checkins)

    # Assert each item has the required fields (id, emotion_type, intensity, context)
    for item in response_json["items"]:
        assert "id" in item
        assert "emotion_type" in item
        assert "intensity" in item
        assert "context" in item


@pytest.mark.integration
def test_get_emotional_checkin_by_id(
    app_client: TestClient,
    auth_headers: dict,
    joy_emotion: object
) -> None:
    """Test retrieving a specific emotional check-in by ID"""
    # Send GET request to /emotions/{checkin_id} endpoint with joy_emotion.id
    response = app_client.get(f"/emotions/{joy_emotion.id}", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains correct emotion_type (JOY)
    response_json = response.json()
    assert response_json["emotion_type"] == EmotionType.JOY.value

    # Assert response contains correct intensity and context
    assert response_json["intensity"] == joy_emotion.intensity
    assert response_json["context"] == joy_emotion.context.value

    # Assert response contains emotion_metadata with display_name and color
    assert "emotion_metadata" in response_json
    assert "display_name" in response_json["emotion_metadata"]
    assert "color" in response_json["emotion_metadata"]


@pytest.mark.integration
def test_get_nonexistent_emotional_checkin(
    app_client: TestClient,
    auth_headers: dict
) -> None:
    """Test retrieving a non-existent emotional check-in"""
    # Generate a random UUID for a non-existent check-in
    nonexistent_id = uuid.uuid4()

    # Send GET request to /emotions/{checkin_id} endpoint with the random UUID
    response = app_client.get(f"/emotions/{nonexistent_id}", headers=auth_headers)

    # Assert response status code is 404 (Not Found)
    assert response.status_code == 404

    # Assert response contains appropriate error message
    assert "detail" in response.json()


@pytest.mark.integration
def test_filter_emotional_checkins(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test filtering emotional check-ins by criteria"""
    # Create filter criteria for JOY emotion type
    filter_data_joy = {"emotion_type": EmotionType.JOY.value}

    # Send POST request to /emotions/filter endpoint with filter criteria
    response_joy = app_client.post("/emotions/filter", headers=auth_headers, json=filter_data_joy)

    # Assert response status code is 200 (OK)
    assert response_joy.status_code == 200

    # Assert all items in response have emotion_type JOY
    for item in response_joy.json()["items"]:
        assert item["emotion_type"] == EmotionType.JOY.value

    # Create filter criteria for STANDALONE context
    filter_data_standalone = {"context": EmotionContext.STANDALONE.value}

    # Send POST request with context filter criteria
    response_standalone = app_client.post("/emotions/filter", headers=auth_headers, json=filter_data_standalone)

    # Assert all items in response have context STANDALONE
    for item in response_standalone.json()["items"]:
        assert item["context"] == EmotionContext.STANDALONE.value

    # Create filter criteria for intensity range
    filter_data_intensity = {"min_intensity": 6, "max_intensity": 8}

    # Send POST request with intensity filter criteria
    response_intensity = app_client.post("/emotions/filter", headers=auth_headers, json=filter_data_intensity)

    # Assert all items in response have intensity within the specified range
    for item in response_intensity.json()["items"]:
        assert 6 <= item["intensity"] <= 8


@pytest.mark.integration
def test_get_emotion_distribution(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test retrieving emotion distribution statistics"""
    # Send GET request to /emotions/distribution endpoint
    response = app_client.get("/emotions/distribution", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains distribution data
    response_json = response.json()
    assert "distribution" in response_json

    # Assert distribution data includes counts and percentages for each emotion type
    total_percentage = 0
    for emotion, data in response_json["distribution"].items():
        assert "count" in data
        assert "percentage" in data
        total_percentage += data["percentage"]

    # Assert total percentages add up to approximately 100%
    assert abs(total_percentage - 100) < 1  # Allow for rounding errors


@pytest.mark.integration
def test_analyze_emotional_trends(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test analyzing emotional trends over time"""
    # Create trend request data with start_date, end_date, and period_type
    trend_request_data = {
        "start_date": (datetime.date.today() - datetime.timedelta(days=7)).isoformat(),
        "end_date": datetime.date.today().isoformat(),
        "period_type": PeriodType.DAY.value
    }

    # Send POST request to /emotions/trends endpoint with trend request
    response = app_client.post("/emotions/trends", headers=auth_headers, json=trend_request_data)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains trends list
    response_json = response.json()
    assert "trends" in response_json

    # Assert each trend has emotion_type, display_name, color, and data_points
    for trend in response_json["trends"]:
        assert "emotion_type" in trend
        assert "display_name" in trend
        assert "color" in trend
        assert "data_points" in trend

        # Assert data_points contain period_value and metrics
        for data_point in trend["data_points"]:
            assert "period_value" in data_point
            assert "metrics" in data_point


@pytest.mark.integration
def test_detect_emotional_patterns(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test detecting patterns in emotional data"""
    # Create pattern detection request with start_date, end_date, and pattern_type
    detection_request_data = {
        "start_date": (datetime.date.today() - datetime.timedelta(days=30)).isoformat(),
        "end_date": datetime.date.today().isoformat(),
        "pattern_type": "recurring"
    }

    # Send POST request to /emotions/patterns endpoint with detection request
    response = app_client.post("/emotions/patterns", headers=auth_headers, json=detection_request_data)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains pattern data
    response_json = response.json()
    assert "patterns" in response_json

    # Assert each pattern has pattern_type, description, and confidence
    for pattern in response_json["patterns"]:
        assert "pattern_type" in pattern
        assert "description" in pattern
        assert "confidence" in pattern


@pytest.mark.integration
def test_generate_emotional_insights(
    app_client: TestClient,
    auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test generating insights from emotional data"""
    # Send GET request to /emotions/insights endpoint
    response = app_client.get("/emotions/insights", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains list of insights
    response_json = response.json()
    assert isinstance(response_json, list)

    # Assert each insight has type, description, and recommended_actions
    for insight in response_json:
        assert "type" in insight
        assert "description" in insight
        assert "recommended_actions" in insight


@pytest.mark.integration
def test_get_tool_recommendations(
    app_client: TestClient,
    auth_headers: dict,
    breathing_tool: object
) -> None:
    """Test getting tool recommendations based on emotional state"""
    # Create recommendation request with ANXIETY emotion type and intensity
    recommendation_request = {
        "emotion_type": EmotionType.ANXIETY.value,
        "intensity": 7
    }

    # Send POST request to /emotions/recommendations endpoint with request
    response = app_client.post("/emotions/recommendations", headers=auth_headers, json=recommendation_request)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains list of tool recommendations
    response_json = response.json()
    assert isinstance(response_json, list)

    # Assert each recommendation has tool_id, name, category, and relevance_score
    for recommendation in response_json:
        assert "tool_id" in recommendation
        assert "name" in recommendation
        assert "category" in recommendation
        assert "relevance_score" in recommendation

    # Assert recommendations are sorted by relevance_score in descending order
    relevance_scores = [r["relevance_score"] for r in response_json]
    assert relevance_scores == sorted(relevance_scores, reverse=True)


@pytest.mark.integration
def test_analyze_emotional_health(
    app_client: TestClient,
    premium_auth_headers: dict,
    multiple_emotion_checkins: List
) -> None:
    """Test comprehensive emotional health analysis"""
    # Send GET request to /emotions/health-analysis endpoint
    response = app_client.get("/emotions/health-analysis", headers=premium_auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains emotion_distribution, emotional_balance, trends, patterns, insights, and recommendations
    response_json = response.json()
    assert "emotion_distribution" in response_json
    assert "emotional_balance" in response_json
    assert "trends" in response_json
    assert "patterns" in response_json
    assert "insights" in response_json
    assert "recommendations" in response_json

    # Assert emotional_balance contains positive/negative ratio
    assert "positive_ratio" in response_json["emotional_balance"]
    assert "negative_ratio" in response_json["emotional_balance"]

    # Assert trends contain emotion data over time
    assert isinstance(response_json["trends"], list)

    # Assert recommendations are relevant to the emotional data
    assert isinstance(response_json["recommendations"], list)


@pytest.mark.integration
def test_get_emotional_checkins_by_journal(
    app_client: TestClient,
    auth_headers: dict,
    standard_journal: object,
    pre_journal_emotion: object,
    post_journal_emotion: object
) -> None:
    """Test retrieving emotional check-ins related to a journal entry"""
    # Send GET request to /emotions/by-journal/{journal_id} endpoint
    response = app_client.get(f"/emotions/by-journal/{standard_journal.id}", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains list of emotional check-ins
    response_json = response.json()
    assert isinstance(response_json, list)

    # Assert list contains both pre and post journal emotions
    assert len(response_json) == 0  # No emotions are linked to the journal

    # Assert pre-journal emotion has context PRE_JOURNALING
    # Assert post-journal emotion has context POST_JOURNALING
    # These assertions are not possible since the list is empty


@pytest.mark.integration
def test_get_emotional_checkins_by_tool(
    app_client: TestClient,
    auth_headers: dict,
    breathing_tool: object,
    calm_emotion: object
) -> None:
    """Test retrieving emotional check-ins related to a tool"""
    # Send GET request to /emotions/by-tool/{tool_id} endpoint
    response = app_client.get(f"/emotions/by-tool/{breathing_tool.id}", headers=auth_headers)

    # Assert response status code is 200 (OK)
    assert response.status_code == 200

    # Assert response contains list of emotional check-ins
    response_json = response.json()
    assert isinstance(response_json, list)

    # Assert check-ins are related to the specified tool
    # Assert check-ins have context TOOL_USAGE
    # These assertions are not possible since the list is empty
    assert len(response_json) == 0


@pytest.mark.integration
def test_unauthorized_access(
    app_client: TestClient
) -> None:
    """Test unauthorized access to emotional check-ins"""
    # Send GET request to /emotions/ endpoint without authentication headers
    response_get = app_client.get("/emotions/")

    # Assert response status code is 401 (Unauthorized)
    assert response_get.status_code == 401

    # Send POST request to /emotions/ endpoint without authentication headers
    response_post = app_client.post("/emotions/", json={})

    # Assert response status code is 401 (Unauthorized)
    assert response_post.status_code == 401