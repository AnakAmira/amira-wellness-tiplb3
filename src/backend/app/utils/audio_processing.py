"""
Audio Processing Module

This module provides utilities for processing audio recordings in the Amira Wellness
application. It handles audio format conversion, compression, quality analysis,
and metadata extraction to support the voice journaling feature.
"""

import os  # standard library
import io  # standard library
import tempfile  # standard library
import typing  # standard library
from typing import Dict, List, Optional, Tuple, Union, BinaryIO  # standard library

import pydub  # pydub 0.25.1+
from pydub import AudioSegment  # pydub 0.25.1+
import numpy as np  # numpy 1.20.0+

from ..core.logging import logger  # internal
from ..core.config import settings  # internal
from ..constants.error_codes import ErrorCategory  # internal

# Default audio parameters based on specifications
DEFAULT_AUDIO_FORMAT = "aac"
DEFAULT_SAMPLE_RATE = 44100  # 44.1 kHz
DEFAULT_BIT_RATE = 128000  # 128 kbps
DEFAULT_CHANNELS = 1  # mono

# Supported audio formats
SUPPORTED_FORMATS = ["aac", "mp3", "wav", "m4a", "ogg"]

# Temporary directory for audio processing
TEMP_DIR = os.path.join(tempfile.gettempdir(), 'amira_audio')


def process_journal_audio(
    audio_data: bytes,
    source_format: str,
    target_format: str = DEFAULT_AUDIO_FORMAT,
    target_sample_rate: int = DEFAULT_SAMPLE_RATE,
    target_bit_rate: int = DEFAULT_BIT_RATE,
    target_channels: int = DEFAULT_CHANNELS
) -> Dict:
    """
    Processes a raw audio recording for optimal storage and playback in the journal feature.
    
    Args:
        audio_data: Raw audio data bytes
        source_format: Source audio format (e.g., 'wav', 'mp3')
        target_format: Target audio format for storage (default: AAC)
        target_sample_rate: Target sample rate in Hz (default: 44.1 kHz)
        target_bit_rate: Target bit rate in bps (default: 128 kbps)
        target_channels: Target number of channels (default: 1 for mono)
        
    Returns:
        Dict containing processed audio data and metadata:
        {
            'audio': bytes,
            'format': str,
            'duration_ms': int,
            'sample_rate': int,
            'bit_rate': int,
            'channels': int,
            'file_size': int
        }
        
    Raises:
        AudioProcessingError: If audio processing fails
        AudioFormatError: If format is unsupported
    """
    try:
        logger.info(f"Processing journal audio from {source_format} to {target_format}")
        
        # Validate input parameters
        if source_format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported source format: {source_format}")
            raise AudioFormatError(f"Unsupported source format: {source_format}")
        
        if target_format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported target format: {target_format}")
            raise AudioFormatError(f"Unsupported target format: {target_format}")
        
        # Create an AudioSegment from the input data
        audio = _create_audio_segment(audio_data, source_format)
        
        # Normalize audio levels
        audio = normalize_audio(audio)
        
        # Apply noise reduction if needed (based on audio quality analysis)
        quality_analyzer = AudioQualityAnalyzer()
        quality_metrics = quality_analyzer.analyze(audio)
        
        if quality_metrics['snr'] < 15.0:  # Apply noise reduction if SNR is low
            logger.debug(f"Applying noise reduction (SNR: {quality_metrics['snr']})")
            audio = reduce_noise(audio)
        
        # Convert to target format with specified parameters
        conversion_options = {
            'sample_rate': target_sample_rate,
            'bit_rate': target_bit_rate,
            'channels': target_channels
        }
        
        processed_audio = _export_audio_segment(audio, target_format, conversion_options)
        
        # Get metadata about the processed audio
        metadata = {
            'format': target_format,
            'duration_ms': len(audio),
            'sample_rate': target_sample_rate,
            'bit_rate': target_bit_rate,
            'channels': target_channels,
            'file_size': len(processed_audio),
        }
        
        logger.info(f"Audio processing completed: {metadata['duration_ms']}ms, {metadata['file_size']} bytes")
        
        return {
            'audio': processed_audio,
            **metadata
        }
    
    except AudioFormatError:
        # Re-raise the specific format error
        raise
    except Exception as e:
        logger.error(f"Audio processing failed: {str(e)}")
        raise AudioProcessingError(f"Failed to process audio: {str(e)}")


