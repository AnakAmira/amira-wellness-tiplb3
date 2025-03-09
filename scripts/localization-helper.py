#!/usr/bin/env python3

import argparse
import os
import sys
import re
import json
import xml.etree.ElementTree as ET
import csv
import datetime as dt
import colorama
from colorama import Fore, Style

# Import from our application
try:
    from src.backend.app.constants.languages import LanguageCode, DEFAULT_LANGUAGE, LANGUAGE_METADATA
except ImportError:
    # Add the project root to the Python path
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from src.backend.app.constants.languages import LanguageCode, DEFAULT_LANGUAGE, LANGUAGE_METADATA

# Paths to localization files
IOS_STRINGS_PATH = os.path.join('src', 'ios', 'AmiraWellness', 'AmiraWellness', 'Resources', 'Localizable.strings')
ANDROID_STRINGS_PATH = os.path.join('src', 'android', 'app', 'src', 'main', 'res', 'values-es', 'strings.xml')
ANDROID_BASE_STRINGS_PATH = os.path.join('src', 'android', 'app', 'src', 'main', 'res', 'values', 'strings.xml')
REPORT_OUTPUT_DIR = os.path.join('reports', 'localization')

def parse_ios_strings(file_path):
    """
    Parses iOS Localizable.strings file and extracts key-value pairs.
    
    Args:
        file_path (str): Path to the Localizable.strings file
        
    Returns:
        dict: Dictionary of string keys and their translations
    """
    strings = {}
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Remove comments
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        
        # Pattern for "key" = "value";
        pattern = r'"([^"]+)"\s*=\s*"([^"]*)";'
        matches = re.findall(pattern, content)
        
        for key, value in matches:
            # Clean up escape sequences
            key = key.replace('\\"', '"')
            value = value.replace('\\"', '"')
            strings[key] = value
            
        return strings
    except Exception as e:
        print(f"{Fore.RED}Error parsing iOS strings file: {e}{Style.RESET_ALL}")
        return {}

def parse_android_strings(file_path):
    """
    Parses Android strings.xml file and extracts string resources.
    
    Args:
        file_path (str): Path to the strings.xml file
        
    Returns:
        dict: Dictionary of string keys and their translations
    """
    strings = {}
    
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        for string_elem in root.findall('.//string'):
            key = string_elem.get('name')
            # Handle empty string elements
            if string_elem.text is None:
                value = ""
            else:
                value = string_elem.text
                
            if key:
                strings[key] = value
                
        return strings
    except Exception as e:
        print(f"{Fore.RED}Error parsing Android strings file: {e}{Style.RESET_ALL}")
        return {}

def find_missing_translations(ios_strings, android_strings):
    """
    Identifies keys that exist in one platform but are missing in another.
    
    Args:
        ios_strings (dict): Dictionary of iOS string keys and translations
        android_strings (dict): Dictionary of Android string keys and translations
        
    Returns:
        dict: Dictionary with missing keys for each platform
    """
    ios_keys = set(ios_strings.keys())
    android_keys = set(android_strings.keys())
    
    missing_in_android = ios_keys - android_keys
    missing_in_ios = android_keys - ios_keys
    
    return {
        'missing_in_android': list(missing_in_android),
        'missing_in_ios': list(missing_in_ios)
    }

