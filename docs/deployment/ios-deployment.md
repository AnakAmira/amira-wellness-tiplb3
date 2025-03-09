---
title: iOS Deployment Guide
---

## Introduction
This document provides comprehensive instructions for deploying the Amira Wellness iOS application to various environments. The iOS app is built with Swift and SwiftUI, with a focus on privacy, security, and user experience.

The deployment process is automated through CI/CD pipelines, with appropriate safeguards and validation steps to ensure application quality and integrity. This guide covers all aspects of iOS deployment, from development builds to App Store distribution, including code signing, build configurations, and release management procedures.

The Amira Wellness iOS application follows Apple's best practices for deployment, with a focus on security, reliability, and user experience. The application is distributed through TestFlight for beta testing and the App Store for production releases.

## Prerequisites
Before proceeding with deployment, ensure the following prerequisites are met:

### Access Requirements
- Apple Developer Program membership (annual subscription)
- App Store Connect access with appropriate role (Admin or App Manager)
- GitHub repository access with write permissions
- Access to the code signing certificates and provisioning profiles
- AWS S3 access for build artifacts (optional)

### Tools and Software
- Xcode 14.0 or later
- macOS 12.0 or later
- Ruby 3.2 or later (for fastlane)
- fastlane 2.210.0 or later
- Git for source code management
- GitHub CLI (optional, for release management)

### Knowledge Requirements
- Basic understanding of iOS app development and Xcode
- Familiarity with code signing and provisioning profiles
- Understanding of App Store submission process
- Knowledge of CI/CD principles and GitHub Actions
- Familiarity with fastlane for iOS automation

## Code Signing
Code signing is a critical aspect of iOS app deployment, ensuring the app's authenticity and integrity.

### Certificate Types
The iOS app requires different certificate types for different deployment scenarios:

- **Development Certificate**: Used for development and debugging on physical devices
- **Distribution Certificate**: Used for App Store and TestFlight distribution

These certificates are managed through the Apple Developer Portal and are linked to the Apple Developer Program account.

### Provisioning Profiles
Provisioning profiles link the app, certificates, and device IDs:

- **Development Provisioning Profile**: For development builds, includes specific device UDIDs
- **App Store Provisioning Profile**: For TestFlight and App Store distribution

Provisioning profiles are generated in the Apple Developer Portal and must be updated when adding new devices or when certificates expire.

### Fastlane Match
The project uses fastlane match to manage certificates and provisioning profiles. Match stores these files in a Git repository, encrypted with a passphrase.

```bash
# Initialize match (first-time setup only)
cd src/ios/AmiraWellness
fastlane match init

# Generate or download development certificates and profiles
fastlane match development

# Generate or download distribution certificates and profiles
fastlane match appstore
```

Match ensures that all team members and CI systems use the same certificates and profiles, preventing code signing issues.

### CI/CD Integration
In the CI/CD pipeline, match is used to retrieve certificates and profiles:

```yaml
# GitHub Actions workflow excerpt
- name: Set up code signing
  run: bundle exec fastlane match appstore
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    FASTLANE_USER: ${{ secrets.FASTLANE_USER }}
    FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
```

This approach ensures secure handling of code signing assets in the CI/CD environment.

## Deployment Environments
The Amira Wellness iOS application can be deployed to several environments, each with specific configurations and purposes:

### Development
Development builds are used for internal testing during feature development. These builds are typically installed directly from Xcode or distributed via ad-hoc methods.

Key characteristics:
- Development signing configuration
- Debug build configuration
- Development API endpoint
- Debug logging enabled
- Test features enabled

To create a development build:

```bash
# Using Xcode
# Open the project and select the 'Debug' scheme
# Run on device or simulator

# Using fastlane
cd src/ios/AmiraWellness
fastlane build_for_testing
```

Development builds can be installed directly on registered devices or simulators.

### TestFlight (Beta)
TestFlight builds are used for beta testing with internal and external testers before App Store release.

Key characteristics:
- Distribution signing configuration
- Release build configuration
- Staging API endpoint
- Limited logging
- Beta features enabled for testing

To create and distribute a TestFlight build:

```bash
# Using fastlane
cd src/ios/AmiraWellness
fastlane beta
```

This command will build the app, run tests, and upload it to TestFlight for distribution to testers. The CI/CD pipeline also automates this process for builds from the `develop` branch.

### App Store (Production)
App Store builds are the production versions available to end users through the App Store.

