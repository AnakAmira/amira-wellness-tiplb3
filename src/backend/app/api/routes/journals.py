"""
API routes for voice journaling functionality in the Amira Wellness application.
Implements endpoints for creating, retrieving, updating, and managing voice journal recordings with emotional check-ins, supporting end-to-end encryption and secure storage integration.
"""
import typing
import uuid
from typing import List, Dict, Any, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Body, Query, Path, Response # fastapi 0.104+
from sqlalchemy.orm import Session # sqlalchemy 2.0+

# Internal imports
from ..db.session import get_db
from ..api.deps import get_current_user, validate_resource_ownership, get_client_rate_limit_key
from ..models.journal import Journal
from ..models.user import User
from ..schemas.journal import JournalCreate, JournalUpdate, Journal as JournalSchema, JournalList, JournalFilter, EmotionalShift, JournalExport, JournalExportResult, JournalStats
from ..services.journal import create_journal, get_journal, get_journal_audio, get_user_journals, get_filtered_journals, update_journal, mark_journal_as_favorite, unmark_journal_as_favorite, delete_journal, restore_journal, get_journal_emotional_shift, get_journal_stats, export_journal, get_journal_download_url, get_recommended_tools_for_journal, sync_journal_to_cloud
from ..services.encryption import get_encryption_key
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException, PermissionDeniedException, ValidationException

# Initialize logger
logger = get_logger(__name__)

# Create router for journal endpoints
router = APIRouter(prefix="/journals", tags=["journals"])

def get_journal_owner_id(db: Session, journal_id: uuid.UUID) -> uuid.UUID:
    """Helper function to get the owner ID of a journal for ownership validation

    Args:
        db: Database session
        journal_id: Journal ID

    Returns:
        User ID of the journal owner
    """
    journal = db.query(Journal).filter(Journal.id == journal_id).first()
    if not journal:
        raise ResourceNotFoundException(resource_type="journal", resource_id=journal_id)
    return journal.user_id

