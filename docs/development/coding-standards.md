# Amira Wellness Coding Standards

## Introduction

This document outlines the coding standards and best practices for the Amira Wellness application. Following these guidelines ensures code consistency, maintainability, and security across all components of the application. These standards apply to all developers working on the project, regardless of which part of the application they are developing.

## General Principles

- **Privacy First**: Always prioritize user privacy in code design and implementation
- **Security by Design**: Incorporate security best practices from the beginning
- **Readability**: Write code that is easy to read and understand
- **Maintainability**: Structure code to be maintainable over time
- **Testability**: Design code to be easily testable
- **Documentation**: Document code thoroughly, especially complex logic
- **Performance**: Consider performance implications of code changes

## Version Control

### Git Workflow

- Use feature branches for all changes
- Branch naming convention: `feature/feature-name`, `bugfix/issue-description`, `hotfix/issue-description`
- Keep commits focused and atomic
- Write meaningful commit messages that explain the why, not just the what
- Rebase feature branches on main before creating pull requests
- Squash commits when appropriate before merging

### Pull Requests

- Follow the PR template provided in `.github/PULL_REQUEST_TEMPLATE.md`
- PRs should address a single concern or feature
- Include tests for all new functionality
- Update documentation as needed
- Ensure all CI checks pass before requesting review
- Require at least one approval before merging
- Address all review comments before merging

## Python (Backend) Standards

### Code Style

- Follow PEP 8 style guide
- Use 4 spaces for indentation (no tabs)
- Maximum line length of 88 characters (Black formatter standard)
- Use snake_case for variables, functions, and file names
- Use PascalCase for class names
- Use UPPER_CASE for constants
- Group imports in the following order:
  1. Standard library imports
  2. Related third-party imports
  3. Local application/library specific imports
- Within each group, imports should be in alphabetical order
- Use absolute imports for clarity

### Documentation

- Use docstrings for all modules, classes, and functions
- Follow Google-style docstring format
- Include type hints for function parameters and return values
- Document exceptions that may be raised
- Keep docstrings up to date with code changes

### Testing

- Write unit tests for all new functionality
- Aim for at least 90% code coverage for core business logic
- Use pytest as the testing framework
- Organize tests to mirror the structure of the application code
- Use descriptive test names that explain what is being tested
- Use fixtures and mocks appropriately to isolate tests
- Include both positive and negative test cases

### Error Handling

- Use custom exception classes for different error categories
- Handle exceptions at the appropriate level
- Provide meaningful error messages
- Log exceptions with appropriate context
- Don't catch exceptions without handling them properly
- Use finally blocks for cleanup when necessary

### Security Practices

- Never store sensitive information (passwords, keys) in code
- Use environment variables or secure vaults for configuration
- Validate all user input
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization checks
- Follow the principle of least privilege
- Use secure defaults for all security-related settings

## Swift (iOS) Standards

### Code Style

- Follow Swift API Design Guidelines
- Use 4 spaces for indentation (no tabs)
- Use camelCase for variables and function names
- Use PascalCase for types and protocols
- Use UPPER_CASE for static constants
- Group imports alphabetically
- Keep files under 400 lines when possible; split larger files into logical components
- Use Swift's type inference where it enhances readability
- Prefer let over var when the value won't change

### Documentation

