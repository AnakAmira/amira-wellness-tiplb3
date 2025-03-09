"""
Constants Module

This module imports and re-exports all constants defined in the Amira Wellness
application. It serves as a centralized entry point for accessing application
constants including emotion types, tool categories, achievement definitions,
error codes, and language settings.

Usage:
    from app.constants import EmotionType, ToolCategory, ErrorCategory

This module also defines application-level constants such as VERSION and APP_NAME.
"""

# Import all constants from submodules
from .emotions import *
from .tools import *
from .achievements import *
from .error_codes import *
from .languages import *

# Application constants
VERSION = "1.0.0"
APP_NAME = "Amira Wellness"