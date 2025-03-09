import pytest
import json
import uuid
from datetime import datetime, timedelta
import io
import os
import base64

# API endpoint constants
API_PREFIX = "/api/v1"
JOURNALS_ENDPOINT = f"{API_PREFIX}/journals"
TEST_AUDIO_DATA = b"This is mock audio data for testing"

def create_journal_data(user_id, title, duration_seconds):
    """Helper function to create test journal data for API requests"""
    return {
        "user_id": str(user_id),
        "title": title,
        "duration_seconds": duration_seconds,
        "audio_format": "AAC",
        "file_size_bytes": duration_seconds * 10240,  # Rough estimate of file size
        "pre_emotional_state": {
            "emotion_type": "ANXIETY",
            "intensity": 7,
            "notes": "Feeling anxious before recording"
        },
        "post_emotional_state": {
            "emotion_type": "CALM",
            "intensity": 5,
            "notes": "Feeling calmer after recording"
        }
    }

def create_test_audio_file():
    """Helper function to create a test audio file for multipart requests"""
    audio_file = io.BytesIO(TEST_AUDIO_DATA)
    filename = "test_audio.aac"
    return (audio_file, filename)

def test_create_journal(app_client, auth_headers, regular_user):
    """Test creating a new journal entry"""
    # Create test data
    journal_data = create_journal_data(regular_user.id, "Test Journal", 120)
    audio_file, filename = create_test_audio_file()
    
    # Create multipart form data
    data = {
        "data": json.dumps(journal_data),
    }
    files = {
        "audio_file": (filename, audio_file, "audio/aac")
    }
    
    # Make request
    response = app_client.post(
        JOURNALS_ENDPOINT,
        data=data,
        files=files,
        headers=auth_headers
    )
    
    # Check response
    assert response.status_code == 201
    result = response.json()
    
    # Verify response contains expected data
    assert "id" in result
    assert result["title"] == journal_data["title"]
    assert result["duration_seconds"] == journal_data["duration_seconds"]
    assert result["audio_format"] == journal_data["audio_format"]
    assert "pre_emotional_state" in result
    assert "post_emotional_state" in result

def test_get_journal(app_client, auth_headers, short_journal):
    """Test retrieving a specific journal entry"""
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["id"] == str(short_journal.id)
    assert result["title"] == short_journal.title
    assert result["duration_seconds"] == short_journal.duration_seconds

def test_get_journal_unauthorized(app_client, short_journal):
    """Test retrieving a journal without authentication"""
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}"
    )
    
    assert response.status_code == 401

def test_get_nonexistent_journal(app_client, auth_headers):
    """Test retrieving a non-existent journal"""
    random_uuid = uuid.uuid4()
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{random_uuid}",
        headers=auth_headers
    )
    
    assert response.status_code == 404

def test_get_journals_list(app_client, auth_headers, multiple_journals):
    """Test retrieving a list of journal entries"""
    response = app_client.get(
        JOURNALS_ENDPOINT,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "items" in result
    assert "total" in result
    assert "page" in result
    assert "page_size" in result
    
    # Test pagination
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}?page=1&page_size=2",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert len(result["items"]) <= 2

def test_filter_journals(app_client, auth_headers, multiple_journals):
    """Test filtering journal entries"""
    # Create filter parameters
    filter_data = {
        "start_date": (datetime.utcnow() - timedelta(days=7)).isoformat(),
        "end_date": datetime.utcnow().isoformat(),
        "favorite_only": True
    }
    
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/filter",
        json=filter_data,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    # All returned journals should be favorites
    for journal in result["items"]:
        assert journal["is_favorite"] == True

def test_update_journal(app_client, auth_headers, short_journal):
    """Test updating a journal entry"""
    update_data = {
        "title": "Updated Journal Title"
    }
    
    response = app_client.patch(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        json=update_data,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["title"] == update_data["title"]
    
    # Verify changes were persisted
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert result["title"] == update_data["title"]

def test_mark_journal_as_favorite(app_client, auth_headers, short_journal):
    """Test marking a journal as favorite"""
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}/favorite",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["is_favorite"] == True
    
    # Verify changes were persisted
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert result["is_favorite"] == True