def generate_missing_keys_report(missing_translations, output_path):
    """
    Generates a report of missing translation keys.
    
    Args:
        missing_translations (dict): Dictionary with missing keys for each platform
        output_path (str): Path to save the report
        
    Returns:
        None
    """
    # Create the output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    missing_in_android = missing_translations['missing_in_android']
    missing_in_ios = missing_translations['missing_in_ios']
    
    report = {
        'timestamp': dt.datetime.now().isoformat(),
        'summary': {
            'missing_in_android_count': len(missing_in_android),
            'missing_in_ios_count': len(missing_in_ios)
        },
        'missing_in_android': missing_in_android,
        'missing_in_ios': missing_in_ios
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        
    print(f"{Fore.GREEN}Missing translations report generated at {output_path}{Style.RESET_ALL}")
    print(f"Summary:")
    print(f"  - Missing in Android: {len(missing_in_android)} keys")
    print(f"  - Missing in iOS: {len(missing_in_ios)} keys")

def export_to_csv(ios_strings, android_strings, output_path):
    """
    Exports all localization strings to a CSV file for easy editing.
    
    Args:
        ios_strings (dict): Dictionary of iOS string keys and translations
        android_strings (dict): Dictionary of Android string keys and translations
        output_path (str): Path to save the CSV file
        
    Returns:
        None
    """
    # Create the output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Get all unique keys
    all_keys = set(ios_strings.keys()) | set(android_strings.keys())
    
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Key', 'iOS Value', 'Android Value'])
        
        for key in sorted(all_keys):
            writer.writerow([
                key,
                ios_strings.get(key, ''),
                android_strings.get(key, '')
            ])
    
    print(f"{Fore.GREEN}Localization data exported to {output_path}{Style.RESET_ALL}")
    print(f"Total keys exported: {len(all_keys)}")

def import_from_csv(csv_path, ios_output_path, android_output_path):
    """
    Imports translations from a CSV file and updates platform-specific files.
    
    Args:
        csv_path (str): Path to the CSV file with translations
        ios_output_path (str): Path to save the updated iOS strings file
        android_output_path (str): Path to save the updated Android strings file
        
    Returns:
        None
    """
    ios_strings = {}
    android_strings = {}
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader)  # Skip the header row
            
            for row in reader:
                if len(row) >= 3:
                    key = row[0]
                    ios_value = row[1]
                    android_value = row[2]
                    
                    if key and ios_value:
                        ios_strings[key] = ios_value
                    if key and android_value:
                        android_strings[key] = android_value
        
        # Create the output directories if they don't exist
        os.makedirs(os.path.dirname(ios_output_path), exist_ok=True)
        os.makedirs(os.path.dirname(android_output_path), exist_ok=True)
        
        # Generate iOS strings file
        with open(ios_output_path, 'w', encoding='utf-8') as f:
            f.write('/* Localization file generated by localization-helper.py */\n\n')
            for key, value in sorted(ios_strings.items()):
                # Escape quotes in the value
                value = value.replace('"', '\\"')
                f.write(f'"{key}" = "{value}";\n')
        
        # Generate Android strings file
        root = ET.Element('resources')
        for key, value in sorted(android_strings.items()):
            string_elem = ET.SubElement(root, 'string', name=key)
            string_elem.text = value
        
        tree = ET.ElementTree(root)
        tree.write(android_output_path, encoding='utf-8', xml_declaration=True)
        
        print(f"{Fore.GREEN}Successfully imported translations:{Style.RESET_ALL}")
        print(f"  - iOS: {len(ios_strings)} keys written to {ios_output_path}")
        print(f"  - Android: {len(android_strings)} keys written to {android_output_path}")
                
    except Exception as e:
        print(f"{Fore.RED}Error importing from CSV: {e}{Style.RESET_ALL}")

def normalize_format_specifiers(text, target_platform):
    """
    Converts between iOS and Android format specifiers for strings.
    
    Args:
        text (str): Text to normalize
        target_platform (str): Target platform ('ios' or 'android')
        
    Returns:
        str: Text with normalized format specifiers
    """
    if text is None:
        return ""
    
    if target_platform.lower() == 'ios':
        # Convert Android to iOS format
        # %1$s -> %@, %1$d -> %d, etc.
        text = re.sub(r'%(\d+)\$s', r'%@', text)
        text = re.sub(r'%(\d+)\$d', r'%d', text)
        text = re.sub(r'%(\d+)\$f', r'%f', text)
    elif target_platform.lower() == 'android':
        # Convert iOS to Android format
        # Need to handle order in more complex way for multiple specifiers
        placeholders = re.findall(r'%[@df]', text)
        for i, placeholder in enumerate(placeholders, 1):
            if placeholder == '%@':
                text = text.replace(placeholder, f'%{i}$s', 1)
            elif placeholder == '%d':
                text = text.replace(placeholder, f'%{i}$d', 1)
            elif placeholder == '%f':
                text = text.replace(placeholder, f'%{i}$f', 1)
    
    return text