Key characteristics:
- Distribution signing configuration
- Release build configuration
- Production API endpoint
- Minimal logging
- Only stable features enabled

To create and submit an App Store build:

```bash
# Using fastlane
cd src/ios/AmiraWellness
fastlane release
```

This command will build the app, run tests, and upload it to App Store Connect for review and distribution. The CI/CD pipeline automates this process for builds from the `main` branch, with required approval.

## Build Configurations
The Xcode project includes multiple build configurations to support different deployment environments.

### Configuration Types
The project defines three main build configurations:

- **Debug**: For development and testing, with debugging enabled
- **Release**: For TestFlight and App Store, with optimizations enabled
- **Staging**: For internal testing with staging backend services

Each configuration has specific settings for optimization, debugging, and environment variables.

### Schemes
The project includes multiple schemes that combine build configurations with specific targets:

- **AmiraWellness**: Main scheme for development and production
- **AmiraWellness-Staging**: Scheme for staging environment
- **AmiraWellness-Tests**: Scheme for running tests

Schemes can be selected in Xcode or specified in fastlane commands.

### Environment Variables
Environment-specific variables are defined using Xcode configuration files (`.xcconfig`):

```
// Debug.xcconfig
API_BASE_URL = https://api-dev.amirawellness.com/
ENABLE_TESTING_FEATURES = YES
LOG_LEVEL = debug

// Staging.xcconfig
API_BASE_URL = https://api-staging.amirawellness.com/
ENABLE_TESTING_FEATURES = YES
LOG_LEVEL = info

// Release.xcconfig
API_BASE_URL = https://api.amirawellness.com/
ENABLE_TESTING_FEATURES = NO
LOG_LEVEL = error
```

These variables are accessed in the code through the Info.plist file or the Bundle extension.

### Feature Flags
Feature flags are used to enable or disable features in different environments:

```swift
enum FeatureFlag {
    case newRecommendationEngine
    case advancedAnalytics
    case voiceEffects
    
    var isEnabled: Bool {
        switch self {
        case .newRecommendationEngine:
            #if DEBUG
            return true
            #elseif STAGING
            return true
            #else
            return false
            #endif
        case .advancedAnalytics:
            return true
        case .voiceEffects:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
}
```

This approach allows for controlled feature rollout and testing.

## CI/CD Pipeline
The CI/CD pipeline automates the build, test, and deployment process, ensuring consistent and reliable deployments.

### GitHub Actions Workflow
The CI/CD pipeline is implemented using GitHub Actions, with separate workflows for different purposes:

- `ios-ci.yml`: Runs tests and builds the app on pull requests and pushes
- `deploy-staging.yml`: Deploys to TestFlight for beta testing on merge to develop
- `deploy-production.yml`: Deploys to App Store with approval

These workflows are defined in the `.github/workflows` directory.

### CI Workflow
The CI workflow (`ios-ci.yml`) includes the following jobs:

1. **Lint**: Runs SwiftLint to ensure code quality
2. **Dependency Check**: Scans for vulnerable dependencies
3. **Unit Test**: Runs unit tests on the iOS simulator
4. **UI Test**: Runs UI tests on the iOS simulator
5. **Build**: Builds the app for testing purposes

This workflow runs on pull requests and pushes to main and develop branches, ensuring code quality before deployment.

### TestFlight Deployment Workflow
The TestFlight deployment workflow is triggered automatically when changes are merged to the develop branch:

1. Set up code signing with match
2. Build the app with staging configuration
3. Run tests to ensure quality
4. Upload to TestFlight for internal testing
5. Notify the team about the new build

This workflow uses the fastlane `beta` lane for deployment automation.

### App Store Deployment Workflow
The App Store deployment workflow requires manual approval and is typically triggered after successful testing in TestFlight:

1. Wait for approval from authorized team members
2. Set up code signing with match
3. Build the app with production configuration
4. Run tests to ensure quality
5. Upload to App Store Connect
6. Create a GitHub release with release notes
7. Notify the team about the submission

This workflow uses the fastlane `release` lane for deployment automation and includes additional safeguards to prevent accidental releases.

### Environment Promotion
Code follows a promotion path through environments:

1. Development: Local builds during feature development
2. TestFlight Internal Testing: Automatic deployment from `develop` branch
3. TestFlight External Testing: Manual promotion after internal testing
4. App Store: Manual approval required for deployment from `main`

