"""
Integration tests for the Tool Library API endpoints in the Amira Wellness application.
Tests the functionality of tool retrieval, filtering, favoriting, usage tracking, 
and recommendation features to ensure they work correctly with the database 
and other components.
"""

import pytest  # pytest latest
import json  # standard library
import uuid  # standard library
from typing import Dict  # standard library

from fastapi import FastAPI  # fastapi 0.104+
from starlette.status import (  # starlette 0.27+
    HTTP_200_OK,
    HTTP_201_CREATED,
    HTTP_403_FORBIDDEN,
    HTTP_404_NOT_FOUND
)

# Test fixtures
from ..conftest import app_client, auth_headers, premium_auth_headers, admin_auth_headers
from ..fixtures.database import test_db
from ..fixtures.users import regular_user, premium_user, admin_user
from ..fixtures.tools import (
    breathing_tool, meditation_tool, somatic_tool, gratitude_tool, journaling_tool,
    premium_tool, tool_favorite, tool_usage_completed, tool_usage_with_emotions,
    multiple_tools
)

# Constants for test assertions
from ...app.constants.tools import ToolCategory, ToolContentType
from ...app.constants.emotions import EmotionType


@pytest.mark.integration
def test_get_all_tools(app_client, multiple_tools):
    """Test retrieving all tools with pagination."""
    # Make a GET request to retrieve all tools
    response = app_client.get("/api/v1/tools/")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response structure includes pagination fields
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert "page_size" in data
    assert "pages" in data
    
    # Verify the items list contains the expected number of tools
    assert len(data["items"]) == min(len(multiple_tools), data["page_size"])
    assert data["total"] == len(multiple_tools)
    
    # Test pagination by requesting page 2
    if data["pages"] > 1:
        response_page_2 = app_client.get("/api/v1/tools/?page=2")
        assert response_page_2.status_code == HTTP_200_OK
        data_page_2 = response_page_2.json()
        
        # Verify different items are returned on page 2
        assert data_page_2["page"] == 2
        assert data_page_2["items"] != data["items"]


@pytest.mark.integration
def test_get_tool_by_id(app_client, breathing_tool):
    """Test retrieving a specific tool by ID."""
    # Make a GET request to retrieve a specific tool
    response = app_client.get(f"/api/v1/tools/{breathing_tool.id}")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains correct tool data
    assert data["id"] == str(breathing_tool.id)
    assert data["name"] == breathing_tool.name
    assert data["description"] == breathing_tool.description
    assert data["category"] == breathing_tool.category.value
    assert data["content_type"] == breathing_tool.content_type.value
    assert data["estimated_duration"] == breathing_tool.estimated_duration
    
    # Verify content data is included
    assert "content" in data
    assert data["content"] == breathing_tool.content


@pytest.mark.integration
def test_get_tool_not_found(app_client):
    """Test retrieving a non-existent tool returns 404."""
    # Generate a random UUID for a non-existent tool
    random_id = str(uuid.uuid4())
    
    # Make a GET request for a non-existent tool
    response = app_client.get(f"/api/v1/tools/{random_id}")
    
    # Verify the response status code is 404 Not Found
    assert response.status_code == HTTP_404_NOT_FOUND
    
    # Verify error message
    data = response.json()
    assert "detail" in data
    assert "not found" in data["detail"].lower()


@pytest.mark.integration
def test_get_tools_by_category(app_client, breathing_tool, meditation_tool, multiple_tools):
    """Test retrieving tools filtered by category."""
    # Make a GET request for breathing tools
    response = app_client.get(f"/api/v1/tools/category/{ToolCategory.BREATHING.value}")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify all returned tools have the correct category
    assert len(data["items"]) > 0
    for tool in data["items"]:
        assert tool["category"] == ToolCategory.BREATHING.value
    
    # Make a GET request for meditation tools
    response = app_client.get(f"/api/v1/tools/category/{ToolCategory.MEDITATION.value}")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify all returned tools have the correct category
    assert len(data["items"]) > 0
    for tool in data["items"]:
        assert tool["category"] == ToolCategory.MEDITATION.value
    
    # Test pagination for category filtering
    response = app_client.get(f"/api/v1/tools/category/{ToolCategory.BREATHING.value}?page=1&page_size=5")
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert data["page"] == 1
    assert data["page_size"] == 5