def validate_translations(ios_strings, android_strings):
    """
    Validates translations for format specifiers and issues warnings for potential problems.
    
    Args:
        ios_strings (dict): Dictionary of iOS string keys and translations
        android_strings (dict): Dictionary of Android string keys and translations
        
    Returns:
        dict: Dictionary with validation issues
    """
    issues = {
        'ios_format_issues': [],
        'android_format_issues': [],
        'value_length_issues': []
    }
    
    # Check iOS format specifiers
    ios_format_pattern = r'%[@dfx]'
    for key, value in ios_strings.items():
        if re.search(ios_format_pattern, value):
            # Check if this key exists in Android
            if key in android_strings:
                android_value = android_strings[key]
                # Check if Android value has corresponding format specifiers
                ios_specifiers = re.findall(ios_format_pattern, value)
                android_specifiers = re.findall(r'%\d+\$[sdf]', android_value)
                
                if len(ios_specifiers) != len(android_specifiers):
                    issues['ios_format_issues'].append({
                        'key': key,
                        'ios_value': value,
                        'android_value': android_value,
                        'issue': f"Format specifier count mismatch: iOS has {len(ios_specifiers)}, Android has {len(android_specifiers)}"
                    })
    
    # Check Android format specifiers
    android_format_pattern = r'%\d+\$[sdf]'
    for key, value in android_strings.items():
        if re.search(android_format_pattern, value):
            # Check if this key exists in iOS
            if key in ios_strings:
                ios_value = ios_strings[key]
                # Check if iOS value has corresponding format specifiers
                android_specifiers = re.findall(android_format_pattern, value)
                ios_specifiers = re.findall(ios_format_pattern, ios_value)
                
                if len(android_specifiers) != len(ios_specifiers):
                    issues['android_format_issues'].append({
                        'key': key,
                        'ios_value': ios_value,
                        'android_value': value,
                        'issue': f"Format specifier count mismatch: Android has {len(android_specifiers)}, iOS has {len(ios_specifiers)}"
                    })
    
    # Check for length discrepancies
    for key in set(ios_strings.keys()) & set(android_strings.keys()):
        ios_value = ios_strings[key]
        android_value = android_strings[key]
        
        # If one string is more than twice as long as the other, flag it
        if len(ios_value) > 0 and len(android_value) > 0:
            ratio = max(len(ios_value), len(android_value)) / min(len(ios_value), len(android_value))
            if ratio > 2:
                issues['value_length_issues'].append({
                    'key': key,
                    'ios_value': ios_value,
                    'android_value': android_value,
                    'ios_length': len(ios_value),
                    'android_length': len(android_value),
                    'ratio': ratio
                })
    
    return issues

def generate_localization_coverage_report(ios_strings, android_strings, output_path):
    """
    Generates a report on localization coverage across the application.
    
    Args:
        ios_strings (dict): Dictionary of iOS string keys and translations
        android_strings (dict): Dictionary of Android string keys and translations
        output_path (str): Path to save the report
        
    Returns:
        None
    """
    # Create stats object and generate report
    stats = LocalizationStats(ios_strings, android_strings)
    report = stats.to_dict()
    
    # Create the output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"{Fore.GREEN}Localization coverage report generated at {output_path}{Style.RESET_ALL}")
    print(f"Summary:")
    print(f"  - iOS: {report['ios_stats']['total_strings']} total strings")
    print(f"  - Android: {report['android_stats']['total_strings']} total strings")
    print(f"  - Common keys: {report['overlap_stats']['common_count']} ({report['overlap_stats']['common_percentage']:.1f}%)")