This process ensures proper validation before code reaches end users.

## Fastlane Configuration
Fastlane automates the build and deployment process, providing consistent and reliable deployments.

### Fastfile Structure
The Fastfile defines the automation lanes for different deployment scenarios:

```ruby
default_platform(:ios)

platform :ios do
  before_all do
    # Setup steps that run before any lane
  end

  desc "Run tests"
  lane :test do
    scan(
      scheme: "AmiraWellness",
      clean: true,
      code_coverage: true,
      output_directory: "fastlane/test_output",
      output_types: "html,junit"
    )
  end

  desc "Build for testing"
  lane :build_for_testing do
    match(type: "development")
    gym(
      scheme: "AmiraWellness",
      configuration: "Debug",
      clean: true,
      export_method: "development"
    )
  end

  desc "Deploy to TestFlight"
  lane :beta do
    increment_build_number
    match(type: "appstore")
    gym(
      scheme: "AmiraWellness-Staging",
      configuration: "Release",
      clean: true,
      export_method: "app-store"
    )
    pilot(
      skip_waiting_for_build_processing: true,
      skip_submission: false,
      distribute_external: false,
      notify_external_testers: true
    )
  end

  desc "Deploy to App Store"
  lane :release do
    increment_build_number
    match(type: "appstore")
    gym(
      scheme: "AmiraWellness",
      configuration: "Release",
      clean: true,
      export_method: "app-store"
    )
    deliver(
      skip_screenshots: true,
      skip_metadata: false,
      submit_for_review: false,
      automatic_release: false,
      phased_release: true
    )
  end

  desc "Refresh certificates"
  lane :refresh_certificates do
    match(type: "development")
    match(type: "appstore")
  end
end
```

This Fastfile defines lanes for testing, building, and deploying the app to different environments.

### Appfile Configuration
The Appfile contains app-specific information for fastlane:

```ruby
app_identifier("com.amirawellness.app") # The bundle identifier of your app
apple_id("developer@amirawellness.com") # Your Apple email address
team_id("ABCDE12345") # Developer Portal Team ID
itc_team_id("123456789") # App Store Connect Team ID
```

This information is used by fastlane to interact with Apple's services.

### Matchfile Configuration
The Matchfile configures the certificate and provisioning profile management:

```ruby
git_url("https://github.com/amirawellness/certificates.git")
storage_mode("git")
git_branch("main")
app_identifier(["com.amirawellness.app"])
type("development") # The default type, can be: appstore, adhoc, enterprise or development
readonly(true) # Set to true to prevent match from modifying files
team_id("ABCDE12345")
username("developer@amirawellness.com")
```

This configuration ensures consistent code signing across all development environments and CI/CD systems.

### Custom Actions
Custom fastlane actions can be defined for project-specific tasks:

```ruby
# In fastlane/actions/update_version.rb
module Fastlane
  module Actions
    class UpdateVersionAction < Action
      def self.run(params)
        # Custom version update logic
      end

      def self.description
        "Updates the version number based on semantic versioning"
      end

      # ... other required methods
    end
  end
end
```

Custom actions can be used in the Fastfile like any built-in action.

## App Store Submission
Submitting the app to the App Store involves several steps beyond building and uploading the binary.

### App Store Connect Setup
Before the first submission, the app must be properly configured in App Store Connect:

1. Create the app in App Store Connect with the correct bundle ID
2. Configure app information (name, description, screenshots, etc.)
3. Complete the App Privacy information
4. Set up pricing and availability
5. Configure in-app purchases (if applicable)

These steps are typically performed manually through the App Store Connect web interface.

### App Store Review Guidelines
The app must comply with Apple's App Store Review Guidelines to be approved for distribution. Key considerations include:

- Privacy and data handling
- Content and intellectual property
- Design and functionality
- Performance and stability
- Business model and monetization

Ensure that the app meets all guidelines before submission to avoid rejection.

### Metadata and Screenshots
App Store metadata can be managed using fastlane deliver:

```bash
# Generate metadata template
fastlane deliver init

# Update metadata and screenshots
fastlane deliver
```

This creates a `fastlane/metadata` directory with subdirectories for different languages, where you can manage app descriptions, keywords, screenshots, and other metadata.

### Phased Release
For production releases, a phased rollout is recommended to gradually release to users:

```ruby
deliver(
  # ... other parameters
  phased_release: true
)
```