def convert_audio_format(
    audio_data: bytes,
    source_format: str,
    target_format: str,
    conversion_options: Dict = None
) -> bytes:
    """
    Converts audio data from one format to another.
    
    Args:
        audio_data: Raw audio data bytes
        source_format: Source audio format (e.g., 'wav', 'mp3')
        target_format: Target audio format (e.g., 'aac', 'mp3')
        conversion_options: Dictionary of conversion options including:
            - sample_rate: Sample rate in Hz
            - bit_rate: Bit rate in bps
            - channels: Number of channels
            
    Returns:
        Converted audio data as bytes
        
    Raises:
        AudioFormatError: If format is unsupported
        AudioProcessingError: If conversion fails
    """
    try:
        logger.info(f"Converting audio from {source_format} to {target_format}")
        
        # Validate formats
        if source_format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported source format: {source_format}")
            raise AudioFormatError(f"Unsupported source format: {source_format}")
        
        if target_format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported target format: {target_format}")
            raise AudioFormatError(f"Unsupported target format: {target_format}")
        
        # Set default conversion options if not provided
        if conversion_options is None:
            conversion_options = {
                'sample_rate': DEFAULT_SAMPLE_RATE,
                'bit_rate': DEFAULT_BIT_RATE,
                'channels': DEFAULT_CHANNELS
            }
        
        # Create an AudioSegment from the input data
        audio = _create_audio_segment(audio_data, source_format)
        
        # Apply conversion options
        if 'sample_rate' in conversion_options:
            audio = audio.set_frame_rate(conversion_options['sample_rate'])
        
        if 'channels' in conversion_options:
            if conversion_options['channels'] == 1 and audio.channels > 1:
                audio = audio.set_channels(1)
            elif conversion_options['channels'] == 2 and audio.channels == 1:
                audio = audio.set_channels(2)
        
        # Export to target format
        converted_audio = _export_audio_segment(audio, target_format, conversion_options)
        
        logger.info(f"Audio conversion completed: {len(converted_audio)} bytes")
        
        return converted_audio
    
    except AudioFormatError:
        # Re-raise the specific format error
        raise
    except Exception as e:
        logger.error(f"Audio conversion failed: {str(e)}")
        raise AudioProcessingError(f"Failed to convert audio: {str(e)}")


def get_audio_metadata(
    audio_data: bytes,
    format: str
) -> Dict:
    """
    Extracts metadata from audio data including duration, format, and quality metrics.
    
    Args:
        audio_data: Raw audio data bytes
        format: Audio format (e.g., 'wav', 'mp3')
        
    Returns:
        Dictionary containing audio metadata:
        {
            'format': str,
            'duration_ms': int,
            'sample_rate': int,
            'channels': int,
            'bit_rate': int,
            'file_size': int,
            'quality': {
                'snr': float,
                'dBFS': float,
                'silent_sections': List[Tuple[int, int]],
                'frequency_distribution': Dict
            }
        }
        
    Raises:
        AudioFormatError: If format is unsupported
        AudioProcessingError: If metadata extraction fails
    """
    try:
        logger.info(f"Extracting metadata from {format} audio")
        
        # Validate format
        if format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported audio format: {format}")
            raise AudioFormatError(f"Unsupported audio format: {format}")
        
        # Create an AudioSegment from the input data
        audio = _create_audio_segment(audio_data, format)
        
        # Extract basic metadata
        metadata = {
            'format': format,
            'duration_ms': len(audio),
            'sample_rate': audio.frame_rate,
            'channels': audio.channels,
            'bit_rate': getattr(audio, 'frame_width', 0) * 8 * audio.frame_rate,
            'file_size': len(audio_data),
        }
        
        # Analyze audio quality
        quality_analyzer = AudioQualityAnalyzer()
        quality_metrics = quality_analyzer.analyze(audio)
        metadata['quality'] = quality_metrics
        
        logger.info(f"Metadata extraction completed: {metadata['duration_ms']}ms, {metadata['file_size']} bytes")
        
        return metadata
    
    except AudioFormatError:
        # Re-raise the specific format error
        raise
    except Exception as e:
        logger.error(f"Metadata extraction failed: {str(e)}")
        raise AudioProcessingError(f"Failed to extract audio metadata: {str(e)}")


def normalize_audio(
    audio: AudioSegment,
    target_dBFS: float = -20.0
) -> AudioSegment:
    """
    Normalizes audio levels for consistent volume.
    
    Args:
        audio: AudioSegment to normalize
        target_dBFS: Target dBFS level (default: -20.0)
        
    Returns:
        Normalized AudioSegment
    """
    try:
        logger.debug(f"Normalizing audio from {audio.dBFS:.2f} dBFS to {target_dBFS:.2f} dBFS")
        
        # Calculate the gain needed to reach target dBFS
        gain = target_dBFS - audio.dBFS
        
        # Apply gain to reach target level
        normalized_audio = audio.apply_gain(gain)
        
        logger.debug(f"Audio normalization completed: {normalized_audio.dBFS:.2f} dBFS")
        
        return normalized_audio
    
    except Exception as e:
        logger.error(f"Audio normalization failed: {str(e)}")
        raise AudioProcessingError(f"Failed to normalize audio: {str(e)}")


