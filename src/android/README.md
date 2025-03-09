# Amira Wellness - Android Application

A native Android application for emotional wellness through voice journaling, emotional check-ins, and self-regulation tools. Built with privacy-first principles and end-to-end encryption.

## Getting Started

### Prerequisites

- Android Studio Hedgehog (2023.1.1) or newer
- JDK 17
- Kotlin 1.9+
- Android SDK 33 (target) / SDK 26 (minimum)
- Gradle 8.0+
- Git for version control

### Installation

1. Clone the repository
2. Navigate to the Android project directory: `cd src/android`
3. Open the project in Android Studio
4. Sync Gradle files
5. Create a local.properties file with appropriate SDK path

### Running the Application

1. Create an Android Virtual Device (AVD) in Android Studio if you don't have one
   - Minimum API level 26 (Android 8.0)
   - Recommended: 4GB RAM or more
2. Select the device in the toolbar
3. Click the Run button or press Shift+F10

The application will build and launch in the selected emulator or device.

### Environment Configuration

Create appropriate environment configuration files for development in `app/src/main/kotlin/com/amirawellness/config/EnvironmentConfig.kt`:

```kotlin
// EnvironmentConfig.kt
package com.amirawellness.config

object EnvironmentConfig {
    const val API_BASE_URL = "http://10.0.2.2:8000/api/v1" // 10.0.2.2 points to host machine's localhost from emulator
    const val AUTH_BASE_URL = "http://10.0.2.2:8000/api/v1/auth"
    const val LOGGING_ENABLED = true
    const val ANALYTICS_ENABLED = false
    // Add other environment-specific configuration
}
```

## Project Structure

The project follows a clean architecture approach with clear separation of concerns:

### Directory Structure

```
src/android/app/src/main/kotlin/com/amirawellness/
  ├── config/                 # Application configuration
  ├── core/                   # Core utilities and constants
  │   ├── constants/          # Application constants
  │   ├── extensions/         # Kotlin extensions
  │   └── utils/              # Utility classes
  ├── data/                   # Data layer
  │   ├── models/             # Data models
  │   ├── local/              # Local storage
  │   │   ├── dao/            # Data access objects
  │   │   └── preferences/    # Shared preferences
  │   ├── remote/             # Remote data sources
  │   │   ├── api/            # API client
  │   │   ├── dto/            # Data transfer objects
  │   │   └── mappers/        # DTO to model mappers
  │   └── repositories/       # Data repositories
  ├── di/                     # Dependency injection
  ├── domain/                 # Domain layer
  │   └── usecases/           # Business use cases
  │       ├── auth/           # Authentication use cases
  │       ├── journal/        # Journal use cases
  │       ├── emotional/      # Emotional check-in use cases
  │       ├── tool/           # Tool library use cases
  │       └── progress/       # Progress tracking use cases
  ├── services/               # Service layer
  │   ├── encryption/         # Encryption services
  │   ├── audio/              # Audio recording services
  │   ├── notification/       # Notification services
  │   ├── biometric/          # Biometric authentication
  │   ├── sync/               # Data synchronization
  │   └── analytics/          # Analytics services
  └── ui/                     # User interface
      ├── theme/              # Theme and styling
      ├── navigation/         # Navigation system
      ├── components/         # Reusable UI components
      └── screens/            # Application screens
          ├── onboarding/     # Onboarding screens
          ├── auth/           # Authentication screens
          ├── home/           # Home dashboard
          ├── journal/        # Journal screens
          ├── emotions/       # Emotional check-in screens
          ├── tools/          # Tool library screens
          ├── progress/       # Progress tracking screens
          ├── profile/        # User profile screens
          ├── settings/       # Settings screens
          └── main/           # Main container screen
```

### Architecture Pattern

The application follows the MVVM (Model-View-ViewModel) architecture pattern with Clean Architecture principles:

- **UI Layer**: Jetpack Compose UI components and ViewModels
- **Domain Layer**: Use cases that encapsulate business logic
- **Data Layer**: Repositories, data sources, and models

This separation ensures testability, maintainability, and scalability of the codebase.

### Dependency Injection

Dependency injection is implemented using Koin:

- **AppModule**: Application-level dependencies
- **NetworkModule**: API and networking dependencies
- **StorageModule**: Database and storage dependencies
- **EncryptionModule**: Security and encryption dependencies
- **ServiceModule**: Service-layer dependencies
- **ViewModelModule**: ViewModel dependencies

## Key Features

The Android application implements the following key features:

### Voice Journaling

- High-quality audio recording with AAC format (128 kbps, 44.1 kHz, mono)
- Pre and post emotional check-ins for each recording
- End-to-end encryption of audio data
- Background recording capability
- Playback with waveform visualization
- Journal management (view, delete, export)

### Emotional Check-ins

- Intuitive emotion selection interface
- Intensity tracking with sliders
- Historical emotion tracking
- Pattern recognition and insights
- Visualization of emotional trends
- Tool recommendations based on emotional state

### Tool Library

- Categorized self-regulation tools
- Breathing exercises with guided animations
- Meditation guides with audio
- Journaling prompts
- Somatic exercises with instructions
- Gratitude practices
- Favorites management
- Offline access to saved tools

### Progress Tracking

- Streak tracking for consistent usage
- Achievement system with unlockable badges
- Emotional trend visualization
- Usage statistics and insights
- Weekly and monthly progress reports

### Security and Privacy

- End-to-end encryption using AES-256-GCM
- Secure key storage using Android Keystore
- Biometric authentication option
- Secure data export
- Privacy-focused design with minimal data collection
- Offline-first approach for privacy

## Security Implementation

Security is a core focus of the application:

### End-to-End Encryption