A phased release starts with a small percentage of users and automatically increases over time. This allows for early detection of issues before affecting all users.

### App Store API
The App Store Connect API can be used to automate app management:

```ruby
app_store_connect_api_key(
  key_id: "ABC123",
  issuer_id: "DEF456",
  key_filepath: "./AuthKey_ABC123.p8",
  duration: 1200,
  in_house: false
)
```

This API key can be used with fastlane actions like `pilot`, `deliver`, and `app_store_build_number` to interact with App Store Connect programmatically.

## Release Management
Proper release management ensures smooth updates and clear communication about changes.

### Version Numbering
The application follows semantic versioning (MAJOR.MINOR.PATCH) with an additional build number:

```swift
// In Info.plist
CFBundleShortVersionString: "1.2.3" // Semantic version
CFBundleVersion: "42" // Build number
```

- CFBundleShortVersionString: Human-readable version following semantic versioning
  - MAJOR: Significant changes that may not be backward compatible
  - MINOR: New features that are backward compatible
  - PATCH: Bug fixes and minor improvements
- CFBundleVersion: Integer that increases with each build (used by App Store)

The build number is incremented automatically for each build by the CI/CD pipeline.

### Release Notes
Release notes are generated automatically from git commits, but should be reviewed and edited before submission:

```bash
# Generate release notes
git log --pretty=format:"- %s" $(git describe --tags --abbrev=0)..HEAD
```

