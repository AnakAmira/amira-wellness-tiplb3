#!/bin/bash
# version-bump.sh - Automates version bumping across the Amira Wellness application
# This script updates version numbers in the backend, iOS, and Android projects

# Exit immediately if a command exits with a non-zero status
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the root directory of the project
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Define paths to version files
BACKEND_VERSION_FILE="$ROOT_DIR/src/backend/app/__init__.py"
IOS_INFO_PLIST="$ROOT_DIR/src/ios/AmiraWellness/AmiraWellness/Info.plist"
ANDROID_BUILD_GRADLE="$ROOT_DIR/src/android/app/build.gradle.kts"

# Define valid version types
VERSION_TYPES=("major" "minor" "patch")

# Global variables
CURRENT_VERSION=""
NEW_VERSION=""

# Display usage information
print_usage() {
    echo "Amira Wellness Version Bump Script"
    echo "Automates version bumping across the Amira Wellness application components"
    echo ""
    echo "Usage: $(basename "$0") VERSION_TYPE [OPTIONS]"
    echo ""
    echo "VERSION_TYPE:"
    echo "  major        Increment the major version (x.0.0)"
    echo "  minor        Increment the minor version (0.x.0)"
    echo "  patch        Increment the patch version (0.0.x)"
    echo ""
    echo "OPTIONS:"
    echo "  --no-commit  Do not commit changes to git"
    echo "  --tag        Create git tag for the new version"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") patch           # Bump patch version and commit changes"
    echo "  $(basename "$0") minor --tag     # Bump minor version, commit and tag"
    echo "  $(basename "$0") major --no-commit # Bump major version without committing"
    echo ""
}

# Extract the current version from the backend version file
get_current_version() {
    if [ ! -f "$BACKEND_VERSION_FILE" ]; then
        echo "Error: Backend version file not found at $BACKEND_VERSION_FILE" >&2
        return 1
    fi
    
    # Extract version using grep and sed from the __version__ line in the Python file
    local version=$(grep -E "__version__\s*=\s*['\"](.*)['\"]" "$BACKEND_VERSION_FILE" | sed -E "s/__version__\s*=\s*['\"](.*)['\"]/\1/")
    
    # Verify version format (semantic versioning)
    if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Current version '$version' does not follow semantic versioning (X.Y.Z)" >&2
        return 1
    fi
    
    echo "$version"
}

# Calculate the new version based on the current version and bump type
bump_version() {
    local version_type="$1"
    local current_version="$2"
    
    # Split version into components
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Increment version based on type
    case "$version_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "Error: Invalid version type '$version_type'" >&2
            return 1
            ;;
    esac
    
    # Construct new version
    echo "${major}.${minor}.${patch}"
}

# Update the version in the backend Python file
update_backend_version() {
    local new_version="$1"
    
    if [ ! -f "$BACKEND_VERSION_FILE" ]; then
        echo "Error: Backend version file not found at $BACKEND_VERSION_FILE" >&2
        return 1
    fi
    
    # Update the version in the file
    sed -i.bak "s/__version__\s*=\s*['\"].*['\"]/\__version__ = \"$new_version\"/" "$BACKEND_VERSION_FILE"
    
    # Verify the change
    if ! grep -q "__version__ = \"$new_version\"" "$BACKEND_VERSION_FILE"; then
        echo "Error: Failed to update backend version" >&2
        # Restore backup if update failed
        mv "${BACKEND_VERSION_FILE}.bak" "$BACKEND_VERSION_FILE"
        return 1
    fi
    
    # Remove backup file
    rm -f "${BACKEND_VERSION_FILE}.bak"
    
    echo "✅ Updated backend version to $new_version"
    return 0
}

# Update the version in the iOS Info.plist file
update_ios_version() {
    local new_version="$1"
    
    if [ ! -f "$IOS_INFO_PLIST" ]; then
        echo "Error: iOS Info.plist file not found at $IOS_INFO_PLIST" >&2
        return 1
    fi
    
    # Get current build number
    local build_number=""
    if command -v plutil &> /dev/null; then
        # Use plutil if available (macOS)
        build_number=$(plutil -extract CFBundleVersion xml1 -o - "$IOS_INFO_PLIST" | sed -n "s/.*<string>\(.*\)<\/string>.*/\1/p")
    else
        # Fallback to grep/sed
        build_number=$(grep -A1 CFBundleVersion "$IOS_INFO_PLIST" | grep "<string>" | sed -E "s/.*<string>(.*)<\/string>.*/\1/")
    fi
    
    # Increment build number
    local new_build=$((build_number + 1))
    
    # Update version and build number
    if command -v plutil &> /dev/null; then
        # Use plutil if available (macOS)
        plutil -replace CFBundleShortVersionString -string "$new_version" "$IOS_INFO_PLIST"
        plutil -replace CFBundleVersion -string "$new_build" "$IOS_INFO_PLIST"
    else
        # Fallback to sed
        sed -i.bak "s/<key>CFBundleShortVersionString<\/key>\\s*<string>.*<\/string>/<key>CFBundleShortVersionString<\/key>\\n\\t<string>$new_version<\/string>/" "$IOS_INFO_PLIST"
        sed -i.bak "s/<key>CFBundleVersion<\/key>\\s*<string>.*<\/string>/<key>CFBundleVersion<\/key>\\n\\t<string>$new_build<\/string>/" "$IOS_INFO_PLIST"
        rm -f "${IOS_INFO_PLIST}.bak"
    fi
    
    echo "✅ Updated iOS version to $new_version (build $new_build)"
    return 0
}