def test_unmark_journal_as_favorite(app_client, auth_headers, favorite_journal):
    """Test removing a journal from favorites"""
    response = app_client.delete(
        f"{JOURNALS_ENDPOINT}/{favorite_journal.id}/favorite",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["is_favorite"] == False
    
    # Verify changes were persisted
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{favorite_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert result["is_favorite"] == False

def test_delete_journal(app_client, auth_headers, short_journal):
    """Test soft-deleting a journal entry"""
    response = app_client.delete(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["is_deleted"] == True
    
    # Verify journal is not included in regular listing
    response = app_client.get(
        JOURNALS_ENDPOINT,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    journal_ids = [journal["id"] for journal in result["items"]]
    assert str(short_journal.id) not in journal_ids

def test_restore_journal(app_client, auth_headers, deleted_journal):
    """Test restoring a soft-deleted journal entry"""
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{deleted_journal.id}/restore",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert result["is_deleted"] == False
    
    # Verify journal is included in regular listing
    response = app_client.get(
        JOURNALS_ENDPOINT,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    journal_ids = [journal["id"] for journal in result["items"]]
    assert str(deleted_journal.id) in journal_ids

def test_get_journal_emotional_shift(app_client, auth_headers, anxiety_to_calm_journal):
    """Test retrieving emotional shift data for a journal"""
    journal, _, _ = anxiety_to_calm_journal
    
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{journal.id}/emotional-shift",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "pre_emotional_state" in result
    assert "post_emotional_state" in result
    assert "primary_shift" in result
    assert "intensity_change" in result
    assert "insights" in result

def test_get_journal_stats(app_client, auth_headers, multiple_journals):
    """Test retrieving journal usage statistics"""
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/stats",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "total_journals" in result
    assert "total_duration_seconds" in result
    assert "journals_by_emotion" in result
    assert "journals_by_month" in result
    
    # Test with date range parameters to filter statistics
    params = {
        "start_date": (datetime.utcnow() - timedelta(days=30)).isoformat(),
        "end_date": datetime.utcnow().isoformat()
    }
    
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/stats",
        params=params,
        headers=auth_headers
    )
    
    assert response.status_code == 200

def test_export_journal(app_client, auth_headers, short_journal):
    """Test exporting a journal to a downloadable format"""
    export_options = {
        "format": "AAC",
        "include_metadata": True
    }
    
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}/export",
        json=export_options,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "download_url" in result
    assert "format" in result
    assert "file_size_bytes" in result
    
    # Test different export formats to ensure correct format conversion
    export_options["format"] = "MP3"
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}/export",
        json=export_options,
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert result["format"] == "MP3"

def test_get_journal_download_url(app_client, auth_headers, uploaded_journal):
    """Test generating a download URL for a journal audio file"""
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{uploaded_journal.id}/download",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "download_url" in result
    
    # Test with expiration_seconds parameter to customize URL expiration
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{uploaded_journal.id}/download?expiration_seconds=3600",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert "download_url" in result

def test_get_recommended_tools(app_client, auth_headers, anxiety_to_calm_journal):
    """Test retrieving tool recommendations based on journal emotional data"""
    journal, _, _ = anxiety_to_calm_journal
    
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{journal.id}/recommendations",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert isinstance(result, list)
    if len(result) > 0:
        assert "id" in result[0]
        assert "name" in result[0]
        assert "category" in result[0]
        assert "relevance_score" in result[0]
    
    # Test with limit parameter to control number of recommendations
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{journal.id}/recommendations?limit=2",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert len(result) <= 2

def test_sync_journal_to_cloud(app_client, auth_headers, short_journal):
    """Test synchronizing a journal recording to cloud storage"""
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}/sync",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    
    assert "sync_status" in result
    assert "s3_key" in result
    
    # Make GET request to journal to verify is_uploaded is now true
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    result = response.json()
    assert result["is_uploaded"] == True

def test_get_journal_audio(app_client, auth_headers, short_journal):
    """Test retrieving the audio recording for a journal"""
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/{short_journal.id}/audio",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    assert response.headers["Content-Type"] in ["audio/aac", "audio/mpeg"]
    assert len(response.content) > 0

def test_premium_features(app_client, premium_auth_headers, premium_user):
    """Test premium-only features for journal management"""
    # Create test journal data with high-quality audio settings
    journal_data = create_journal_data(premium_user.id, "Premium Journal", 300)
    journal_data["audio_format"] = "MP3"
    journal_data["high_quality_audio"] = True
    
    audio_file, filename = create_test_audio_file()
    
    # Create multipart form data
    data = {
        "data": json.dumps(journal_data),
    }
    files = {
        "audio_file": (filename, audio_file, "audio/mpeg")
    }
    
    # Make request to create premium journal
    response = app_client.post(
        JOURNALS_ENDPOINT,
        data=data,
        files=files,
        headers=premium_auth_headers
    )
    
    assert response.status_code == 201
    result = response.json()
    
    journal_id = result["id"]
    
    # Test premium export options with additional metadata
    export_options = {
        "format": "MP3",
        "include_metadata": True,
        "high_quality": True,
        "include_emotional_data": True
    }
    
    response = app_client.post(
        f"{JOURNALS_ENDPOINT}/{journal_id}/export",
        json=export_options,
        headers=premium_auth_headers
    )
    
    assert response.status_code == 200
    
    # Verify premium users can access extended storage features
    response = app_client.get(
        f"{JOURNALS_ENDPOINT}/stats?include_extended_metrics=true",
        headers=premium_auth_headers
    )
    
    assert response.status_code == 200