# Amira Wellness - iOS Application

A native iOS application for emotional wellness through voice journaling, emotional check-ins, and self-regulation tools. Built with privacy-first principles and end-to-end encryption.

## Getting Started

Instructions for setting up the development environment, building, and running the application.

## Prerequisites

- Xcode 14.0 or later
- iOS 14.0+ deployment target
- Swift 5.9+
- CocoaPods dependency manager
- Git for version control

## Installation

1. Clone the repository
2. Navigate to the iOS project directory: `cd src/ios/AmiraWellness`
3. Install dependencies: `pod install`
4. Open the workspace: `open AmiraWellness.xcworkspace`

## Project Structure

The project follows a modular architecture with clear separation of concerns:

- **Core**: Constants, extensions, utilities, and dependency injection
- **Models**: Data models for the application
- **Services**: Business logic and API communication
- **UI**: User interface components and screens
- **Managers**: Application-wide managers for specific functionality

## Key Features

1. **Voice Journaling**: Record, manage, and play voice journals with emotional check-ins
2. **Emotional Check-ins**: Track emotional states before and after journaling
3. **Tool Library**: Access self-regulation tools categorized by purpose
4. **Progress Tracking**: Visualize emotional trends and track usage streaks
5. **End-to-End Encryption**: Secure all sensitive user data with AES-256-GCM encryption

## Architecture

The application uses a coordinator pattern for navigation flow and MVVM (Model-View-ViewModel) architecture for screens:

- **Coordinators**: Manage navigation flow between screens
- **ViewModels**: Handle business logic and data preparation for views
- **Views**: Display UI and forward user actions to ViewModels
- **Services**: Provide functionality to ViewModels and handle API communication
- **Dependency Injection**: Manage service dependencies with DIContainer

## Security Implementation

Security is a core focus of the application:

- **End-to-End Encryption**: Voice recordings are encrypted with AES-256-GCM
- **Key Management**: User-controlled encryption keys stored in the Secure Enclave
- **Secure Storage**: Sensitive data stored in the Keychain
- **Network Security**: Certificate pinning and TLS 1.3 for API communication
- **Authentication**: JWT tokens with secure storage and refresh mechanism

## Dependencies

Key third-party libraries used in the project:

- **Alamofire**: Networking and API communication
- **KeychainAccess**: Secure storage for sensitive data
- **SwiftJWT**: JWT token handling for authentication
- **RxSwift/RxCocoa**: Reactive programming
- **Charts**: Visualization for emotional trends
- **lottie-ios**: Animations for loading and feedback states
- **Firebase**: Analytics, crash reporting, and push notifications
- **Sentry**: Error monitoring and reporting

## Testing

The project includes comprehensive testing:

- **Unit Tests**: Test individual components with Quick and Nimble
- **Integration Tests**: Test component interactions
- **UI Tests**: Test user flows with XCUITest
- **Snapshot Tests**: Verify UI appearance across devices

## Coding Standards

- Follow Swift style guide and best practices
- Use SwiftLint for code quality enforcement
- Write meaningful commit messages
- Document public APIs with documentation comments
- Write tests for new functionality

## Build and Deployment

- **Development**: Local testing and debugging
- **Testing**: TestFlight distribution for internal testing
- **Production**: App Store distribution

Fastlane is configured for automated build and deployment processes.

## Localization

The application is primarily in Spanish with support for regional variations. Localization is managed through `.strings` files and follows Apple's localization best practices.

## Accessibility

The application is designed to be accessible to all users:

- VoiceOver support for screen reading
- Dynamic Type for text scaling
- Sufficient color contrast for readability
- Haptic feedback for important interactions

## Troubleshooting

Common issues and their solutions:

- **Pod installation issues**: Try `pod repo update` and then `pod install` again
- **Build errors**: Ensure Xcode version is compatible and all dependencies are installed
- **Runtime crashes**: Check Sentry dashboard for detailed crash reports

## Contributing

1. Create a feature branch from `develop`
2. Implement your changes with tests
3. Ensure all tests pass and code meets quality standards
4. Submit a pull request with a detailed description of changes

## License

This project is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.