@router.post("/", response_model=JournalSchema, status_code=status.HTTP_201_CREATED, dependencies=[Depends(get_client_rate_limit_key)])
async def create_journal_entry(
    journal_data: JournalCreate = Depends(),
    audio_file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new journal entry

    Creates a new voice journal entry with audio data and emotional check-ins
    """
    try:
        # Get encryption key for the user
        encryption_key = get_encryption_key(db, current_user.id)

        # Read audio file content
        audio_data = await audio_file.read()

        # Create journal entry
        journal_entry = create_journal(db, journal_data, audio_data, encryption_key)

        # Log successful creation
        logger.info(f"Journal entry created successfully: {journal_entry['id']}")
        return journal_entry
    except Exception as e:
        logger.error(f"Error creating journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/", response_model=JournalList, dependencies=[Depends(get_client_rate_limit_key)])
def get_journals(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user's journal entries

    Retrieves a paginated list of journal entries for the current user
    """
    try:
        # Get journal entries for the user
        journals, total = get_user_journals(db, current_user.id, page, page_size)

        # Create response
        response = JournalList(
            items=journals,
            total=total,
            page=page,
            page_size=page_size
        )

        # Log successful retrieval
        logger.info(f"Retrieved {len(journals)} journal entries for user: {current_user.id}")
        return response
    except Exception as e:
        logger.error(f"Error retrieving journal entries: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/filter", response_model=JournalList, dependencies=[Depends(get_client_rate_limit_key)])
def filter_journals(
    filter_params: JournalFilter,
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Filter journal entries

    Retrieves a filtered list of journal entries based on criteria
    """
    try:
        # Get filtered journal entries for the user
        journals, total = get_filtered_journals(db, current_user.id, filter_params, page, page_size)

        # Create response
        response = JournalList(
            items=journals,
            total=total,
            page=page,
            page_size=page_size
        )

        # Log successful retrieval
        logger.info(f"Retrieved {len(journals)} filtered journal entries for user: {current_user.id}")
        return response
    except Exception as e:
        logger.error(f"Error retrieving filtered journal entries: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/{journal_id}", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def get_journal_by_id(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to retrieve"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific journal entry

    Retrieves a specific journal entry by ID
    """
    try:
        # Get journal entry by ID
        journal_entry = get_journal(db, journal_id, current_user.id)

        # Log successful retrieval
        logger.info(f"Retrieved journal entry with ID: {journal_id} for user: {current_user.id}")
        return journal_entry
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error retrieving journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/{journal_id}/audio", response_class=Response, dependencies=[Depends(get_client_rate_limit_key)])
def get_journal_audio_data(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to retrieve audio for"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get journal audio

    Retrieves the audio recording for a specific journal entry
    """
    try:
        # Get encryption key for the user
        encryption_key = get_encryption_key(db, current_user.id)

        # Get journal audio data
        audio_data = get_journal_audio(db, journal_id, current_user.id, encryption_key)

        # Log successful retrieval
        logger.info(f"Retrieved audio for journal entry with ID: {journal_id} for user: {current_user.id}")
        return Response(content=audio_data, media_type="audio/mpeg")
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error retrieving journal audio: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.patch("/{journal_id}", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def update_journal_by_id(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to update"),
    journal_data: JournalUpdate = Body(..., description="Data to update the journal with"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update journal entry

    Updates a specific journal entry by ID
    """
    try:
        # Update journal entry
        updated_journal = update_journal(db, journal_id, journal_data, current_user.id)

        # Log successful update
        logger.info(f"Updated journal entry with ID: {journal_id} for user: {current_user.id}")
        return updated_journal
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error updating journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/{journal_id}/favorite", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def mark_journal_favorite(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to mark as favorite"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark journal as favorite

    Marks a specific journal entry as favorite
    """
    try:
        # Mark journal as favorite
        updated_journal = mark_journal_as_favorite(db, journal_id, current_user.id)

        # Log successful update
        logger.info(f"Marked journal as favorite with ID: {journal_id} for user: {current_user.id}")
        return updated_journal
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error marking journal as favorite: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.delete("/{journal_id}/favorite", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def unmark_journal_favorite(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to unmark as favorite"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Unmark journal as favorite

    Removes a specific journal entry from favorites
    """
    try:
        # Unmark journal as favorite
        updated_journal = unmark_journal_as_favorite(db, journal_id, current_user.id)

        # Log successful update
        logger.info(f"Unmarked journal as favorite with ID: {journal_id} for user: {current_user.id}")
        return updated_journal
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error unmarking journal as favorite: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.delete("/{journal_id}", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def delete_journal_by_id(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to delete"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete journal entry

    Soft deletes a specific journal entry by ID
    """
    try:
        # Delete journal entry
        deleted_journal = delete_journal(db, journal_id, current_user.id)

        # Log successful deletion
        logger.info(f"Deleted journal entry with ID: {journal_id} for user: {current_user.id}")
        return deleted_journal
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error deleting journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/{journal_id}/restore", response_model=JournalSchema, dependencies=[Depends(get_client_rate_limit_key)])
def restore_journal_by_id(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to restore"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Restore deleted journal

    Restores a soft-deleted journal entry
    """
    try:
        # Restore journal entry
        restored_journal = restore_journal(db, journal_id, current_user.id)

        # Log successful restoration
        logger.info(f"Restored journal entry with ID: {journal_id} for user: {current_user.id}")
        return restored_journal
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error restoring journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/{journal_id}/emotional-shift", response_model=EmotionalShift, dependencies=[Depends(get_client_rate_limit_key)])
def get_emotional_shift_data(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to retrieve emotional shift data for"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get emotional shift data

    Retrieves the emotional shift data between pre and post journaling states
    """
    try:
        # Get emotional shift data
        emotional_shift = get_journal_emotional_shift(db, journal_id, current_user.id)

        # Log successful retrieval
        logger.info(f"Retrieved emotional shift data for journal entry with ID: {journal_id} for user: {current_user.id}")
        return emotional_shift
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error retrieving emotional shift data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/stats", response_model=JournalStats, dependencies=[Depends(get_client_rate_limit_key)])
def get_journal_statistics(
    start_date: Optional[datetime] = Query(None, description="Start date for the statistics range"),
    end_date: Optional[datetime] = Query(None, description="End date for the statistics range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get journal statistics

    Retrieves usage statistics for the user's journal entries
    """
    try:
        # Get journal statistics
        journal_stats = get_journal_stats(db, current_user.id, start_date, end_date)

        # Log successful retrieval
        logger.info(f"Retrieved journal statistics for user: {current_user.id}")
        return journal_stats
    except Exception as e:
        logger.error(f"Error retrieving journal statistics: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/{journal_id}/export", response_model=JournalExportResult, dependencies=[Depends(get_client_rate_limit_key)])
def export_journal_entry(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to export"),
    export_options: JournalExport = Body(..., description="Export options"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export journal

    Exports a journal entry to a downloadable format
    """
    try:
        # Get encryption key for the user
        encryption_key = get_encryption_key(db, current_user.id)

        # Export journal entry
        export_result = export_journal(db, journal_id, current_user.id, export_options, encryption_key)

        # Log successful export
        logger.info(f"Exported journal entry with ID: {journal_id} for user: {current_user.id}")
        return export_result
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error exporting journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/{journal_id}/download", response_model=Dict[str, str], dependencies=[Depends(get_client_rate_limit_key)])
def get_download_url_for_journal(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to get download URL for"),
    expiration_seconds: int = Query(3600, description="Expiration time for the download URL in seconds"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get download URL

    Generates a temporary download URL for a journal audio file
    """
    try:
        # Get download URL
        download_url = get_journal_download_url(db, journal_id, current_user.id, expiration_seconds)

        # Log successful retrieval
        logger.info(f"Retrieved download URL for journal entry with ID: {journal_id} for user: {current_user.id}")
        return {"download_url": download_url}
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error retrieving download URL: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/{journal_id}/recommendations", response_model=List[Dict[str, Any]], dependencies=[Depends(get_client_rate_limit_key)])
def get_tool_recommendations_for_journal(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to retrieve recommendations for"),
    limit: int = Query(5, ge=1, le=10, description="Maximum number of recommendations to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get tool recommendations

    Retrieves tool recommendations based on journal emotional data
    """
    try:
        # Get tool recommendations
        recommendations = get_recommended_tools_for_journal(db, journal_id, current_user.id, limit)

        # Log successful retrieval
        logger.info(f"Retrieved tool recommendations for journal entry with ID: {journal_id} for user: {current_user.id}")
        return recommendations
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error retrieving tool recommendations: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/{journal_id}/sync", response_model=Dict[str, Any], dependencies=[Depends(get_client_rate_limit_key)])
def sync_journal_with_cloud(
    journal_id: uuid.UUID = Path(..., description="The ID of the journal to sync"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Sync journal to cloud

    Synchronizes a journal recording to cloud storage
    """
    try:
        # Sync journal to cloud
        sync_result = sync_journal_to_cloud(db, journal_id, current_user.id)

        # Log successful sync
        logger.info(f"Synchronized journal entry with ID: {journal_id} for user: {current_user.id}")
        return sync_result
    except ResourceNotFoundException as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=e.to_dict())
    except PermissionDeniedException as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=e.to_dict())
    except Exception as e:
        logger.error(f"Error syncing journal entry: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))