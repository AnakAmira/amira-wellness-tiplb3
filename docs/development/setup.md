---
title: Development Environment Setup
---

## Introduction
This document provides comprehensive instructions for setting up the development environment for the Amira Wellness application. The application consists of multiple components that require different development environments:

- Backend API services (Python/FastAPI)
- iOS mobile application (Swift/SwiftUI)
- Android mobile application (Kotlin/Jetpack Compose)

Following these setup instructions will ensure that you have a consistent development environment that aligns with the project's requirements and coding standards. This guide assumes basic familiarity with software development tools and practices.

## Prerequisites
Before setting up the specific development environments, ensure you have the following general tools and access:

### General Tools
- **Git**: Version 2.30.0 or higher
- **GitHub Account**: With access to the Amira Wellness repositories
- **Code Editor/IDE**: Visual Studio Code, IntelliJ IDEA, or similar
- **Terminal**: Command-line interface for your operating system
- **SSH Keys**: Configured for GitHub authentication
- **AWS CLI**: Version 2.x (for backend development)
- **Docker**: Version 20.10.x or higher (for backend development)
- **Docker Compose**: Version 2.x (for backend development)

### Access Requirements
Ensure you have been granted access to the following resources:

- GitHub repositories for the project
- Development AWS account (for backend developers)
- Apple Developer account (for iOS developers)
- Google Play Developer account (for Android developers)
- Project management tools (Jira, Confluence, etc.)
- Team communication channels (Slack, Microsoft Teams, etc.)

## Repository Structure
The Amira Wellness application code is organized into the following repositories:

### Main Repositories
- **amira-backend**: Backend API services and infrastructure code
- **amira-ios**: iOS mobile application
- **amira-android**: Android mobile application
- **amira-docs**: Documentation and architecture specifications
- **amira-infrastructure**: Infrastructure as Code (Terraform, CloudFormation)

### Cloning Repositories
Clone the repositories you need for your development work:

```bash
# For backend development
git clone git@github.com:amira-wellness/amira-backend.git

# For iOS development
git clone git@github.com:amira-wellness/amira-ios.git

# For Android development
git clone git@github.com:amira-wellness/amira-android.git

# For documentation
git clone git@github.com:amira-wellness/amira-docs.git
```

### Branch Strategy
The project follows a GitFlow-based branching strategy:

- **main**: Production-ready code that has been released
- **develop**: Integration branch for features being developed for the next release
- **feature/\***: Feature branches for active development work
- **release/\***: Release candidate branches for testing
- **hotfix/\***: Branches for critical production fixes

When starting new work, always branch from `develop` and create a feature branch with a descriptive name:

```bash
git checkout develop
git pull
git checkout -b feature/your-feature-name
```

## Backend Development Environment
The backend services are developed using Python with FastAPI. Follow these steps to set up your backend development environment:

### Python Setup
1. Install Python 3.11 or higher:
   - **macOS**: `brew install python@3.11`
   - **Linux**: `sudo apt install python3.11 python3.11-dev python3.11-venv`
   - **Windows**: Download and install from [python.org](https://www.python.org/downloads/)

2. Verify the installation:
   ```bash
   python3 --version
   # Should output Python 3.11.x or higher
   ```

3. Install pipenv for dependency management:
   ```bash
   pip3 install pipenv
   ```

### Backend Project Setup
1. Navigate to the backend repository:
   ```bash
   cd amira-backend
   ```

2. Create a virtual environment and install dependencies:
   ```bash
   pipenv install --dev
   ```

3. Activate the virtual environment:
   ```bash
   pipenv shell
   ```

4. Create a `.env` file for local development (copy from `.env.example`):
   ```bash
   cp .env.example .env
   ```

5. Update the `.env` file with your local configuration values.

### Database Setup
1. Install PostgreSQL:
   - **macOS**: `brew install postgresql@15`
   - **Linux**: `sudo apt install postgresql-15`
   - **Windows**: Download and install from [postgresql.org](https://www.postgresql.org/download/)

2. Start PostgreSQL service:
   - **macOS**: `brew services start postgresql@15`
   - **Linux**: `sudo systemctl start postgresql`
   - **Windows**: PostgreSQL is installed as a service and should start automatically

3. Create a database for development:
   ```bash
   createdb amira_dev
   ```

4. Run database migrations:
   ```bash
   alembic upgrade head
   ```

5. Seed the database with initial data:
   ```bash
   python -m scripts.seed_db
   ```

### Docker Setup
For containerized development and testing:

1. Ensure Docker and Docker Compose are installed:
   - **macOS/Windows**: Install Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)
   - **Linux**: Follow the [installation instructions](https://docs.docker.com/engine/install/) for your distribution

2. Build and start the containers:
   ```bash
   docker-compose up -d
   ```

3. Verify the containers are running:
   ```bash
   docker-compose ps
   ```

This will start the following services:
- API service on port 8000
- PostgreSQL database on port 5432
- Redis cache on port 6379
- MongoDB for content storage on port 27017

### Running the Backend Locally
1. With the virtual environment activated, run the development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

2. Access the API documentation at http://localhost:8000/docs

3. Run tests to verify your setup:
   ```bash
   pytest
   ```

### Backend Development Tools
Install and configure these recommended tools for backend development:

1. **Code Formatting**:
   ```bash
   pip install black isort
   ```

2. **Linting**:
   ```bash
   pip install flake8 mypy
   ```

3. **Pre-commit Hooks**:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

4. **API Testing**:
   - Install [Postman](https://www.postman.com/downloads/) or [Insomnia](https://insomnia.rest/download)
   - Import the API collection from `docs/api/amira-api-collection.json`

## iOS Development Environment
The iOS application is developed using Swift and SwiftUI. Follow these steps to set up your iOS development environment:

### macOS Requirements
iOS development requires a Mac running macOS Monterey (12.0) or later with the following specifications:

- Intel or Apple Silicon processor
- 16GB RAM recommended (8GB minimum)
- 50GB available disk space
- macOS Monterey (12.0) or later

### Xcode Setup
1. Install Xcode 14.0 or later from the Mac App Store or [Apple Developer website](https://developer.apple.com/xcode/)

2. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

3. Verify the installation:
   ```bash
   xcode-select -p
   # Should output something like /Applications/Xcode.app/Contents/Developer
   ```

4. Configure Xcode preferences:
   - Open Xcode
   - Go to Preferences > Accounts
   - Add your Apple ID and team membership

### iOS Project Setup
1. Navigate to the iOS repository:
   ```bash
   cd amira-ios
   ```

2. Install CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```

3. Install project dependencies:
   ```bash
   cd AmiraWellness
   pod install
   ```

4. Open the workspace in Xcode:
   ```bash
   open AmiraWellness.xcworkspace
   ```

5. Create a `Config/Development.xcconfig` file (copy from `Config/Development.xcconfig.example`):
   ```bash
   cp Config/Development.xcconfig.example Config/Development.xcconfig
   ```

6. Update the configuration file with your development settings.

### Running the iOS Application
1. In Xcode, select a simulator or connected device

2. Select the "AmiraWellness" scheme

3. Click the Run button (▶️) or press Cmd+R

4. The application should build and launch on the selected device/simulator

### iOS Development Tools
Install and configure these recommended tools for iOS development:

1. **SwiftLint** for code style enforcement:
   ```bash
   brew install swiftlint
   ```

2. **SwiftFormat** for code formatting:
   ```bash
   brew install swiftformat
   ```

3. **Fastlane** for automation:
   ```bash
   brew install fastlane
   ```

4. **Tuist** (optional) for project generation:
   ```bash
   curl -Ls https://install.tuist.io | bash
   ```

### iOS Testing Setup
1. Run unit tests in Xcode:
   - Press Cmd+U or select Product > Test

2. Run UI tests:
   - Select the UI test target
   - Press Cmd+U

3. Configure code coverage:
   - In the scheme editor, enable code coverage for the test action

## Android Development Environment
The Android application is developed using Kotlin and Jetpack Compose. Follow these steps to set up your Android development environment:

### System Requirements
Android development can be done on Windows, macOS, or Linux with the following specifications:

- 64-bit operating system
- 16GB RAM recommended (8GB minimum)
- 50GB available disk space
- 1280 x 800 minimum screen resolution

### Android Studio Setup
1. Download and install [Android Studio](https://developer.android.com/studio) (latest stable version)

2. During installation, ensure the following components are selected:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
   - Performance (Intel HAXM or equivalent)

3. Launch Android Studio and complete the setup wizard

4. Install additional SDK components:
   - Open SDK Manager (Tools > SDK Manager)
   - Select the "SDK Platforms" tab
   - Check Android 13 (API Level 33) and Android 8.0 (API Level 26)
   - Select the "SDK Tools" tab
   - Check Android SDK Build-Tools, Android Emulator, and Android SDK Platform-Tools
   - Click "Apply" to install the selected components

### Android Project Setup
1. Navigate to the Android repository:
   ```bash
   cd amira-android
   ```

2. Open the project in Android Studio:
   - Select "Open an existing Android Studio project"
   - Navigate to the amira-android directory
   - Click "Open"

3. Let Android Studio sync the project and download dependencies

4. Create a `local.properties` file if it doesn't exist:
   ```bash
   touch local.properties
   ```

5. Add the path to your Android SDK in `local.properties`:
   ```properties
   sdk.dir=/path/to/your/android/sdk
   ```

6. Create a `app/src/main/assets/config.properties` file (copy from `config.properties.example`):
   ```bash
   cp app/src/main/assets/config.properties.example app/src/main/assets/config.properties
   ```

7. Update the configuration file with your development settings.

### Running the Android Application
1. Create an Android Virtual Device (AVD):
   - Open AVD Manager (Tools > AVD Manager)
   - Click "Create Virtual Device"
   - Select a device definition (e.g., Pixel 6)
   - Select a system image (API level 33 recommended)
   - Complete the AVD creation process

2. Run the application:
   - Select the "app" configuration
   - Select your AVD or connected device
   - Click the Run button (▶️) or press Shift+F10

3. The application should build and launch on the selected device/emulator

### Android Development Tools
Install and configure these recommended tools for Android development:

1. **ktlint** for code style enforcement:
   ```bash
   brew install ktlint  # macOS
   # or
   curl -sSLO https://github.com/pinterest/ktlint/releases/download/0.45.2/ktlint && chmod +x ktlint && sudo mv ktlint /usr/local/bin/  # Linux/Windows
   ```

2. **Gradle** tasks for code quality:
   ```bash
   ./gradlew detekt  # Static analysis
   ./gradlew ktlintCheck  # Code style check
   ```

3. **Git hooks** for pre-commit checks:
   ```bash
   ./gradlew installGitHooks
   ```

### Android Testing Setup
1. Run unit tests:
   ```bash
   ./gradlew test
   ```

2. Run instrumented tests:
   ```bash
   ./gradlew connectedAndroidTest
   ```

3. Generate code coverage report:
   ```bash
   ./gradlew jacocoTestReport
   ```

## Security Tools Setup
The Amira Wellness application has strict security requirements, particularly for end-to-end encryption. Set up the following security tools for development:

### Encryption Development Tools
1. **OpenSSL** for certificate generation and testing:
   - **macOS**: `brew install openssl`
   - **Linux**: `sudo apt install openssl`
   - **Windows**: Download from [openssl.org](https://www.openssl.org/source/)

2. **Key Management Tools**:
   - For iOS: Use the Keychain Access app and Security framework
   - For Android: Use the Android Keystore System
   - For backend: AWS KMS (configured through AWS CLI)

3. **Security Testing Tools**:
   ```bash
   # Install OWASP ZAP for API security testing
   brew install --cask owasp-zap  # macOS
   # or download from https://www.zaproxy.org/download/
   
   # Install Burp Suite Community Edition
   brew install --cask burp-suite  # macOS
   # or download from https://portswigger.net/burp/communitydownload
   ```

### Certificate Setup for Development
1. Generate a self-signed certificate for local development:
   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt
   ```

2. Configure your local environment to trust this certificate:
   - **macOS**: Add to Keychain Access and set to "Always Trust"
   - **Windows**: Import to Certificate Manager
   - **Linux**: Add to system certificates

3. Configure the backend to use HTTPS in development:
   - Update your `.env` file with the paths to your certificate files
   - Restart the development server with HTTPS enabled

### Security Scanning Tools
1. **Backend Security Scanning**:
   ```bash
   # Install bandit for Python security scanning
   pip install bandit
   
   # Run security scan
   bandit -r app/
   ```

2. **Dependency Scanning**:
   ```bash
   # For Python
   pip install safety
   safety check
   
   # For iOS
   brew install dependency-check
   dependency-check --scan AmiraWellness
   
   # For Android
   ./gradlew dependencyCheckAnalyze
   ```

3. **Secret Detection**:
   ```bash
   # Install git-secrets
   brew install git-secrets  # macOS
   
   # Configure git-secrets
   git secrets --install
   git secrets --register-aws
   ```

## Continuous Integration Setup
The Amira Wellness project uses GitHub Actions for continuous integration. Set up your local environment to work with the CI pipeline:

### GitHub Actions Local Testing
1. Install [act](https://github.com/nektos/act) for local GitHub Actions testing:
   ```bash
   # macOS
   brew install act
   
   # Linux/Windows
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   ```

2. Run GitHub Actions workflows locally:
   ```bash
   # Run all workflows
   act
   
   # Run a specific workflow
   act -j build
   ```

### Pre-commit Checks
Ensure your code passes all checks before committing:

1. **Backend Checks**:
   ```bash
   # Format code
   black app/
   isort app/
   
   # Run linters
   flake8 app/
   mypy app/
   
   # Run tests
   pytest
   ```

2. **iOS Checks**:
   ```bash
   # Run SwiftLint
   swiftlint
   
   # Run tests
   xcodebuild test -workspace AmiraWellness.xcworkspace -scheme AmiraWellness -destination 'platform=iOS Simulator,name=iPhone 14'
   ```

3. **Android Checks**:
   ```bash
   # Run ktlint
   ./gradlew ktlintCheck
   
   # Run detekt
   ./gradlew detekt
   
   # Run tests
   ./gradlew test
   ```

### CI/CD Pipeline Overview
The CI/CD pipeline includes the following stages:

1. **Build**: Compiles the code and creates artifacts
2. **Test**: Runs unit and integration tests
3. **Analyze**: Performs static code analysis and security scanning
4. **Deploy**: Deploys to development/staging environments

Familiarize yourself with the workflow files in the `.github/workflows/` directory of each repository to understand the CI/CD process.

## Development Workflow
Follow these steps for the standard development workflow:

### Feature Development
1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Implement your changes following the project's coding standards

3. Commit your changes with meaningful commit messages:
   ```bash
   git add .
   git commit -m "feat(component): add feature description"
   ```

4. Push your branch to GitHub:
   ```bash
   git push -u origin feature/your-feature-name
   ```

### Pull Request Process
1. Go to the repository on GitHub and create a new pull request

2. Set the base branch to `develop` and the compare branch to your feature branch

3. Add a descriptive title and detailed description of your changes

4. Fill out the pull request template with:
   - Summary of changes
   - Related issue numbers
   - Testing performed
   - Screenshots or recordings (if applicable)

5. Request reviews from appropriate team members

6. Address review comments and update your pull request

7. Once approved, merge your changes using the "Squash and merge" option

8. Delete your feature branch after it's merged

### Release Process
1. Release branches are created from `develop` with the naming convention `release/v{version}`

2. Only bug fixes are committed directly to release branches

3. After testing in the staging environment, release branches are merged into `main`

4. The `main` branch is tagged with the version number using semantic versioning (e.g., `v1.2.3`)

5. Hotfixes for production issues are created from `main` with the naming convention `hotfix/v{version}.{patch}`

6. After verification, hotfixes are merged into both `main` and `develop`

### Coding Standards
All code contributions should follow these key principles:

1. **Code Style**:
   - Follow language-specific conventions (PEP 8 for Python, Swift API Design Guidelines, Kotlin Coding Conventions)
   - Use consistent indentation (4 spaces for Python, 4 spaces for Swift, 4 spaces for Kotlin)
   - Keep line length reasonable (120 characters maximum)

2. **Naming Conventions**:
   - Use descriptive names for variables, functions, and classes
   - Follow language-specific naming conventions (snake_case for Python, camelCase for Swift/Kotlin variables, PascalCase for Swift/Kotlin types)
   - Avoid abbreviations unless widely understood

3. **Documentation**:
   - Document all public APIs
   - Include docstrings/comments for complex logic
   - Keep documentation up-to-date with code changes

4. **Testing**:
   - Write unit tests for all new functionality
   - Maintain or improve code coverage
   - Test edge cases and error conditions

5. **Error Handling**:
   - Handle all potential errors
   - Provide meaningful error messages
   - Fail gracefully with appropriate user feedback

## Troubleshooting
Common issues and their solutions:

### Backend Issues
1. **Database connection errors**:
   - Verify PostgreSQL is running: `pg_isready`
   - Check database credentials in `.env` file
   - Ensure the database exists: `psql -l`

2. **Dependency issues**:
   - Recreate the virtual environment: `pipenv --rm && pipenv install --dev`
   - Update dependencies: `pipenv update`

3. **Migration errors**:
   - Reset migrations: `alembic downgrade base`
   - Apply migrations: `alembic upgrade head`

### iOS Issues
1. **Pod installation failures**:
   - Update CocoaPods: `sudo gem install cocoapods`
   - Delete Pods directory and reinstall: `rm -rf Pods && pod install`

2. **Build errors**:
   - Clean the build folder: Product > Clean Build Folder (Shift+Cmd+K)
   - Reset the simulator: Device > Erase All Content and Settings

3. **Code signing issues**:
   - Verify your Apple Developer account in Xcode
   - Check the signing configuration in project settings
   - Use automatic signing for development

### Android Issues
1. **Gradle sync failures**:
   - Refresh Gradle: File > Sync Project with Gradle Files
   - Clean project: Build > Clean Project
   - Invalidate caches: File > Invalidate Caches / Restart

2. **Emulator issues**:
   - Update Android Studio and SDK tools
   - Verify hardware acceleration is enabled
   - Create a new AVD with a different system image

3. **Dependency conflicts**:
   - Run `./gradlew app:dependencies` to view the dependency tree
   - Add resolution strategy in `build.gradle` for conflicting dependencies

### Git Issues
1. **Merge conflicts**:
   - Update your branch with the latest changes: `git pull origin develop`
   - Resolve conflicts manually
   - Use a merge tool: `git mergetool`

2. **Permission issues**:
   - Verify your SSH key is added to GitHub
   - Check repository access permissions

3. **Large file issues**:
   - Use Git LFS for large files
   - Avoid committing build artifacts and dependencies

## Additional Resources
Refer to these additional resources for more information:

### Documentation
- [Architecture Overview](../architecture/overview.md): System architecture and component interactions
- [Backend Architecture](../architecture/backend.md): Detailed backend design
- [Mobile Architecture](../architecture/mobile.md): iOS and Android application architecture
- [Security Architecture](../architecture/security.md): Security implementation details
- [API Documentation](../api/): API specifications and usage guidelines

### Learning Resources
- **Python/FastAPI**:
  - [FastAPI Documentation](https://fastapi.tiangolo.com/)
  - [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
  - [Alembic Documentation](https://alembic.sqlalchemy.org/)

- **iOS/Swift**:
  - [Swift Documentation](https://swift.org/documentation/)
  - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
  - [Combine Documentation](https://developer.apple.com/documentation/combine)

- **Android/Kotlin**:
  - [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
  - [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
  - [Android Developer Guides](https://developer.android.com/guide)

### Team Resources
- **Communication Channels**:
  - Slack: #amira-dev, #amira-ios, #amira-android, #amira-backend
  - Weekly Team Meetings: Tuesdays at 10:00 AM (PST)
  - Technical Discussion: Thursdays at 2:00 PM (PST)

- **Project Management**:
  - Jira Board: [Amira Wellness Project](https://amira-wellness.atlassian.net/)
  - Documentation: [Confluence Space](https://amira-wellness.atlassian.net/wiki/)

- **Design Resources**:
  - Figma Designs: [Amira Wellness Design System](https://www.figma.com/file/amira-wellness-design/)
  - Design Guidelines: [Amira Design Guidelines](https://amira-wellness.atlassian.net/wiki/design-guidelines)

## Conclusion
This setup guide provides the necessary instructions to establish your development environment for the Amira Wellness application. By following these steps, you should have a fully functional environment for backend, iOS, and/or Android development.

If you encounter any issues not covered in the troubleshooting section, please reach out to the development team through the appropriate communication channels.

Remember to follow the project's coding standards and development workflow to ensure consistent, high-quality contributions to the Amira Wellness application.