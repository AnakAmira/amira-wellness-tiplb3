from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from .base import BaseModel
from ..constants.emotions import EmotionContext

class Journal(BaseModel):
    """
    SQLAlchemy model representing a voice journal entry in the Amira Wellness application.
    
    This model stores metadata about voice journal recordings, including references to
    emotional check-ins performed before and after recording, and implements end-to-end
    encryption for privacy.
    """
    
    # User relationship
    user_id = Column(ForeignKey('users.id'), nullable=False)
    
    # Journal metadata
    title = Column(String(255))
    duration_seconds = Column(Integer)
    
    # Storage information
    storage_path = Column(String(255))  # Local path for temporary storage
    s3_key = Column(String(255))        # S3 key for cloud storage
    encryption_iv = Column(Text)        # Initialization vector for encryption
    encryption_tag = Column(Text)       # Authentication tag for encryption
    audio_format = Column(String(255))  # Format of the audio file (AAC, etc.)
    file_size_bytes = Column(Integer)
    
    # Status flags
    is_favorite = Column(Boolean, default=False)
    is_uploaded = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    
    # Table arguments for indexes and constraints
    __table_args__ = (
        Index('idx_journals_user_id', user_id),
        Index('idx_journals_created_at', user_id, "created_at"),
        Index('idx_journals_favorite', user_id, is_favorite),
        CheckConstraint('duration_seconds > 0'),
        CheckConstraint('file_size_bytes >= 0'),
    )
    
    # Relationships
    user = relationship("User", back_populates="journals")
    emotional_checkins = relationship("EmotionalCheckin", back_populates="journal", 
                                    foreign_keys="EmotionalCheckin.related_journal_id")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if a journal is accessible by a specific user
        
        Args:
            user_id (UUID): The user ID to check access for
            
        Returns:
            bool: True if the journal is accessible by the user, False otherwise
        """
        return self.user_id == user_id
    
    def mark_as_favorite(self):
        """
        Marks the journal as a favorite
        """
        self.is_favorite = True
    
    def unmark_as_favorite(self):
        """
        Removes the journal from favorites
        """
        self.is_favorite = False
    
    def mark_as_uploaded(self, s3_key):
        """
        Marks the journal as uploaded to cloud storage
        
        Args:
            s3_key (str): The S3 key where the recording is stored
        """
        self.is_uploaded = True
        self.s3_key = s3_key
    
    def soft_delete(self):
        """
        Marks the journal as deleted without removing from database
        """
        self.is_deleted = True
    
    def restore(self):
        """
        Restores a soft-deleted journal
        """
        self.is_deleted = False
    
    def get_emotional_shift(self):
        """
        Calculates the emotional shift between pre and post check-ins
        
        Returns:
            dict: Dictionary containing emotional shift data or None if check-ins are missing
        """
        pre_checkin = next((c for c in self.emotional_checkins 
                          if c.context == EmotionContext.PRE_JOURNALING.value), None)
        post_checkin = next((c for c in self.emotional_checkins 
                           if c.context == EmotionContext.POST_JOURNALING.value), None)
        
        if not pre_checkin or not post_checkin:
            return None
        
        return {
            'pre_emotion': pre_checkin.emotion_type,
            'pre_intensity': pre_checkin.intensity,
            'post_emotion': post_checkin.emotion_type,
            'post_intensity': post_checkin.intensity,
            'emotion_changed': pre_checkin.emotion_type != post_checkin.emotion_type,
            'intensity_change': post_checkin.intensity - pre_checkin.intensity
        }
    
    def get_encryption_details(self):
        """
        Gets encryption details for secure audio retrieval
        
        Returns:
            dict: Dictionary with encryption IV and tag
        """
        return {
            'encryption_iv': self.encryption_iv,
            'encryption_tag': self.encryption_tag
        }