- Voice recordings are encrypted with AES-256-GCM
- Encryption is performed on-device before storage or transmission
- Each recording uses a unique initialization vector (IV)
- Authentication tags ensure data integrity
- Encryption keys are derived from user credentials and stored securely

### Key Management

- Encryption keys are stored in the Android Keystore system
- Hardware-backed security when available on device
- Biometric authentication can be required for key access
- Keys never leave the device
- Secure key rotation mechanism

### Secure Storage

- Encrypted Room database for sensitive information
- EncryptedSharedPreferences for secure settings
- Encrypted file storage for audio recordings
- Secure deletion with verification
- Memory protection for sensitive data

### Network Security

- TLS 1.3 for all API communications
- Certificate pinning to prevent MITM attacks
- Network security configuration
- No cleartext traffic allowed
- Request signing for API authentication

## Offline Capability

The application is designed to function effectively without an internet connection:

### Offline-First Approach

- All data is stored locally first
- Core features work completely offline
- Background synchronization when online
- Clear indicators of sync status
- Bandwidth-aware synchronization

### Synchronization Strategy

- Operation queuing for offline changes
- Conflict resolution for concurrent changes
- Prioritized sync for critical data
- Retry mechanism with exponential backoff
- Battery-efficient background sync

## UI Implementation

The user interface is built using Jetpack Compose:

### Design System

- Nature-inspired color palette
- Consistent typography and spacing
- Reusable component library
- Support for light and dark themes
- Responsive layouts for different screen sizes

### Compose UI

- Declarative UI with Compose
- State hoisting pattern
- Recomposition optimization
- Animation system for smooth transitions
- Custom composables for specialized functionality

### Accessibility

- TalkBack support with semantic properties
- Content descriptions for all UI elements
- Support for dynamic font sizes
- Sufficient contrast ratios
- Keyboard navigation support

### Localization

- Spanish (ES) as primary language
- Support for regional variations
- Localized strings and resources
- RTL layout support for future language additions
- Context-aware translations

## Testing

The project includes comprehensive testing:

### Unit Tests

```bash
# Run unit tests
./gradlew test

# Run tests with coverage report
./gradlew testDebugUnitTestCoverage

# Run specific test
./gradlew testDebugUnitTest --tests "com.amirawellness.ui.screens.auth.LoginViewModelTest"
```

### Instrumented Tests

```bash
# Run instrumented tests
./gradlew connectedAndroidTest

# Run specific instrumented test
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.amirawellness.ui.screens.auth.LoginScreenTest
```

### Test Structure

- Unit tests for ViewModels, Use Cases, Repositories, and Utilities
- Instrumented tests for Room DAOs and UI components
- Mocks and test doubles using Mockito
- UI testing with Compose testing libraries
- Test fixtures for consistent test data

## Build Configuration

The application uses Gradle with Kotlin DSL for build configuration:

### Build Variants

- **Debug**: Development build with logging and developer tools
- **Release**: Production build with optimizations and ProGuard
- **Staging**: Pre-production build with staging environment

### Gradle Tasks

```bash
# Assemble debug build
./gradlew assembleDebug

# Install debug build on connected device
./gradlew installDebug

# Run static analysis
./gradlew lint

# Check Kotlin code style
./gradlew ktlintCheck

# Format Kotlin code
./gradlew ktlintFormat

# Generate dependency reports
./gradlew dependencyReport
```

### Dependencies

Key dependencies used in the project:

- **Jetpack Compose**: UI framework
- **Kotlin Coroutines**: Asynchronous programming
- **Room**: Local database
- **Retrofit**: Network communication
- **Koin**: Dependency injection
- **Security Crypto**: Encryption
- **Media3**: Audio playback and recording
- **WorkManager**: Background processing
- **Firebase**: Analytics and crash reporting

## Deployment

The application is deployed through Google Play:

### Release Process

1. Version bump in `build.gradle.kts`
2. Update release notes
3. Create signed release build
4. Test release build thoroughly
5. Upload to Google Play Console
6. Staged rollout to production

### CI/CD

Continuous Integration and Deployment is set up with GitHub Actions:

- Automated builds on pull requests
- Unit and instrumented tests
- Static analysis and code quality checks
- Automated deployment to internal testing track

## Troubleshooting

Common issues and their solutions:

### Build Issues

- **Gradle sync failures**: Check internet connection and Gradle configuration
- **Dependency conflicts**: Check for version incompatibilities
- **Compile errors**: Ensure Kotlin and Android plugin versions are compatible

### Runtime Issues

- **App crashes**: Check Logcat for exception details
- **Performance problems**: Use Android Profiler to identify bottlenecks
- **UI glitches**: Verify Compose state management and recomposition

### Device Compatibility

- **API level issues**: Verify minimum API level compatibility
- **Device-specific bugs**: Test on multiple device types
- **Permission problems**: Check manifest and runtime permission handling

## Contributing

Guidelines for contributing to the project:

### Development Workflow

1. Create a feature branch from `develop`
2. Implement changes with tests
3. Follow code style guidelines
4. Create a pull request with detailed description
5. Address review comments
6. Merge after approval

### Coding Standards

- Follow Kotlin style guide
- Use ktlint for code formatting
- Write meaningful commit messages
- Document public APIs
- Write tests for new functionality

## Additional Resources

For more detailed information, refer to these resources:

- [Architecture Overview](../../docs/architecture/mobile.md)
- [API Documentation](../../docs/api/)
- [Development Setup Guide](../../docs/development/setup.md)
- [Security Implementation](../../docs/security/encryption.md)
- [Testing Guidelines](../../docs/development/testing.md)

## License

This project is licensed under the terms specified in the LICENSE file.