def prepare_new_language(language_code):
    """
    Prepares template files for a new language based on existing translations.
    
    Args:
        language_code (str): Language code to prepare files for
        
    Returns:
        None
    """
    # Validate language code
    try:
        lang_code = LanguageCode(language_code)
    except ValueError:
        print(f"{Fore.RED}Invalid language code: {language_code}{Style.RESET_ALL}")
        print(f"Available language codes: {[code.value for code in LanguageCode]}")
        return
    
    if lang_code not in LANGUAGE_METADATA:
        print(f"{Fore.RED}Language code not defined in LANGUAGE_METADATA: {language_code}{Style.RESET_ALL}")
        return
    
    # Load default language strings
    default_ios_strings = parse_ios_strings(IOS_STRINGS_PATH)
    default_android_strings = parse_android_strings(ANDROID_STRINGS_PATH)
    
    if not default_ios_strings or not default_android_strings:
        print(f"{Fore.RED}Could not load default language strings.{Style.RESET_ALL}")
        return
    
    # Create iOS directory structure
    ios_lang_dir = os.path.join('src', 'ios', 'AmiraWellness', 'AmiraWellness', 'Resources', f'{language_code}.lproj')
    os.makedirs(ios_lang_dir, exist_ok=True)
    
    # Create Android resource directory
    android_lang_dir = os.path.join('src', 'android', 'app', 'src', 'main', 'res', f'values-{language_code}')
    os.makedirs(android_lang_dir, exist_ok=True)
    
    # Generate iOS template with empty translations but keeping keys
    ios_output_path = os.path.join(ios_lang_dir, 'Localizable.strings')
    with open(ios_output_path, 'w', encoding='utf-8') as f:
        f.write(f'/* Localization template for {LANGUAGE_METADATA[lang_code]["display_name_en"]} */\n\n')
        for key, value in sorted(default_ios_strings.items()):
            # Add the original Spanish value as a comment for reference
            f.write(f'/* Spanish: "{value}" */\n')
            f.write(f'"{key}" = "";\n\n')
    
    # Generate Android template
    android_output_path = os.path.join(android_lang_dir, 'strings.xml')
    root = ET.Element('resources')
    
    # Add comment about translation
    comment = ET.Comment(f' Localization template for {LANGUAGE_METADATA[lang_code]["display_name_en"]} ')
    root.append(comment)
    
    for key, value in sorted(default_android_strings.items()):
        # Add comment with original Spanish value
        comment = ET.Comment(f' Spanish: "{value}" ')
        root.append(comment)
        
        string_elem = ET.SubElement(root, 'string', name=key)
        string_elem.text = ""  # Empty for translation
    
    tree = ET.ElementTree(root)
    tree.write(android_output_path, encoding='utf-8', xml_declaration=True)
    
    print(f"{Fore.GREEN}Successfully prepared template files for {LANGUAGE_METADATA[lang_code]['display_name_en']}:{Style.RESET_ALL}")
    print(f"  - iOS: {ios_output_path}")
    print(f"  - Android: {android_output_path}")
    print(f"\nPlease translate the strings in these files and then run validation.")

