# Contributing to Amira Wellness

Thank you for your interest in contributing to Amira Wellness! This document provides guidelines and instructions for contributing to our emotional wellness application.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing to the project. We expect all contributors to adhere to these guidelines to ensure a positive and inclusive environment.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment following instructions in [docs/development/setup.md](docs/development/setup.md)
4. Create a new branch for your feature or bugfix
5. Make your changes
6. Test your changes thoroughly
7. Submit a pull request

## Development Environment

Please refer to the setup instructions in [docs/development/setup.md](docs/development/setup.md) for detailed information on setting up your development environment for backend, iOS, and Android development.

## Coding Standards

We follow specific coding standards for each part of the application:

- **Backend (Python)**: Follow PEP 8 style guide and use type hints
- **iOS (Swift)**: Follow the Swift API Design Guidelines and SwiftLint rules
- **Android (Kotlin)**: Follow Kotlin Coding Conventions and use ktlint

More detailed coding standards can be found in [docs/development/coding-standards.md](docs/development/coding-standards.md).

## Commit Guidelines

- Use clear, descriptive commit messages
- Start with a verb in the present tense (e.g., "Add", "Fix", "Update")
- Reference issue numbers when applicable (e.g., "Fix #123: Resolve audio recording issue")
- Keep commits focused on a single change
- Squash multiple commits if they address the same issue

## Branch Naming

Use the following naming convention for branches:

- `feature/short-description` for new features
- `bugfix/short-description` for bug fixes
- `hotfix/short-description` for critical fixes
- `docs/short-description` for documentation changes
- `refactor/short-description` for code refactoring

## Pull Request Process

1. Ensure your code follows our coding standards
2. Update documentation if necessary
3. Include tests for new functionality
4. Ensure all tests pass locally
5. Fill out the pull request template completely
6. Request review from appropriate team members
7. Address any feedback from reviewers

More details on the PR process can be found in [docs/development/pr-process.md](docs/development/pr-process.md).

## Testing

All contributions should include appropriate tests:

- **Backend**: Unit tests with pytest, integration tests for API endpoints
- **iOS**: Unit tests with XCTest, UI tests for critical flows
- **Android**: Unit tests with JUnit, UI tests with Espresso

Aim for high test coverage, especially for critical components like encryption, audio processing, and data handling. More information on testing can be found in [docs/development/testing.md](docs/development/testing.md).

## Security Considerations

Given the sensitive nature of emotional wellness data, security is a top priority:

- Never commit secrets, API keys, or credentials
- Follow the encryption guidelines in [docs/security/encryption.md](docs/security/encryption.md)
- Adhere to privacy-by-design principles
- Use secure coding practices to prevent common vulnerabilities
- Report security concerns immediately via our [security policy](SECURITY.md)

## Localization

Amira Wellness is primarily focused on Spanish-speaking users:

- Ensure all user-facing strings are localizable
- Use the localization helper script for managing translations: `scripts/localization-helper.py`
- Test your changes with Spanish language settings

## Documentation

Update relevant documentation when making changes:

- API documentation for backend changes
- Code comments for complex logic
- README updates for significant features
- Architecture documentation for structural changes

## Continuous Integration

Our CI pipeline will automatically run on your pull request:

- Code style checks
- Unit and integration tests
- Security scans
- Build verification

All CI checks must pass before a pull request can be merged.

## License

By contributing to Amira Wellness, you agree that your contributions will be licensed under the project's license. See the [LICENSE](LICENSE) file for details.

## Questions?

If you have any questions about contributing, please open an issue with the 'question' label or contact the project maintainers directly.