- Use Swift-style documentation comments (///) for all public interfaces
- Include parameter and return value descriptions
- Document thrown errors
- Use markdown formatting in documentation comments
- Keep documentation up to date with code changes

### Architecture

- Follow MVVM architecture pattern
- Use SwiftUI for new UI components
- Use Combine for reactive programming
- Implement dependency injection for testability
- Use protocols to define interfaces between components
- Keep view controllers and view models focused on a single responsibility

### Testing

- Write unit tests for all business logic
- Use XCTest framework for unit and UI testing
- Mock dependencies for isolated testing
- Test both success and failure paths
- Use test helpers and factories to reduce test code duplication
- Aim for at least 80% code coverage for business logic

### Security Practices

- Use the Keychain for storing sensitive information
- Implement proper authentication checks
- Use App Transport Security for network requests
- Implement certificate pinning for critical API endpoints
- Use the Secure Enclave for biometric authentication
- Sanitize data before logging
- Implement proper error handling to avoid information leakage

## Kotlin (Android) Standards

### Code Style

- Follow Kotlin coding conventions
- Use 4 spaces for indentation (no tabs)
- Use camelCase for variables and function names
- Use PascalCase for classes and interfaces
- Use UPPER_CASE for constants
- Maximum line length of 100 characters
- Group imports alphabetically
- Prefer val over var when the value won't change
- Use expression bodies for simple functions

### Documentation

- Use KDoc comments for all public interfaces
- Include parameter and return value descriptions
- Document thrown exceptions
- Use markdown formatting in documentation comments
- Keep documentation up to date with code changes

### Architecture

- Follow MVVM architecture pattern
- Use Jetpack Compose for new UI components
- Use Kotlin Coroutines and Flow for asynchronous operations
- Implement dependency injection using Hilt
- Use interfaces to define contracts between components
- Keep view models focused on a single responsibility
- Use use cases for business logic

### Testing

- Write unit tests for all business logic
- Use JUnit and Mockito for unit testing
- Use Espresso for UI testing
- Mock dependencies for isolated testing
- Test both success and failure paths
- Use test helpers and factories to reduce test code duplication
- Aim for at least 80% code coverage for business logic

### Security Practices

- Use the Android Keystore for storing sensitive information
- Implement proper authentication checks
- Use network security configuration for secure connections
- Implement certificate pinning for critical API endpoints
- Use biometric authentication when appropriate
- Sanitize data before logging
- Implement proper error handling to avoid information leakage

## Database Standards

### Schema Design

- Use meaningful table and column names
- Define appropriate constraints (NOT NULL, UNIQUE, etc.)
- Use foreign keys to enforce referential integrity
- Create indexes for frequently queried columns
- Use appropriate data types for columns
- Document table schemas and relationships

### Query Performance

- Write efficient queries that use indexes
- Avoid N+1 query problems
- Use query parameterization to prevent SQL injection
- Limit result sets to necessary data
- Use pagination for large result sets
- Monitor and optimize slow queries

### Migrations

- Use migration scripts for all schema changes
- Version all migrations
- Make migrations reversible when possible
- Test migrations thoroughly before deployment
- Document migration changes
- Consider data volume when planning migrations

## API Standards

### RESTful Design

- Follow RESTful principles for API design
- Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- Use meaningful resource names
- Use consistent URL patterns
- Implement proper status codes
- Version APIs in the URL (e.g., /v1/resource)
- Document all API endpoints

### Request/Response Format

- Use JSON for request and response bodies
- Use consistent field naming (camelCase)
- Include appropriate metadata in responses
- Implement pagination for list endpoints
- Use standard error response format
- Validate request data
- Sanitize response data

### Security

- Require authentication for protected endpoints
- Implement proper authorization checks
- Use HTTPS for all API traffic
- Implement rate limiting
- Validate and sanitize all input
- Implement proper error handling
- Use secure headers (CORS, Content-Security-Policy, etc.)

## Privacy and Security Standards

### Data Protection

- Implement end-to-end encryption for sensitive data
- Use AES-256-GCM for encryption
- Store encryption keys securely
- Implement proper key rotation
- Minimize data collection
- Implement data retention policies
- Provide data export and deletion functionality

### Authentication and Authorization

- Use secure authentication mechanisms
- Implement proper password policies
- Use JWT for authentication tokens
- Implement token expiration and refresh
- Use role-based access control
- Implement proper session management
- Log authentication events

### Secure Coding

- Validate all user input
- Sanitize output to prevent XSS
- Use parameterized queries to prevent SQL injection
- Implement proper error handling
- Use secure random number generation
- Keep dependencies up to date
- Follow the principle of least privilege

## Code Review Guidelines

- Review code for functionality, readability, and maintainability
- Verify that code follows the established standards
- Check for security vulnerabilities
- Ensure proper error handling
- Verify that tests are included and pass
- Look for edge cases that might not be handled
- Provide constructive feedback
- Approve only when all issues are addressed

## Continuous Integration

- All code must pass automated tests before merging
- Run linters and formatters to ensure code style compliance
- Check for security vulnerabilities in dependencies
- Measure and maintain code coverage
- Perform static code analysis
- Run performance tests for critical components
- Generate documentation from code comments

## Appendix: Tools and Resources

### Python Tools

- **Linting**: flake8, pylint
- **Formatting**: black, isort
- **Type Checking**: mypy
- **Testing**: pytest
- **Documentation**: Sphinx

### Swift Tools

- **Linting**: SwiftLint
- **Formatting**: SwiftFormat
- **Testing**: XCTest
- **Documentation**: DocC

### Kotlin Tools

- **Linting**: ktlint, detekt
- **Testing**: JUnit, Espresso
- **Documentation**: Dokka

### CI/CD Tools

- **CI/CD**: GitHub Actions
- **Code Coverage**: SonarQube
- **Security Scanning**: Snyk, OWASP Dependency Check
- **Performance Testing**: JMeter