class LocalizationStats:
    """Class for calculating and storing localization statistics"""
    
    def __init__(self, ios_strings, android_strings):
        """
        Initializes the LocalizationStats object.
        
        Args:
            ios_strings (dict): Dictionary of iOS string keys and translations
            android_strings (dict): Dictionary of Android string keys and translations
        """
        self.ios_stats = self.calculate_ios_stats(ios_strings)
        self.android_stats = self.calculate_android_stats(android_strings)
        self.overlap_stats = self.calculate_overlap(ios_strings, android_strings)
    
    def calculate_ios_stats(self, ios_strings):
        """
        Calculates statistics for iOS strings.
        
        Args:
            ios_strings (dict): Dictionary of iOS string keys and translations
            
        Returns:
            dict: Statistics for iOS strings
        """
        total = len(ios_strings)
        
        # Group by prefixes or naming patterns
        categories = {}
        for key in ios_strings:
            # Determine category based on key prefix
            prefix = key.split('.')[0] if '.' in key else 'uncategorized'
            categories.setdefault(prefix, []).append(key)
        
        # Calculate category percentages
        category_stats = {}
        for category, keys in categories.items():
            category_stats[category] = {
                'count': len(keys),
                'percentage': (len(keys) / total * 100) if total > 0 else 0
            }
        
        return {
            'total_strings': total,
            'categories': category_stats
        }
    
    def calculate_android_stats(self, android_strings):
        """
        Calculates statistics for Android strings.
        
        Args:
            android_strings (dict): Dictionary of Android string keys and translations
            
        Returns:
            dict: Statistics for Android strings
        """
        total = len(android_strings)
        
        # Group by prefixes or naming patterns
        categories = {}
        for key in android_strings:
            # Determine category based on key prefix
            prefix = key.split('_')[0] if '_' in key else 'uncategorized'
            categories.setdefault(prefix, []).append(key)
        
        # Calculate category percentages
        category_stats = {}
        for category, keys in categories.items():
            category_stats[category] = {
                'count': len(keys),
                'percentage': (len(keys) / total * 100) if total > 0 else 0
            }
        
        return {
            'total_strings': total,
            'categories': category_stats
        }
    
    def calculate_overlap(self, ios_strings, android_strings):
        """
        Calculates overlap statistics between iOS and Android strings.
        
        Args:
            ios_strings (dict): Dictionary of iOS string keys and translations
            android_strings (dict): Dictionary of Android string keys and translations
            
        Returns:
            dict: Overlap statistics
        """
        ios_keys = set(ios_strings.keys())
        android_keys = set(android_strings.keys())
        
        common_keys = ios_keys.intersection(android_keys)
        ios_only_keys = ios_keys - android_keys
        android_only_keys = android_keys - ios_keys
        
        total_unique_keys = len(ios_keys.union(android_keys))
        
        common_percentage = (len(common_keys) / total_unique_keys * 100) if total_unique_keys > 0 else 0
        ios_only_percentage = (len(ios_only_keys) / total_unique_keys * 100) if total_unique_keys > 0 else 0
        android_only_percentage = (len(android_only_keys) / total_unique_keys * 100) if total_unique_keys > 0 else 0
        
        return {
            'common_count': len(common_keys),
            'ios_only_count': len(ios_only_keys),
            'android_only_count': len(android_only_keys),
            'total_unique_count': total_unique_keys,
            'common_percentage': common_percentage,
            'ios_only_percentage': ios_only_percentage,
            'android_only_percentage': android_only_percentage
        }
    
    def to_dict(self):
        """
        Converts all statistics to a dictionary for reporting.
        
        Returns:
            dict: Complete statistics dictionary
        """
        return {
            'timestamp': dt.datetime.now().isoformat(),
            'ios_stats': self.ios_stats,
            'android_stats': self.android_stats,
            'overlap_stats': self.overlap_stats,
            'summary': {
                'total_ios_strings': self.ios_stats['total_strings'],
                'total_android_strings': self.android_stats['total_strings'],
                'common_strings': self.overlap_stats['common_count'],
                'coverage_percentage': self.overlap_stats['common_percentage']
            }
        }