# Update the version in the Android build.gradle.kts file
update_android_version() {
    local new_version="$1"
    
    if [ ! -f "$ANDROID_BUILD_GRADLE" ]; then
        echo "Error: Android build.gradle.kts file not found at $ANDROID_BUILD_GRADLE" >&2
        return 1
    fi
    
    # Get current versionCode
    local version_code=$(grep -E "versionCode\s*=\s*[0-9]+" "$ANDROID_BUILD_GRADLE" | grep -o '[0-9]\+')
    
    # Increment versionCode
    local new_code=$((version_code + 1))
    
    # Update versionName and versionCode
    sed -i.bak "s/versionName\s*=\s*\".*\"/versionName = \"$new_version\"/" "$ANDROID_BUILD_GRADLE"
    sed -i.bak "s/versionCode\s*=\s*[0-9]\+/versionCode = $new_code/" "$ANDROID_BUILD_GRADLE"
    
    # Verify the changes
    if ! grep -q "versionName = \"$new_version\"" "$ANDROID_BUILD_GRADLE"; then
        echo "Error: Failed to update Android versionName" >&2
        # Restore backup if update failed
        mv "${ANDROID_BUILD_GRADLE}.bak" "$ANDROID_BUILD_GRADLE"
        return 1
    fi
    
    # Remove backup file
    rm -f "${ANDROID_BUILD_GRADLE}.bak"
    
    echo "✅ Updated Android version to $new_version (code $new_code)"
    return 0
}

# Commit version changes to git
commit_changes() {
    local new_version="$1"
    local create_tag="${2:-false}"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        echo "Warning: git command not found, skipping commit" >&2
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Warning: Not in a git repository, skipping commit" >&2
        return 1
    fi
    
    # Add modified files
    git add "$BACKEND_VERSION_FILE" "$IOS_INFO_PLIST" "$ANDROID_BUILD_GRADLE"
    
    # Commit changes
    git commit -m "Bump version to $new_version"
    
    echo "✅ Committed version changes to git"
    
    # Create tag if requested
    if [ "$create_tag" = true ]; then
        git tag -a "v$new_version" -m "Version $new_version"
        echo "✅ Created git tag v$new_version"
    fi
    
    return 0
}

# Main function
main() {
    # Parse arguments
    local version_type=""
    local do_commit=true
    local create_tag=false
    
    # If no arguments or help flag, show usage
    if [ $# -eq 0 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        print_usage
        return 0
    fi
    
    # Get version type
    version_type="$1"
    shift
    
    # Process remaining arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-commit)
                do_commit=false
                ;;
            --tag)
                create_tag=true
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                print_usage
                return 1
                ;;
        esac
        shift
    done
    
    # Validate version type
    local valid_type=false
    for type in "${VERSION_TYPES[@]}"; do
        if [ "$version_type" == "$type" ]; then
            valid_type=true
            break
        fi
    done
    
    if [ "$valid_type" = false ]; then
        echo "Error: Invalid version type '$version_type'" >&2
        print_usage
        return 1
    fi
    
    # Get current version
    CURRENT_VERSION=$(get_current_version)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "Current version: $CURRENT_VERSION"
    
    # Calculate new version
    NEW_VERSION=$(bump_version "$version_type" "$CURRENT_VERSION")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "New version: $NEW_VERSION"
    
    # Update versions in all components
    update_backend_version "$NEW_VERSION" || return 2
    update_ios_version "$NEW_VERSION" || return 2
    update_android_version "$NEW_VERSION" || return 2
    
    # Commit changes if requested
    if [ "$do_commit" = true ]; then
        commit_changes "$NEW_VERSION" "$create_tag" || echo "Warning: Failed to commit changes"
    fi
    
    echo ""
    echo "🎉 Version bump complete! $CURRENT_VERSION → $NEW_VERSION"
    
    return 0
}

# Execute main function with all arguments
main "$@"