def reduce_noise(
    audio: AudioSegment,
    reduction_amount: float = 0.3
) -> AudioSegment:
    """
    Applies noise reduction to improve audio clarity.
    
    Args:
        audio: AudioSegment to process
        reduction_amount: Amount of noise reduction to apply (0.0-1.0)
        
    Returns:
        Noise-reduced AudioSegment
    """
    try:
        logger.debug(f"Applying noise reduction with amount {reduction_amount}")
        
        # Convert audio to numpy array for processing
        samples = np.array(audio.get_array_of_samples())
        
        # Convert to float32 for processing
        samples = samples.astype(np.float32)
        if audio.channels > 1:
            # Reshape for multi-channel audio
            samples = samples.reshape((-1, audio.channels))
        
        # Simple spectral gating noise reduction
        # This is a simplified version; in a real implementation,
        # you would use a more sophisticated algorithm
        
        # 1. Identify noise profile from the quietest parts of the audio
        # For simplicity, we'll assume the first 500ms is noise
        if len(samples) > audio.frame_rate // 2:
            noise_sample = samples[:audio.frame_rate // 2]
        else:
            noise_sample = samples[:len(samples) // 10]  # Use 10% of audio if very short
        
        # 2. Calculate noise threshold
        if audio.channels > 1:
            noise_threshold = np.mean(np.abs(noise_sample), axis=0) * 2
        else:
            noise_threshold = np.mean(np.abs(noise_sample)) * 2
        
        # 3. Apply noise gate
        if audio.channels > 1:
            mask = np.abs(samples) < noise_threshold.reshape(1, -1)
            samples[mask] *= (1.0 - reduction_amount)
        else:
            mask = np.abs(samples) < noise_threshold
            samples[mask] *= (1.0 - reduction_amount)
        
        # Convert back to original data type
        samples = samples.astype(audio.array_type)
        
        # Create a new AudioSegment
        reduced_audio = AudioSegment(
            samples.tobytes(),
            frame_rate=audio.frame_rate,
            sample_width=audio.sample_width,
            channels=audio.channels
        )
        
        logger.debug("Noise reduction completed")
        
        return reduced_audio
    
    except Exception as e:
        logger.error(f"Noise reduction failed: {str(e)}")
        raise AudioProcessingError(f"Failed to reduce noise: {str(e)}")


def validate_audio_file(
    audio_data: bytes,
    format: str,
    min_duration_ms: int = 1000,  # 1 second
    max_duration_ms: int = 15 * 60 * 1000,  # 15 minutes
    max_file_size_bytes: int = 50 * 1024 * 1024  # 50 MB
) -> bool:
    """
    Validates that an audio file meets the required specifications.
    
    Args:
        audio_data: Raw audio data bytes
        format: Audio format (e.g., 'wav', 'mp3')
        min_duration_ms: Minimum allowed duration in milliseconds
        max_duration_ms: Maximum allowed duration in milliseconds
        max_file_size_bytes: Maximum allowed file size in bytes
        
    Returns:
        True if audio file is valid, False otherwise
    """
    try:
        logger.debug(f"Validating {format} audio file ({len(audio_data)} bytes)")
        
        # Check if format is supported
        if format not in SUPPORTED_FORMATS:
            logger.error(f"Unsupported audio format: {format}")
            return False
        
        # Check file size
        if len(audio_data) > max_file_size_bytes:
            logger.error(f"Audio file too large: {len(audio_data)} bytes > {max_file_size_bytes} bytes")
            return False
        
        # Try to create an AudioSegment to verify file integrity
        try:
            audio = _create_audio_segment(audio_data, format)
        except Exception as e:
            logger.error(f"Invalid audio file: {str(e)}")
            return False
        
        # Check duration
        duration_ms = len(audio)
        if duration_ms < min_duration_ms:
            logger.error(f"Audio duration too short: {duration_ms}ms < {min_duration_ms}ms")
            return False
        
        if duration_ms > max_duration_ms:
            logger.error(f"Audio duration too long: {duration_ms}ms > {max_duration_ms}ms")
            return False
        
        logger.debug(f"Audio file validation passed: {duration_ms}ms, {len(audio_data)} bytes")
        
        return True
    
    except Exception as e:
        logger.error(f"Audio validation failed: {str(e)}")
        return False


class AudioProcessor:
    """
    Class for processing audio recordings with configurable parameters.
    """
    
    def __init__(
        self,
        target_format: str = DEFAULT_AUDIO_FORMAT,
        target_sample_rate: int = DEFAULT_SAMPLE_RATE,
        target_bit_rate: int = DEFAULT_BIT_RATE,
        target_channels: int = DEFAULT_CHANNELS,
        apply_normalization: bool = True,
        apply_noise_reduction: bool = True
    ):
        """
        Initializes the AudioProcessor with processing parameters.
        
        Args:
            target_format: Target audio format (default: AAC)
            target_sample_rate: Target sample rate in Hz (default: 44.1 kHz)
            target_bit_rate: Target bit rate in bps (default: 128 kbps)
            target_channels: Target number of channels (default: 1 for mono)
            apply_normalization: Whether to apply audio normalization (default: True)
            apply_noise_reduction: Whether to apply noise reduction (default: True)
        """
        # Validate and set parameters
        if target_format not in SUPPORTED_FORMATS:
            raise AudioFormatError(f"Unsupported target format: {target_format}")
        
        if target_sample_rate <= 0:
            raise ValueError("Sample rate must be a positive integer")
        
        if target_bit_rate <= 0:
            raise ValueError("Bit rate must be a positive integer")
        
        if target_channels not in [1, 2]:
            raise ValueError("Channels must be either 1 (mono) or 2 (stereo)")
        
        self._target_format = target_format
        self._target_sample_rate = target_sample_rate
        self._target_bit_rate = target_bit_rate
        self._target_channels = target_channels
        self._apply_normalization = apply_normalization
        self._apply_noise_reduction = apply_noise_reduction
        
        logger.debug(f"AudioProcessor initialized with format={target_format}, "
                    f"sample_rate={target_sample_rate}, bit_rate={target_bit_rate}, "
                    f"channels={target_channels}, normalization={apply_normalization}, "
                    f"noise_reduction={apply_noise_reduction}")
    
    def process(
        self,
        audio_data: bytes,
        source_format: str
    ) -> Dict:
        """
        Processes audio data according to configured parameters.
        
        Args:
            audio_data: Raw audio data bytes
            source_format: Source audio format (e.g., 'wav', 'mp3')
            
        Returns:
            Dict containing processed audio data and metadata
            
        Raises:
            AudioFormatError: If format is unsupported
            AudioProcessingError: If processing fails
        """
        try:
            logger.info(f"Processing audio from {source_format} to {self._target_format}")
            
            # Validate source format
            if source_format not in SUPPORTED_FORMATS:
                logger.error(f"Unsupported source format: {source_format}")
                raise AudioFormatError(f"Unsupported source format: {source_format}")
            
            # Create an AudioSegment from the input data
            audio = _create_audio_segment(audio_data, source_format)
            
            # Apply normalization if enabled
            if self._apply_normalization:
                audio = normalize_audio(audio)
            
            # Apply noise reduction if enabled
            if self._apply_noise_reduction:
                # Only apply noise reduction if SNR is low
                quality_analyzer = AudioQualityAnalyzer()
                quality_metrics = quality_analyzer.analyze(audio)
                
                if quality_metrics['snr'] < 15.0:
                    logger.debug(f"Applying noise reduction (SNR: {quality_metrics['snr']})")
                    audio = reduce_noise(audio)
            
            # Convert to target format with configured parameters
            conversion_options = {
                'sample_rate': self._target_sample_rate,
                'bit_rate': self._target_bit_rate,
                'channels': self._target_channels
            }
            
            processed_audio = _export_audio_segment(audio, self._target_format, conversion_options)
            
            # Get metadata about the processed audio
            metadata = {
                'format': self._target_format,
                'duration_ms': len(audio),
                'sample_rate': self._target_sample_rate,
                'bit_rate': self._target_bit_rate,
                'channels': self._target_channels,
                'file_size': len(processed_audio),
            }
            
            logger.info(f"Audio processing completed: {metadata['duration_ms']}ms, {metadata['file_size']} bytes")
            
            return {
                'audio': processed_audio,
                **metadata
            }
        
        except AudioFormatError:
            # Re-raise the specific format error
            raise
        except Exception as e:
            logger.error(f"Audio processing failed: {str(e)}")
            raise AudioProcessingError(f"Failed to process audio: {str(e)}")
    
    def batch_process(
        self,
        audio_files: List[Dict]
    ) -> List[Dict]:
        """
        Processes multiple audio files with the same configuration.
        
        Args:
            audio_files: List of dictionaries containing:
                - 'audio': Raw audio data bytes
                - 'format': Source audio format
                
        Returns:
            List of dictionaries containing processed audio data and metadata
            
        Raises:
            AudioProcessingError: If batch processing fails
        """
        try:
            logger.info(f"Batch processing {len(audio_files)} audio files")
            
            results = []
            for i, audio_file in enumerate(audio_files):
                try:
                    if 'audio' not in audio_file or 'format' not in audio_file:
                        logger.error(f"Missing required fields in audio file {i}")
                        raise ValueError(f"Missing required fields in audio file {i}")
                    
                    result = self.process(audio_file['audio'], audio_file['format'])
                    results.append(result)
                except Exception as e:
                    logger.error(f"Failed to process audio file {i}: {str(e)}")
                    # Add error information to the result
                    results.append({
                        'error': str(e),
                        'index': i
                    })
            
            logger.info(f"Batch processing completed: {len(results)} files")
            
            return results
        
        except Exception as e:
            logger.error(f"Batch processing failed: {str(e)}")
            raise AudioProcessingError(f"Failed to batch process audio files: {str(e)}")
    
    def set_target_format(self, format: str) -> None:
        """
        Sets the target audio format.
        
        Args:
            format: Target audio format
            
        Raises:
            AudioFormatError: If format is unsupported
        """
        if format not in SUPPORTED_FORMATS:
            raise AudioFormatError(f"Unsupported target format: {format}")
        
        self._target_format = format
        logger.debug(f"Target format set to {format}")
    
    def set_target_sample_rate(self, sample_rate: int) -> None:
        """
        Sets the target sample rate.
        
        Args:
            sample_rate: Target sample rate in Hz
            
        Raises:
            ValueError: If sample_rate is not a positive integer
        """
        if sample_rate <= 0:
            raise ValueError("Sample rate must be a positive integer")
        
        self._target_sample_rate = sample_rate
        logger.debug(f"Target sample rate set to {sample_rate} Hz")
    
    def set_target_bit_rate(self, bit_rate: int) -> None:
        """
        Sets the target bit rate.
        
        Args:
            bit_rate: Target bit rate in bps
            
        Raises:
            ValueError: If bit_rate is not a positive integer
        """
        if bit_rate <= 0:
            raise ValueError("Bit rate must be a positive integer")
        
        self._target_bit_rate = bit_rate
        logger.debug(f"Target bit rate set to {bit_rate} bps")
    
    def set_target_channels(self, channels: int) -> None:
        """
        Sets the target number of audio channels.
        
        Args:
            channels: Target number of channels (1 for mono, 2 for stereo)
            
        Raises:
            ValueError: If channels is not 1 or 2
        """
        if channels not in [1, 2]:
            raise ValueError("Channels must be either 1 (mono) or 2 (stereo)")
        
        self._target_channels = channels
        logger.debug(f"Target channels set to {channels}")
    
    def enable_normalization(self) -> None:
        """Enables audio normalization."""
        self._apply_normalization = True
        logger.debug("Audio normalization enabled")
    
    def disable_normalization(self) -> None:
        """Disables audio normalization."""
        self._apply_normalization = False
        logger.debug("Audio normalization disabled")
    
    def enable_noise_reduction(self) -> None:
        """Enables noise reduction."""
        self._apply_noise_reduction = True
        logger.debug("Noise reduction enabled")
    
    def disable_noise_reduction(self) -> None:
        """Disables noise reduction."""
        self._apply_noise_reduction = False
        logger.debug("Noise reduction disabled")


class AudioQualityAnalyzer:
    """
    Class for analyzing audio quality metrics.
    """
    
    def __init__(self):
        """
        Initializes the AudioQualityAnalyzer.
        """
        logger.debug("AudioQualityAnalyzer initialized")
    
    def analyze(self, audio: AudioSegment) -> Dict:
        """
        Analyzes audio data and returns quality metrics.
        
        Args:
            audio: AudioSegment to analyze
            
        Returns:
            Dictionary containing quality metrics:
            {
                'snr': float,  # Signal-to-noise ratio in dB
                'dBFS': float,  # Volume level in dB relative to full scale
                'silent_sections': List[Tuple[int, int]],  # List of (start_ms, end_ms) tuples
                'frequency_distribution': Dict  # Frequency distribution data
            }
        """
        try:
            logger.debug("Analyzing audio quality")
            
            # Calculate SNR (signal-to-noise ratio)
            snr = self.calculate_snr(audio)
            
            # Get volume level (dBFS - decibels relative to full scale)
            dBFS = audio.dBFS
            
            # Detect silent sections
            silent_sections = self.detect_silence(audio)
            
            # Analyze frequency distribution
            freq_dist = self.analyze_frequency_distribution(audio)
            
            # Compile quality metrics
            quality_metrics = {
                'snr': snr,
                'dBFS': dBFS,
                'silent_sections': silent_sections,
                'frequency_distribution': freq_dist
            }
            
            logger.debug(f"Audio quality analysis completed: SNR={snr:.2f}dB, dBFS={dBFS:.2f}dB")
            
            return quality_metrics
        
        except Exception as e:
            logger.error(f"Audio quality analysis failed: {str(e)}")
            # Return a minimal set of metrics if analysis fails
            return {
                'snr': 0.0,
                'dBFS': audio.dBFS if hasattr(audio, 'dBFS') else 0.0,
                'silent_sections': [],
                'frequency_distribution': {}
            }
    
    def calculate_snr(self, audio: AudioSegment) -> float:
        """
        Calculates signal-to-noise ratio of audio.
        
        Args:
            audio: AudioSegment to analyze
            
        Returns:
            Signal-to-noise ratio in dB
        """
        try:
            # Convert audio to numpy array
            samples = np.array(audio.get_array_of_samples())
            samples = samples.astype(np.float32)
            
            if audio.channels > 1:
                # For multi-channel, reshape and calculate for each channel
                samples = samples.reshape((-1, audio.channels))
                
                # Calculate per-channel SNR and average
                channel_snrs = []
                for ch in range(audio.channels):
                    channel_samples = samples[:, ch]
                    # Estimate signal power
                    signal_power = np.mean(channel_samples ** 2)
                    # Estimate noise power (using first 500ms or 10% as noise)
                    if len(channel_samples) > audio.frame_rate // 2:
                        noise_sample = channel_samples[:audio.frame_rate // 2]
                    else:
                        noise_sample = channel_samples[:len(channel_samples) // 10]
                    noise_power = np.mean(noise_sample ** 2)
                    
                    # Avoid division by zero
                    if noise_power > 0:
                        snr = 10 * np.log10(signal_power / noise_power)
                    else:
                        snr = 100.0  # Arbitrary high value for very clean signal
                    
                    channel_snrs.append(snr)
                
                # Return average SNR across channels
                return float(np.mean(channel_snrs))
            else:
                # Mono audio processing
                # Estimate signal power
                signal_power = np.mean(samples ** 2)
                # Estimate noise power (using first 500ms or 10% as noise)
                if len(samples) > audio.frame_rate // 2:
                    noise_sample = samples[:audio.frame_rate // 2]
                else:
                    noise_sample = samples[:len(samples) // 10]
                noise_power = np.mean(noise_sample ** 2)
                
                # Avoid division by zero
                if noise_power > 0:
                    snr = 10 * np.log10(signal_power / noise_power)
                else:
                    snr = 100.0  # Arbitrary high value for very clean signal
                
                return float(snr)
        
        except Exception as e:
            logger.error(f"SNR calculation failed: {str(e)}")
            return 0.0  # Default to 0 on error
    
    def detect_silence(
        self,
        audio: AudioSegment,
        min_silence_len: int = 500,  # 500ms
        silence_thresh: int = -40  # -40 dBFS
    ) -> List[Tuple[int, int]]:
        """
        Detects silent periods in audio.
        
        Args:
            audio: AudioSegment to analyze
            min_silence_len: Minimum silence length in ms
            silence_thresh: Silence threshold in dBFS
            
        Returns:
            List of silent periods as (start_ms, end_ms) tuples
        """
        try:
            # Use pydub's built-in silence detection
            silence_ranges = pydub.silence.detect_silence(
                audio,
                min_silence_len=min_silence_len,
                silence_thresh=silence_thresh
            )
            
            # Convert from milliseconds
            silence_ranges = [(start, end) for start, end in silence_ranges]
            
            logger.debug(f"Detected {len(silence_ranges)} silent sections")
            
            return silence_ranges
        
        except Exception as e:
            logger.error(f"Silence detection failed: {str(e)}")
            return []  # Return empty list on error
    
    def analyze_frequency_distribution(self, audio: AudioSegment) -> Dict:
        """
        Analyzes frequency distribution of audio.
        
        Args:
            audio: AudioSegment to analyze
            
        Returns:
            Dictionary with frequency analysis results
        """
        try:
            # Convert audio to numpy array
            samples = np.array(audio.get_array_of_samples())
            samples = samples.astype(np.float32)
            
            # Handle multi-channel audio - we'll analyze the first channel
            if audio.channels > 1:
                samples = samples.reshape((-1, audio.channels))
                samples = samples[:, 0]  # Take first channel
            
            # Perform FFT
            n = len(samples)
            fft_result = np.fft.rfft(samples)
            fft_freq = np.fft.rfftfreq(n, 1 / audio.frame_rate)
            magnitude = np.abs(fft_result)
            
            # Define frequency bands
            bands = {
                'sub_bass': (20, 60),
                'bass': (60, 250),
                'low_mid': (250, 500),
                'mid': (500, 2000),
                'high_mid': (2000, 4000),
                'high': (4000, 8000),
                'very_high': (8000, 20000)
            }
            
            # Calculate energy in each band
            band_energy = {}
            for band_name, (low_freq, high_freq) in bands.items():
                # Find FFT indices corresponding to frequency range
                indices = np.where((fft_freq >= low_freq) & (fft_freq <= high_freq))[0]
                if len(indices) > 0:
                    # Calculate average energy in the band
                    band_energy[band_name] = float(np.mean(magnitude[indices]))
                else:
                    band_energy[band_name] = 0.0
            
            # Normalize to percentages
            total_energy = sum(band_energy.values())
            if total_energy > 0:
                normalized_energy = {band: energy / total_energy * 100
                                    for band, energy in band_energy.items()}
            else:
                normalized_energy = {band: 0.0 for band in band_energy}
            
            # Find dominant frequency ranges
            dominant_bands = sorted(normalized_energy.items(), key=lambda x: x[1], reverse=True)
            
            # Prepare result
            frequency_analysis = {
                'band_energy': band_energy,
                'normalized_energy': normalized_energy,
                'dominant_bands': [band for band, _ in dominant_bands[:3]]  # Top 3 dominant bands
            }
            
            logger.debug(f"Frequency analysis completed: dominant bands={frequency_analysis['dominant_bands']}")
            
            return frequency_analysis
        
        except Exception as e:
            logger.error(f"Frequency analysis failed: {str(e)}")
            return {
                'band_energy': {},
                'normalized_energy': {},
                'dominant_bands': []
            }  # Return empty analysis on error
    
    def get_quality_score(self, audio: AudioSegment) -> float:
        """
        Calculates an overall quality score for audio.
        
        Args:
            audio: AudioSegment to analyze
            
        Returns:
            Quality score between 0.0 and 1.0
        """
        try:
            # Analyze audio to get metrics
            metrics = self.analyze(audio)
            
            # Define weights for different factors
            weights = {
                'snr': 0.5,          # Signal-to-noise ratio (higher is better)
                'volume': 0.2,        # Volume level (mid-range is better)
                'silence': 0.1,       # Amount of silence (some silence is normal)
                'frequency': 0.2      # Frequency distribution (speech range is better)
            }
            
            # Calculate score components
            
            # SNR score: 0 for SNR <= 0, 1 for SNR >= 30
            snr_score = min(1.0, max(0.0, metrics['snr'] / 30.0)) if 'snr' in metrics else 0.0
            
            # Volume score: 1.0 for -18 to -12 dBFS, decreasing for extremes
            volume = metrics.get('dBFS', -60)
            if -18 <= volume <= -12:
                volume_score = 1.0
            elif volume < -50:  # Too quiet
                volume_score = 0.0
            elif volume > -6:   # Too loud
                volume_score = 0.0
            elif volume < -18:  # Quieter side
                volume_score = 1.0 - min(1.0, (-18 - volume) / 32.0)
            else:               # Louder side
                volume_score = 1.0 - min(1.0, (volume + 12) / 6.0)
            
            # Silence score: Penalize too much silence
            silent_ratio = 0.0
            if 'silent_sections' in metrics:
                total_silence_ms = sum(end - start for start, end in metrics['silent_sections'])
                total_duration_ms = len(audio)
                silent_ratio = total_silence_ms / total_duration_ms if total_duration_ms > 0 else 0.0
            
            # Ideal: 10-20% silence
            if 0.1 <= silent_ratio <= 0.2:
                silence_score = 1.0
            elif silent_ratio > 0.5:  # Too much silence
                silence_score = 0.0
            elif silent_ratio < 0.05:  # Too little silence (continuous speaking)
                silence_score = 0.5
            elif silent_ratio > 0.2:  # More silence than ideal
                silence_score = 1.0 - min(1.0, (silent_ratio - 0.2) / 0.3)
            else:  # Less silence than ideal
                silence_score = 0.5 + (silent_ratio / 0.1) * 0.5
            
            # Frequency score: Check if dominant bands are in speech range
            speech_bands = ['low_mid', 'mid', 'high_mid']
            freq_dist = metrics.get('frequency_distribution', {})
            dominant_bands = freq_dist.get('dominant_bands', [])
            
            if dominant_bands:
                speech_band_count = sum(1 for band in dominant_bands if band in speech_bands)
                frequency_score = speech_band_count / len(dominant_bands)
            else:
                frequency_score = 0.5  # Default if no data
            
            # Calculate weighted score
            quality_score = (
                weights['snr'] * snr_score +
                weights['volume'] * volume_score +
                weights['silence'] * silence_score +
                weights['frequency'] * frequency_score
            )
            
            logger.debug(f"Audio quality score: {quality_score:.2f}")
            
            return quality_score
        
        except Exception as e:
            logger.error(f"Quality score calculation failed: {str(e)}")
            return 0.5  # Default to mid-range on error


class AudioProcessingError(Exception):
    """
    Exception raised when audio processing operations fail.
    """
    
    def __init__(self, message: str, error_code: str = "SYS_AUDIO_PROCESSING_ERROR"):
        """
        Initializes the AudioProcessingError with error details.
        
        Args:
            message: Error message
            error_code: Error code identifier
        """
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.category = ErrorCategory.SYSTEM


class AudioFormatError(AudioProcessingError):
    """
    Exception raised when audio format operations fail.
    """
    
    def __init__(self, message: str):
        """
        Initializes the AudioFormatError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message, "SYS_AUDIO_FORMAT_ERROR")


class AudioQualityError(AudioProcessingError):
    """
    Exception raised when audio quality is below acceptable threshold.
    """
    
    def __init__(self, message: str):
        """
        Initializes the AudioQualityError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message, "SYS_AUDIO_QUALITY_ERROR")


# Helper functions
def _create_audio_segment(audio_data: bytes, format: str) -> AudioSegment:
    """
    Creates an AudioSegment from raw bytes data.
    
    Args:
        audio_data: Raw audio data bytes
        format: Audio format (e.g., 'wav', 'mp3')
        
    Returns:
        AudioSegment object
        
    Raises:
        AudioFormatError: If format is unsupported or data is invalid
    """
    try:
        # Ensure temp directory exists
        os.makedirs(TEMP_DIR, exist_ok=True)
        
        # Create a temporary file for reading the audio data
        with tempfile.NamedTemporaryFile(suffix=f'.{format}', dir=TEMP_DIR, delete=False) as temp_file:
            temp_file.write(audio_data)
            temp_file_path = temp_file.name
        
        try:
            # Load the audio file using pydub
            audio = AudioSegment.from_file(temp_file_path, format=format)
            return audio
        finally:
            # Clean up the temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
    
    except Exception as e:
        logger.error(f"Failed to create AudioSegment: {str(e)}")
        raise AudioFormatError(f"Failed to create AudioSegment: {str(e)}")


def _export_audio_segment(
    audio: AudioSegment,
    format: str,
    options: Dict = None
) -> bytes:
    """
    Exports an AudioSegment to bytes in the specified format.
    
    Args:
        audio: AudioSegment to export
        format: Target format (e.g., 'wav', 'mp3')
        options: Export options including sample_rate, bit_rate, channels
        
    Returns:
        Audio data as bytes
        
    Raises:
        AudioProcessingError: If export fails
    """
    try:
        # Set default options if not provided
        if options is None:
            options = {}
        
        # Configure export parameters
        export_params = {}
        
        if format == 'mp3':
            export_params['format'] = 'mp3'
            if 'bit_rate' in options:
                export_params['bitrate'] = str(options['bit_rate'])
        elif format == 'aac':
            export_params['format'] = 'adts'  # AAC is typically in ADTS container
            if 'bit_rate' in options:
                export_params['bitrate'] = str(options['bit_rate'])
        elif format == 'wav':
            export_params['format'] = 'wav'
        elif format == 'm4a':
            export_params['format'] = 'm4a'
            if 'bit_rate' in options:
                export_params['bitrate'] = str(options['bit_rate'])
        elif format == 'ogg':
            export_params['format'] = 'ogg'
            if 'bit_rate' in options:
                export_params['bitrate'] = str(options['bit_rate'])
        else:
            raise AudioFormatError(f"Unsupported export format: {format}")
        
        # Apply sample rate if specified
        if 'sample_rate' in options:
            # First, adjust the frame rate of the audio
            audio = audio.set_frame_rate(options['sample_rate'])
        
        # Apply channels if specified
        if 'channels' in options:
            if options['channels'] == 1 and audio.channels > 1:
                audio = audio.set_channels(1)
            elif options['channels'] == 2 and audio.channels == 1:
                audio = audio.set_channels(2)
        
        # Export to an in-memory bytes buffer
        buffer = io.BytesIO()
        audio.export(buffer, **export_params)
        
        # Get the bytes from the buffer
        buffer.seek(0)
        exported_data = buffer.read()
        
        return exported_data
    
    except Exception as e:
        logger.error(f"Failed to export audio: {str(e)}")
        raise AudioProcessingError(f"Failed to export audio: {str(e)}")