@pytest.mark.integration
def test_get_tools_by_emotion(app_client, multiple_tools):
    """Test retrieving tools targeting a specific emotion."""
    # Make a GET request for tools targeting anxiety
    response = app_client.get(f"/api/v1/tools/emotion/{EmotionType.ANXIETY.value}")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify returned tools target the specified emotion
    assert len(data["items"]) > 0
    
    # Make a GET request for tools targeting sadness
    response = app_client.get(f"/api/v1/tools/emotion/{EmotionType.SADNESS.value}")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify pagination works for emotion filtering
    response = app_client.get(f"/api/v1/tools/emotion/{EmotionType.ANXIETY.value}?page=1&page_size=5")
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert data["page"] == 1
    assert data["page_size"] == 5


@pytest.mark.integration
def test_filter_tools(app_client, multiple_tools):
    """Test filtering tools with multiple criteria."""
    # Filter by category
    response = app_client.get(f"/api/v1/tools/?category={ToolCategory.BREATHING.value}")
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert len(data["items"]) > 0
    for tool in data["items"]:
        assert tool["category"] == ToolCategory.BREATHING.value
    
    # Filter by content type
    response = app_client.get(f"/api/v1/tools/?content_type={ToolContentType.AUDIO.value}")
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert len(data["items"]) > 0
    for tool in data["items"]:
        assert tool["content_type"] == ToolContentType.AUDIO.value
    
    # Filter by maximum duration
    response = app_client.get("/api/v1/tools/?max_duration=5")
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert len(data["items"]) > 0
    for tool in data["items"]:
        assert tool["estimated_duration"] <= 5
    
    # Filter with multiple parameters
    response = app_client.get(
        f"/api/v1/tools/?category={ToolCategory.BREATHING.value}&max_duration=5"
    )
    assert response.status_code == HTTP_200_OK
    data = response.json()
    for tool in data["items"]:
        assert tool["category"] == ToolCategory.BREATHING.value
        assert tool["estimated_duration"] <= 5


@pytest.mark.integration
def test_create_tool_admin(app_client, admin_auth_headers):
    """Test creating a new tool as admin user."""
    # Create tool data
    new_tool_data = {
        "name": "Nueva Técnica de Respiración",
        "description": "Una técnica de respiración para reducir el estrés",
        "category": ToolCategory.BREATHING.value,
        "content_type": ToolContentType.GUIDED_EXERCISE.value,
        "content": {
            "steps": [
                {"title": "Paso 1", "description": "Inhale profundamente", "duration": 5},
                {"title": "Paso 2", "description": "Mantenga la respiración", "duration": 3},
                {"title": "Paso 3", "description": "Exhale lentamente", "duration": 7}
            ]
        },
        "estimated_duration": 3,
        "difficulty": "BEGINNER",
        "target_emotions": [EmotionType.ANXIETY.value, EmotionType.STRESS.value],
        "is_premium": False
    }
    
    # Make a POST request to create a new tool with admin authentication
    response = app_client.post(
        "/api/v1/tools/",
        json=new_tool_data,
        headers=admin_auth_headers
    )
    
    # Verify the response status code is 201 Created
    assert response.status_code == HTTP_201_CREATED
    
    data = response.json()
    
    # Verify response contains created tool data
    assert data["name"] == new_tool_data["name"]
    assert data["description"] == new_tool_data["description"]
    assert data["category"] == new_tool_data["category"]
    
    # Verify tool was created by retrieving it
    tool_id = data["id"]
    response = app_client.get(f"/api/v1/tools/{tool_id}")
    assert response.status_code == HTTP_200_OK
    assert response.json()["name"] == new_tool_data["name"]


@pytest.mark.integration
def test_create_tool_unauthorized(app_client, auth_headers):
    """Test creating a tool as regular user fails."""
    # Create tool data
    new_tool_data = {
        "name": "Técnica no autorizada",
        "description": "Esta herramienta no debería crearse",
        "category": ToolCategory.BREATHING.value,
        "content_type": ToolContentType.TEXT.value,
        "content": {
            "text": "Contenido de ejemplo"
        },
        "estimated_duration": 2,
        "difficulty": "BEGINNER",
        "target_emotions": [EmotionType.ANXIETY.value],
        "is_premium": False
    }
    
    # Make a POST request with regular user authentication
    response = app_client.post(
        "/api/v1/tools/",
        json=new_tool_data,
        headers=auth_headers
    )
    
    # Verify the response status code is 403 Forbidden
    assert response.status_code == HTTP_403_FORBIDDEN
    
    # Verify error message
    data = response.json()
    assert "detail" in data
    assert "permission" in data["detail"].lower() or "access" in data["detail"].lower()