Release notes should be concise, user-focused, and highlight new features, improvements, and bug fixes. They should be written in Spanish (the app's primary language) and follow a consistent format.

### Git Tagging
Each release is tagged in git for future reference:

```bash
# Tag the release (done automatically by the release workflow)
git tag -a v1.2.3 -m "Version 1.2.3"
git push origin v1.2.3
```

Tags follow the format `v{version}` (e.g., `v1.2.3`) and include the full version number.

### GitHub Releases
GitHub Releases provide a centralized place to document changes and provide release artifacts:

```bash
# Create a GitHub release (done by the CI/CD pipeline)
github release create v1.2.3 --title "Version 1.2.3" --notes "$(git log --pretty=format:'- %s' v1.2.2..HEAD)"
```

GitHub Releases are created automatically by the CI/CD pipeline after successful App Store submission.

## Troubleshooting
Common deployment issues and their resolution procedures.

### Code Signing Issues
For code signing issues:

1. Verify that certificates and profiles are valid: `fastlane match nuke distribution && fastlane match appstore`
2. Check that the team ID and bundle identifier are correct
3. Ensure that the provisioning profile matches the app's entitlements
4. Verify that the signing identity is correctly selected in Xcode
5. Check that the match repository is accessible and up to date

If issues persist, consider regenerating certificates and profiles using `fastlane match nuke [type]` followed by `fastlane match [type]`.

### Build Failures
For build failures:

1. Check the build log for specific error messages
2. Verify that dependencies are up to date: `pod install` or `swift package update`
3. Clean the build folder: `xcodebuild clean` or use Xcode's "Clean Build Folder" option
4. Check for Swift version compatibility issues
5. Verify that all required files are included in the project

If the issue persists, try building from Xcode directly to get more detailed error information.

### TestFlight Issues
For TestFlight issues:

1. Verify that the app's bundle ID is registered in App Store Connect
2. Check that the provisioning profile includes the correct devices
3. Ensure that the app version and build number are unique
4. Verify that the app binary meets Apple's requirements
5. Check that testers are properly added to the TestFlight distribution list

If uploads fail, check the App Store Connect console for specific error messages.

### App Store Rejection
For App Store rejection:

1. Carefully read the rejection reason in App Store Connect
2. Address the specific issues mentioned by the reviewer
3. Test the fixes thoroughly before resubmitting
4. Consider contacting App Review if the rejection seems incorrect
5. Update the app metadata if it doesn't match the app functionality

Common rejection reasons include privacy policy issues, performance problems, and metadata inconsistencies.

## Security Considerations
Security is a primary concern for the Amira Wellness application, with specific considerations for iOS deployment.

### Secure Credentials Storage
Sensitive credentials are stored securely:

- Local development: Keychain or environment variables
- CI/CD pipeline: GitHub Secrets with appropriate access controls
- App Store Connect API: API keys stored securely and rotated regularly

Credentials are never committed to the repository, even in encrypted form.

### Certificate Protection
Code signing certificates are protected through several measures:

- Storage in an encrypted Git repository using fastlane match
- Access limited to authorized developers and CI systems
- Regular rotation according to Apple's expiration policies
- Secure passphrase management for the match repository

These measures prevent unauthorized app distribution and protect the app's identity.

### Sensitive Configuration
Sensitive configuration is handled securely:

- API keys and secrets are not hardcoded in the app
- Environment-specific configuration is injected during build
- Production credentials are only used in production builds
- Debug features are disabled in production builds

This approach prevents leakage of sensitive information through the app binary.

### End-to-End Encryption
The app implements end-to-end encryption for sensitive user data:

- Voice recordings are encrypted on the device before transmission
- Encryption keys are stored in the Secure Enclave where available
- Key material is never transmitted to the server
- Biometric authentication can be used to protect access to encrypted data

This ensures that sensitive user data remains private and secure throughout the application lifecycle.

## References
Additional resources for iOS deployment and operations:

### Internal Documentation
- [iOS README](../../src/ios/README.md): Overview of the iOS application
- [Backend Deployment](./backend-deployment.md): Backend deployment procedures
- [Security Architecture](../architecture/security.md): Security implementation details
- [Development Setup](../development/setup.md): Local development environment

### External Resources
- [App Store Connect Help](https://help.apple.com/app-store-connect/): Official documentation for App Store Connect
- [TestFlight Beta Testing](https://developer.apple.com/testflight/): Apple's guide to TestFlight
- [Fastlane Documentation](https://docs.fastlane.tools/): Comprehensive guide to fastlane
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): Apple's guidelines for app review

### Tools and Scripts
- `scripts/version-bump.sh`: Helper script for version management
- `scripts/generate-release-notes.sh`: Script for generating release notes
- `scripts/validate-build.sh`: Build validation script
- `scripts/localization-helper.py`: Localization management script

## Appendix
Additional reference information for iOS deployment.

### Fastlane Commands Reference
Common fastlane commands used in the deployment process:

```bash
# Run tests
fastlane test

# Build for development
fastlane build_for_testing

# Deploy to TestFlight
fastlane beta

# Deploy to App Store
fastlane release

# Refresh certificates and profiles
fastlane refresh_certificates

# Increment build number
fastlane increment_build_number

# Increment version number
fastlane increment_version_number bump_type:patch
```

These commands can be run locally or in the CI/CD pipeline.

### Environment Variables
Environment variables used in the deployment process:

| Variable | Purpose | Used In |
|----------|---------|--------|
| `FASTLANE_USER` | Apple ID for authentication | match, pilot, deliver |
| `FASTLANE_PASSWORD` | App-specific password | match, pilot, deliver |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password for Apple ID | pilot, deliver |
| `MATCH_PASSWORD` | Passphrase for match repository | match |
| `MATCH_GIT_URL` | URL of the match Git repository | match |
| `KEYCHAIN_PASSWORD` | Password for the macOS keychain | CI/CD pipeline |
| `DEVELOPER_DIR` | Path to Xcode installation | CI/CD pipeline |
| `FL_VERSION_NUMBER_VERSION` | Version number override | increment_version_number |
| `FL_BUILD_NUMBER_BUILD_NUMBER` | Build number override | increment_build_number |

These variables should be set in the CI/CD environment or locally as needed.

### App Store Connect API Key Setup
Steps to set up an App Store Connect API key:

1. Log in to App Store Connect
2. Go to Users and Access > Keys
3. Click the "+" button to create a new key
4. Provide a name for the key and select the appropriate access level
5. Download the key file (it can only be downloaded once)
6. Store the key file securely
7. Use the key with fastlane:

```ruby
app_store_connect_api_key(
  key_id: "ABC123",
  issuer_id: "DEF456",
  key_filepath: "./AuthKey_ABC123.p8"
)
```

This approach is more secure than using Apple ID credentials.

### TestFlight Distribution Groups
TestFlight distribution can be organized into groups:

1. **Internal Testers**: Apple Developer account members (up to 100 users)
   - Immediate access to builds
   - No review required
   - Used for development team testing

2. **External Testers**: Any user with an email invitation or public link
   - Requires App Review approval
   - Can be organized into groups
   - Used for beta testing with real users

To manage groups with fastlane:

```ruby
pilot(
  groups: ["Developers", "QA Team", "Beta Testers"],
  distribute_external: true,
  notify_external_testers: true
)
```

This allows for targeted distribution to specific tester groups.