def main():
    """
    Main function that parses arguments and executes the appropriate command.
    
    Returns:
        int: Exit code (0 for success, non-zero for errors)
    """
    # Initialize colorama
    colorama.init()
    
    parser = argparse.ArgumentParser(description='Amira Wellness Localization Helper')
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Sync command
    sync_parser = subparsers.add_parser('sync', help='Find and report missing translations')
    sync_parser.add_argument('--output', default=os.path.join(REPORT_OUTPUT_DIR, 'missing_translations.json'),
                            help='Output file for the missing translations report')
    
    # Export command
    export_parser = subparsers.add_parser('export', help='Export translations to CSV')
    export_parser.add_argument('--output', default=os.path.join(REPORT_OUTPUT_DIR, 'translations.csv'),
                             help='Output file for the CSV export')
    
    # Import command
    import_parser = subparsers.add_parser('import', help='Import translations from CSV')
    import_parser.add_argument('csv_file', help='CSV file with translations')
    import_parser.add_argument('--ios-output', default=IOS_STRINGS_PATH,
                              help='Output file for the iOS strings')
    import_parser.add_argument('--android-output', default=ANDROID_STRINGS_PATH,
                              help='Output file for the Android strings')
    
    # Report command
    report_parser = subparsers.add_parser('report', help='Generate localization coverage report')
    report_parser.add_argument('--output', default=os.path.join(REPORT_OUTPUT_DIR, 'localization_coverage.json'),
                              help='Output file for the coverage report')
    
    # Validate command
    validate_parser = subparsers.add_parser('validate', help='Validate translations for issues')
    validate_parser.add_argument('--output', default=os.path.join(REPORT_OUTPUT_DIR, 'validation_issues.json'),
                               help='Output file for the validation report')
    
    # New language command
    new_lang_parser = subparsers.add_parser('new-language', help='Prepare template files for a new language')
    new_lang_parser.add_argument('language_code', help='Language code (e.g., en, pt)')
    
    # Parse arguments
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    try:
        if args.command == 'sync':
            # Parse iOS and Android strings
            ios_strings = parse_ios_strings(IOS_STRINGS_PATH)
            android_strings = parse_android_strings(ANDROID_STRINGS_PATH)
            
            # Find missing translations
            missing_translations = find_missing_translations(ios_strings, android_strings)
            
            # Generate report
            generate_missing_keys_report(missing_translations, args.output)
            
        elif args.command == 'export':
            # Parse iOS and Android strings
            ios_strings = parse_ios_strings(IOS_STRINGS_PATH)
            android_strings = parse_android_strings(ANDROID_STRINGS_PATH)
            
            # Export to CSV
            export_to_csv(ios_strings, android_strings, args.output)
            
        elif args.command == 'import':
            # Import from CSV
            import_from_csv(args.csv_file, args.ios_output, args.android_output)
            
        elif args.command == 'report':
            # Parse iOS and Android strings
            ios_strings = parse_ios_strings(IOS_STRINGS_PATH)
            android_strings = parse_android_strings(ANDROID_STRINGS_PATH)
            
            # Generate coverage report
            generate_localization_coverage_report(ios_strings, android_strings, args.output)
            
        elif args.command == 'validate':
            # Parse iOS and Android strings
            ios_strings = parse_ios_strings(IOS_STRINGS_PATH)
            android_strings = parse_android_strings(ANDROID_STRINGS_PATH)
            
            # Validate translations
            issues = validate_translations(ios_strings, android_strings)
            
            # Create the output directory if it doesn't exist
            os.makedirs(os.path.dirname(args.output), exist_ok=True)
            
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(issues, f, indent=2, ensure_ascii=False)
            
            total_issues = len(issues['ios_format_issues']) + len(issues['android_format_issues']) + len(issues['value_length_issues'])
            
            print(f"{Fore.GREEN}Validation completed with {total_issues} issues found. Report saved to {args.output}{Style.RESET_ALL}")
            print(f"Summary:")
            print(f"  - iOS format issues: {len(issues['ios_format_issues'])}")
            print(f"  - Android format issues: {len(issues['android_format_issues'])}")
            print(f"  - Value length issues: {len(issues['value_length_issues'])}")
            
        elif args.command == 'new-language':
            # Prepare template files for new language
            prepare_new_language(args.language_code)
            
        return 0
            
    except Exception as e:
        print(f"{Fore.RED}Error: {e}{Style.RESET_ALL}")
        return 1

if __name__ == '__main__':
    sys.exit(main())