@pytest.mark.integration
def test_update_tool_admin(app_client, admin_auth_headers, breathing_tool):
    """Test updating an existing tool as admin user."""
    # Create update data
    update_data = {
        "name": "Respiración 4-7-8 Actualizada",
        "description": "Versión actualizada del ejercicio de respiración"
    }
    
    # Make a PUT request with admin authentication
    response = app_client.patch(
        f"/api/v1/tools/{breathing_tool.id}",
        json=update_data,
        headers=admin_auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains updated tool data
    assert data["name"] == update_data["name"]
    assert data["description"] == update_data["description"]
    
    # Verify tool was updated by retrieving it
    response = app_client.get(f"/api/v1/tools/{breathing_tool.id}")
    assert response.status_code == HTTP_200_OK
    assert response.json()["name"] == update_data["name"]
    assert response.json()["description"] == update_data["description"]


@pytest.mark.integration
def test_update_tool_unauthorized(app_client, auth_headers, breathing_tool):
    """Test updating a tool as regular user fails."""
    # Create update data
    update_data = {
        "name": "Intento no autorizado",
        "description": "Esta actualización no debería funcionar"
    }
    
    # Make a PUT request with regular user authentication
    response = app_client.patch(
        f"/api/v1/tools/{breathing_tool.id}",
        json=update_data,
        headers=auth_headers
    )
    
    # Verify the response status code is 403 Forbidden
    assert response.status_code == HTTP_403_FORBIDDEN
    
    # Verify error message
    data = response.json()
    assert "detail" in data
    assert "permission" in data["detail"].lower() or "access" in data["detail"].lower()


@pytest.mark.integration
def test_delete_tool_admin(app_client, admin_auth_headers, breathing_tool):
    """Test deleting a tool as admin user."""
    # Make a DELETE request with admin authentication
    response = app_client.delete(
        f"/api/v1/tools/{breathing_tool.id}",
        headers=admin_auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    # Verify tool was deleted by attempting to retrieve it
    response = app_client.get(f"/api/v1/tools/{breathing_tool.id}")
    assert response.status_code == HTTP_404_NOT_FOUND


@pytest.mark.integration
def test_delete_tool_unauthorized(app_client, auth_headers, breathing_tool):
    """Test deleting a tool as regular user fails."""
    # Make a DELETE request with regular user authentication
    response = app_client.delete(
        f"/api/v1/tools/{breathing_tool.id}",
        headers=auth_headers
    )
    
    # Verify the response status code is 403 Forbidden
    assert response.status_code == HTTP_403_FORBIDDEN
    
    # Verify error message
    data = response.json()
    assert "detail" in data
    assert "permission" in data["detail"].lower() or "access" in data["detail"].lower()


@pytest.mark.integration
def test_get_favorite_tools(app_client, auth_headers, tool_favorite):
    """Test retrieving user's favorite tools."""
    # Make a GET request with authentication
    response = app_client.get(
        "/api/v1/tools/favorites",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains favorite tool
    assert "items" in data
    assert len(data["items"]) >= 1
    
    # Verify the favorite tool ID matches our fixture
    favorite_ids = [tool["id"] for tool in data["items"]]
    assert str(tool_favorite.tool_id) in favorite_ids
    
    # Test pagination
    response = app_client.get(
        "/api/v1/tools/favorites?page=1&page_size=5",
        headers=auth_headers
    )
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert data["page"] == 1
    assert data["page_size"] == 5


@pytest.mark.integration
def test_toggle_favorite_add(app_client, auth_headers, meditation_tool):
    """Test adding a tool to favorites."""
    # Make a POST request to add tool to favorites
    response = app_client.post(
        f"/api/v1/tools/favorites/{meditation_tool.id}",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response indicates tool is now favorited
    assert "is_favorite" in data
    assert data["is_favorite"] is True
    
    # Verify tool appears in favorites list
    response = app_client.get(
        "/api/v1/tools/favorites",
        headers=auth_headers
    )
    assert response.status_code == HTTP_200_OK
    
    favorites = response.json()
    favorite_ids = [tool["id"] for tool in favorites["items"]]
    assert str(meditation_tool.id) in favorite_ids


@pytest.mark.integration
def test_toggle_favorite_remove(app_client, auth_headers, tool_favorite):
    """Test removing a tool from favorites."""
    # Make a POST request to toggle favorite status for an already favorited tool
    response = app_client.post(
        f"/api/v1/tools/favorites/{tool_favorite.tool_id}",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response indicates tool is no longer favorited
    assert "is_favorite" in data
    assert data["is_favorite"] is False
    
    # Verify tool no longer appears in favorites list
    response = app_client.get(
        "/api/v1/tools/favorites",
        headers=auth_headers
    )
    assert response.status_code == HTTP_200_OK
    
    favorites = response.json()
    favorite_ids = [tool["id"] for tool in favorites["items"]]
    assert str(tool_favorite.tool_id) not in favorite_ids


@pytest.mark.integration
def test_record_tool_usage(app_client, auth_headers, breathing_tool):
    """Test recording tool usage."""
    # Create tool usage data
    usage_data = {
        "tool_id": str(breathing_tool.id),
        "duration_seconds": 300,  # 5 minutes
        "completion_status": "COMPLETED",
        "pre_checkin_id": None,
        "post_checkin_id": None
    }
    
    # Make a POST request to record usage
    response = app_client.post(
        "/api/v1/tools/usage",
        json=usage_data,
        headers=auth_headers
    )
    
    # Verify the response status code is 201 Created
    assert response.status_code == HTTP_201_CREATED
    
    data = response.json()
    
    # Verify response contains usage record data
    assert data["tool_id"] == str(breathing_tool.id)
    assert data["duration_seconds"] == usage_data["duration_seconds"]
    assert data["completion_status"] == usage_data["completion_status"]
    
    # Verify usage record is retrievable
    response = app_client.get(
        "/api/v1/tools/usage",
        headers=auth_headers
    )
    assert response.status_code == HTTP_200_OK
    
    usage_records = response.json()
    usage_tool_ids = [record["tool_id"] for record in usage_records["items"]]
    assert str(breathing_tool.id) in usage_tool_ids


@pytest.mark.integration
def test_get_user_tool_usage(app_client, auth_headers, tool_usage_completed):
    """Test retrieving user's tool usage history."""
    # Make a GET request for usage history
    response = app_client.get(
        "/api/v1/tools/usage",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains usage records
    assert "items" in data
    assert len(data["items"]) >= 1
    
    # Verify the usage record matches our fixture
    usage_ids = [record["id"] for record in data["items"]]
    assert str(tool_usage_completed.id) in usage_ids
    
    # Test pagination
    response = app_client.get(
        "/api/v1/tools/usage?page=1&page_size=5",
        headers=auth_headers
    )
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert data["page"] == 1
    assert data["page_size"] == 5


@pytest.mark.integration
def test_get_tool_usage_stats(app_client, auth_headers, breathing_tool, tool_usage_completed):
    """Test retrieving usage statistics for a specific tool."""
    # Make a GET request for tool usage stats
    response = app_client.get(
        f"/api/v1/tools/usage/stats/{breathing_tool.id}",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains usage statistics
    assert "total_usages" in data
    assert "total_duration_seconds" in data
    assert "completion_stats" in data
    assert "average_duration_seconds" in data
    
    # Verify statistics are accurate
    assert data["total_usages"] >= 1
    assert data["total_duration_seconds"] >= tool_usage_completed.duration_seconds


@pytest.mark.integration
def test_get_recommended_tools(app_client, auth_headers, multiple_tools):
    """Test retrieving tool recommendations based on emotional state."""
    # Create recommendation request data
    recommendation_data = {
        "emotion_type": EmotionType.ANXIETY.value,
        "intensity": 7
    }
    
    # Make a POST request for recommendations
    response = app_client.post(
        "/api/v1/tools/recommendations",
        json=recommendation_data,
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains recommendations
    assert isinstance(data, list)
    assert len(data) > 0
    
    # Verify each recommendation has required fields
    for recommendation in data:
        assert "tool_id" in recommendation
        assert "tool_name" in recommendation
        assert "relevance_score" in recommendation
        assert "reason" in recommendation
    
    # Test with a different emotion
    recommendation_data["emotion_type"] = EmotionType.SADNESS.value
    
    response = app_client.post(
        "/api/v1/tools/recommendations",
        json=recommendation_data,
        headers=auth_headers
    )
    
    assert response.status_code == HTTP_200_OK
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0


@pytest.mark.integration
def test_get_tool_categories(app_client):
    """Test retrieving all tool categories with metadata."""
    # Make a GET request for tool categories
    response = app_client.get("/api/v1/tools/categories")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains categories
    assert isinstance(data, list)
    assert len(data) >= 5  # At least 5 categories defined in the enum
    
    # Verify each category includes required metadata
    for category in data:
        assert "id" in category
        assert "display_name" in category
        assert "description" in category
        assert "color" in category
        
        # Verify category ID is a valid enum value
        assert any(category["id"] == tool_cat.value for tool_cat in ToolCategory)


@pytest.mark.integration
def test_get_tool_content_types(app_client):
    """Test retrieving all tool content types with metadata."""
    # Make a GET request for tool content types
    response = app_client.get("/api/v1/tools/content-types")
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains content types
    assert isinstance(data, list)
    assert len(data) >= 4  # At least 4 content types defined in the enum
    
    # Verify each content type includes required metadata
    for content_type in data:
        assert "id" in content_type
        assert "display_name" in content_type
        assert "icon" in content_type
        
        # Verify content type ID is a valid enum value
        assert any(content_type["id"] == ct.value for ct in ToolContentType)


@pytest.mark.integration
def test_get_tool_library_stats_admin(app_client, admin_auth_headers, multiple_tools, tool_usage_completed):
    """Test retrieving overall tool library statistics as admin."""
    # Make a GET request for library stats with admin authentication
    response = app_client.get(
        "/api/v1/tools/stats",
        headers=admin_auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify response contains library statistics
    assert "total_tools" in data
    assert "total_premium_tools" in data
    assert "total_favorites" in data
    assert "total_usages" in data
    assert "category_breakdown" in data
    assert "most_popular_tools" in data
    
    # Verify statistics are accurate
    assert data["total_tools"] >= len(multiple_tools)
    assert data["total_usages"] >= 1
    assert len(data["category_breakdown"]) > 0
    assert isinstance(data["most_popular_tools"], list)


@pytest.mark.integration
def test_get_tool_library_stats_unauthorized(app_client, auth_headers):
    """Test retrieving library statistics as regular user fails."""
    # Make a GET request for library stats with regular user authentication
    response = app_client.get(
        "/api/v1/tools/stats",
        headers=auth_headers
    )
    
    # Verify the response status code is 403 Forbidden
    assert response.status_code == HTTP_403_FORBIDDEN
    
    # Verify error message
    data = response.json()
    assert "detail" in data
    assert "permission" in data["detail"].lower() or "access" in data["detail"].lower()


@pytest.mark.integration
def test_premium_tool_access(app_client, auth_headers, premium_auth_headers, premium_tool):
    """Test premium tool access for different user types."""
    # Regular user request for premium tool
    response = app_client.get(
        f"/api/v1/tools/{premium_tool.id}",
        headers=auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify premium content is not included for regular users
    assert data["is_premium"] is True
    if "content" in data:
        assert data["content"].get("full_content_accessible") is False or data["content"].get("preview_only") is True
    
    # Premium user request for premium tool
    response = app_client.get(
        f"/api/v1/tools/{premium_tool.id}",
        headers=premium_auth_headers
    )
    
    # Verify the response status code is 200 OK
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    
    # Verify premium content is included for premium users
    assert data["is_premium"] is True
    assert "content" in data
    
    # Verify premium tools are marked in tool listings
    response = app_client.get("/api/v1/tools/", headers=auth_headers)
    
    assert response.status_code == HTTP_200_OK
    
    data = response.json()
    premium_tools = [tool for tool in data["items"] if tool["is_premium"] is True]
    assert len(premium_tools) > 0