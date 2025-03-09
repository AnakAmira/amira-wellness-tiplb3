from enum import Enum

class LanguageCode(Enum):
    """Enumeration of language codes supported in the application."""
    ES = "es"          # Spanish (Spain)
    ES_LATAM = "es-la" # Spanish (Latin America)
    EN = "en"          # English
    PT = "pt"          # Portuguese

# Default language for the application
DEFAULT_LANGUAGE = LanguageCode.ES

# Metadata for all supported languages
LANGUAGE_METADATA = {
    LanguageCode.ES: {
        'display_name': 'Español',
        'display_name_en': 'Spanish',
        'native_name': 'Español',
        'available': True,
        'default': True,
        'flag_icon': 'es.png'
    },
    LanguageCode.ES_LATAM: {
        'display_name': 'Español (Latinoamérica)',
        'display_name_en': 'Spanish (Latin America)',
        'native_name': 'Español (Latinoamérica)',
        'available': True,
        'default': False,
        'flag_icon': 'es_latam.png'
    },
    LanguageCode.EN: {
        'display_name': 'Inglés',
        'display_name_en': 'English',
        'native_name': 'English',
        'available': False,  # Not available in initial release
        'default': False,
        'flag_icon': 'en.png'
    },
    LanguageCode.PT: {
        'display_name': 'Portugués',
        'display_name_en': 'Portuguese',
        'native_name': 'Português',
        'available': False,  # Not available in initial release
        'default': False,
        'flag_icon': 'pt.png'
    }
}

def get_language_display_name(language_code: LanguageCode, use_english: bool = False) -> str:
    """
    Returns the localized display name for a language code.
    
    Args:
        language_code: The language code to get the display name for
        use_english: If True, returns the English display name
        
    Returns:
        The localized display name for the language
        
    Raises:
        ValueError: If the language code is not valid
    """
    if language_code in LANGUAGE_METADATA:
        if use_english:
            return LANGUAGE_METADATA[language_code]['display_name_en']
        return LANGUAGE_METADATA[language_code]['display_name']
    else:
        raise ValueError(f"Invalid language code: {language_code}")

def get_language_native_name(language_code: LanguageCode) -> str:
    """
    Returns the native name for a language code.
    
    Args:
        language_code: The language code to get the native name for
        
    Returns:
        The native name for the language
        
    Raises:
        ValueError: If the language code is not valid
    """
    if language_code in LANGUAGE_METADATA:
        return LANGUAGE_METADATA[language_code]['native_name']
    else:
        raise ValueError(f"Invalid language code: {language_code}")

def is_language_available(language_code: LanguageCode) -> bool:
    """
    Checks if a language is currently available in the application.
    
    Args:
        language_code: The language code to check availability for
        
    Returns:
        True if the language is available, False otherwise
        
    Raises:
        ValueError: If the language code is not valid
    """
    if language_code in LANGUAGE_METADATA:
        return LANGUAGE_METADATA[language_code]['available']
    else:
        raise ValueError(f"Invalid language code: {language_code}")

def get_available_languages() -> list:
    """
    Returns a list of all available language codes.
    
    Returns:
        A list of available LanguageCode values
    """
    available_languages = []
    for lang_code, metadata in LANGUAGE_METADATA.items():
        if metadata['available']:
            available_languages.append(lang_code)
    return available_languages