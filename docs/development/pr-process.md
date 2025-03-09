---
title: PR Process
---

## Introduction

This document outlines the pull request (PR) process for the Amira Wellness application. Following a standardized PR process ensures code quality, maintains security standards, and facilitates efficient collaboration among team members.

The Amira Wellness application handles sensitive emotional data, making it critical that all code changes undergo thorough review and testing before being merged into the main codebase. This document provides guidelines for creating, reviewing, and merging pull requests across all components of the application (backend, iOS, and Android).

## Pull Request Workflow

The pull request workflow follows these general steps:

### 1. Branch Creation

All development work should be done in feature branches created from the main development branch.

**Branch Naming Convention:**
- `feature/feature-name` - For new features
- `bugfix/issue-description` - For bug fixes
- `hotfix/issue-description` - For critical fixes that need to be applied to production
- `docs/description` - For documentation updates
- `refactor/description` - For code refactoring without functional changes

**Example:**
```bash
# Create a new feature branch
git checkout develop
git pull
git checkout -b feature/voice-journal-encryption
```

Ensure your branch is up-to-date with the latest changes from the target branch before creating a PR.

### 2. Commit Guidelines

Write clear, concise commit messages that explain the purpose of the change.

**Commit Message Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Changes to the build process or auxiliary tools

**Example:**
```
feat: implement end-to-end encryption for voice journals

Add AES-256-GCM encryption for voice journal recordings with client-side
key generation to ensure privacy of user data.

Resolves #123
```

**Guidelines:**
- Keep commits focused and atomic (one logical change per commit)
- Use present tense in commit messages
- Reference issue numbers in the footer when applicable
- Consider using interactive rebase to clean up commits before creating a PR

### 3. Pull Request Creation

When your changes are ready for review, create a pull request using the GitHub interface.

**Steps:**
1. Push your branch to the remote repository
2. Navigate to the repository on GitHub
3. Click "Pull Request"
4. Select your branch and the target branch (usually `develop` or `main`)
5. Fill out the PR template with all required information
6. Assign reviewers or let the CODEOWNERS file automatically assign them
7. Add relevant labels

**PR Template:**
The PR template (located at `.github/PULL_REQUEST_TEMPLATE.md`) includes sections for:
- Changes overview
- Related issues
- Type of change
- Testing performed
- Security considerations
- Privacy considerations
- Performance impact
- Screenshots/videos (if applicable)
- Additional notes
- Checklist of requirements

Ensure all sections are filled out appropriately before submitting the PR.

### 4. CI/CD Integration

All pull requests trigger automated CI/CD workflows that run tests, security scans, and other quality checks.

**Backend CI Workflow:**
The backend CI workflow (`.github/workflows/backend-ci.yml`) includes:
- Linting and static analysis
- Unit and integration tests
- Security scanning
- Code coverage reporting

**iOS CI Workflow:**
The iOS CI workflow (`.github/workflows/ios-ci.yml`) includes:
- SwiftLint checks
- Dependency vulnerability scanning
- Unit tests
- UI tests
- Build verification

**Android CI Workflow:**
The Android CI workflow (`.github/workflows/android-ci.yml`) includes:
- Kotlin linting
- Dependency vulnerability scanning
- Unit tests
- Instrumented tests
- Build verification

**Requirements:**
- All CI checks must pass before a PR can be merged
- Code coverage must meet minimum thresholds (90% for core services, 85% for UI components)
- No critical security vulnerabilities are allowed
- All linting issues must be resolved

### 5. Code Review

Code review is a critical part of the PR process to ensure code quality, knowledge sharing, and adherence to project standards.

**Reviewer Assignment:**
Reviewers are automatically assigned based on the CODEOWNERS file (`.github/CODEOWNERS`), which maps file paths to responsible teams or individuals. For example:
- Backend code is reviewed by the backend team
- iOS code is reviewed by the iOS team
- Android code is reviewed by the Android team
- Security-sensitive code requires review from the security team

**Review Guidelines:**
- Reviewers should respond to PR requests within 24 business hours
- Reviews should be thorough but constructive
- Focus on code quality, security, performance, and adherence to standards
- Use GitHub's review features (comments, suggestions, approvals)
- For complex changes, consider pair programming or in-person reviews

**Review Checklist:**
- Code follows project coding standards
- Tests are included and pass
- Security best practices are followed
- Privacy considerations are addressed
- Documentation is updated
- No unnecessary code or dependencies
- Error handling is appropriate
- Performance implications are considered

Refer to the [Coding Standards](./coding-standards.md) document for detailed code review guidelines.

### 6. Addressing Feedback

After receiving review feedback, address all comments and make necessary changes.

**Process:**
1. Review all feedback and ask for clarification if needed
2. Make requested changes in your branch
3. Respond to each comment indicating how it was addressed
4. Push the changes to update the PR
5. Request re-review if significant changes were made

**Guidelines:**
- Address all comments before requesting re-review
- If you disagree with a comment, explain your reasoning clearly
- For substantial changes, consider creating a new commit rather than amending existing ones
- Update the PR description if the scope of changes has evolved

### 7. Merge Requirements

Before a PR can be merged, it must meet the following requirements:

**Merge Criteria:**
- All CI checks pass
- Required number of approvals received (minimum 1, 2 for security-sensitive code)
- No unresolved comments or requested changes
- PR template is completely filled out
- Branch is up-to-date with the target branch

**Merge Methods:**
- **Squash and merge**: Preferred for feature branches with multiple small commits
- **Rebase and merge**: Used for branches with clean, well-structured commits
- **Merge commit**: Used for long-lived branches with many commits

**Post-Merge Actions:**
- Delete the branch after merging
- Update related issues and project boards
- Monitor the deployment pipeline for any issues
- Verify the changes in the test environment

## Special PR Types

Some pull requests require special handling due to their nature or impact.

### Security-Sensitive PRs

PRs that modify security-critical components require additional scrutiny.

**Examples of security-sensitive code:**
- Authentication and authorization
- Encryption implementation
- Data storage and handling
- API security controls
- Input validation and sanitization

**Requirements:**
- Must be reviewed by at least one member of the security team
- Must include appropriate security tests
- May require security impact assessment
- Should include documentation of security considerations

Security-sensitive PRs should be marked with the `security` label and explicitly mention security implications in the PR description.

### Privacy-Impacting PRs

PRs that affect user data collection, processing, or storage require privacy review.

**Examples of privacy-impacting changes:**
- Changes to data collection
- Modifications to data retention policies
- Updates to encryption methods
- Changes to data export or deletion functionality
- New analytics or tracking features

**Requirements:**
- Must be reviewed by a privacy champion or data protection officer
- Must include privacy impact assessment for significant changes
- Should document privacy considerations in the PR description

Privacy-impacting PRs should be marked with the `privacy` label and include detailed privacy considerations in the PR description.

### Hotfix PRs

Hotfixes address critical issues in production and follow an expedited process.

**Hotfix Process:**
1. Create a branch from the production branch (e.g., `main`)
2. Implement the minimal fix required
3. Create a PR with the `hotfix` label
4. Request expedited review
5. After approval, merge to production
6. Backport the fix to the development branch

**Requirements:**
- Must address a critical issue affecting users
- Should be minimal in scope
- Must include tests
- Requires approval from a senior team member

Hotfix PRs should include clear documentation of the issue being fixed and the impact on users.

### Large Refactoring PRs

Large refactoring efforts require special handling to ensure effective review.

**Guidelines for Large Refactorings:**
1. Break the refactoring into smaller, logical PRs when possible
2. Provide detailed context and rationale in the PR description
3. Consider scheduling a dedicated review session
4. Include before/after metrics (performance, code complexity, etc.)

**Requirements:**
- Must not change functionality
- Must maintain or improve test coverage
- Should include performance benchmarks if relevant
- May require approval from architecture team

Large refactoring PRs should be planned in advance and communicated to the team to ensure proper review resources are available.

## PR Best Practices

Following these best practices will help ensure smooth and efficient PR reviews:

### PR Size

Keep PRs small and focused on a single concern.

**Guidelines:**
- Aim for PRs under 500 lines of code when possible
- Break large features into smaller, logical PRs
- Each PR should address a single concern or feature
- Consider using feature flags for large features that need to be merged incrementally

**Benefits:**
- Easier to review thoroughly
- Faster review turnaround
- Reduced merge conflicts
- Easier to understand and test

### PR Description

Write clear, comprehensive PR descriptions that provide context and rationale.

**Components of a Good PR Description:**
- Clear summary of changes
- Rationale for the approach taken
- Links to relevant issues or documentation
- Testing instructions
- Screenshots or videos for UI changes
- Notes on any technical debt or follow-up work

**Example:**
```markdown
# Voice Journal Encryption Implementation

## Changes Overview
Implements end-to-end encryption for voice journal recordings using AES-256-GCM with client-side key generation.

## Related Issues
Fixes #123 - Implement end-to-end encryption for voice journals

## Type of Change
- [x] New feature (non-breaking change that adds functionality)
- [x] Security improvement

## Testing Performed
- [x] Unit tests for encryption/decryption
- [x] Integration tests for the full recording flow
- [x] Manual testing on iOS and Android

Added tests for key generation, encryption, decryption, and error handling. Verified that recordings cannot be decrypted without the correct key.

## Security Considerations
- [x] Changes include security-sensitive code (encryption)
- [x] Security review needed

Implements AES-256-GCM encryption with secure key derivation using PBKDF2. Keys are stored in the device's secure storage (Keychain for iOS, Keystore for Android) and never transmitted to the server.

## Performance Impact
- [x] Changes may affect application performance
- [x] Performance testing performed

Encryption adds approximately 200ms to the recording save process. This is acceptable and doesn't noticeably impact the user experience.

## Screenshots
[Screenshot of encryption settings UI]

## Additional Notes
This PR only implements encryption for new recordings. A follow-up PR will handle migrating existing recordings.
```

### Testing Requirements

Include appropriate tests for all changes.

**Testing Guidelines:**
- All new features must include unit tests
- Bug fixes should include regression tests
- UI changes should include UI tests when applicable
- Security changes must include security-focused tests
- Test edge cases and error conditions

**Types of Tests Required:**
- **Backend**: Unit tests, integration tests, API tests
- **iOS**: Unit tests, UI tests, performance tests
- **Android**: Unit tests, instrumented tests, UI tests

Refer to the [Testing Guidelines](./testing.md) document for detailed testing requirements and approaches.

### Documentation Updates

Update documentation to reflect code changes.

**Documentation Requirements:**
- Update API documentation for backend changes
- Update code comments for complex logic
- Update README files when necessary
- Update user-facing documentation for feature changes
- Include architecture diagrams for significant structural changes

**Documentation Locations:**
- Code comments (using standard formats: JSDoc, docstrings, etc.)
- API documentation (Swagger/OpenAPI)
- Markdown files in the `docs/` directory
- Wiki pages (for architectural and process documentation)

### Responding to Reviews

Respond to review comments professionally and constructively.

**Guidelines:**
- Respond to all comments, even if just to acknowledge
- Be open to feedback and suggestions
- Explain your reasoning when disagreeing with a comment
- Ask for clarification when needed
- Thank reviewers for their time and input

**Example Responses:**
- "Good catch, fixed in commit abc123."
- "I chose this approach because... Would you prefer an alternative approach?"
- "I'm not sure I understand the concern. Could you elaborate?"
- "Thanks for the suggestion! I've implemented it in the latest commit."

## Code Review Guidelines

Effective code reviews are critical to maintaining code quality and knowledge sharing.

### Review Mindset

Approach code reviews with a constructive and collaborative mindset.

**Guidelines:**
- Focus on the code, not the person
- Be respectful and professional in comments
- Provide specific, actionable feedback
- Acknowledge good practices and improvements
- Remember that the goal is to improve the codebase, not to find fault

**Example:**
Instead of: "This code is inefficient."
Try: "This loop could be optimized by using a Set instead of an Array to improve lookup performance."

### What to Look For

When reviewing code, consider the following aspects:

**Functionality:**
- Does the code work as intended?
- Does it handle edge cases and errors?
- Is it consistent with the requirements?

**Code Quality:**
- Does it follow coding standards and best practices?
- Is it readable and maintainable?
- Is there appropriate abstraction and encapsulation?
- Are there any code smells or anti-patterns?

**Security:**
- Are there potential security vulnerabilities?
- Is sensitive data handled properly?
- Is input validated and sanitized?
- Is authentication and authorization implemented correctly?

**Performance:**
- Are there potential performance issues?
- Are resources used efficiently?
- Are there any unnecessary computations or operations?

**Testing:**
- Are tests comprehensive and meaningful?
- Do they cover edge cases and error conditions?
- Is the test code itself well-structured?

**Documentation:**
- Is the code adequately documented?
- Are complex algorithms or decisions explained?
- Is the PR description complete and clear?

### Review Comments

Write clear, specific, and actionable review comments.

**Comment Types:**
- **Questions**: Asking for clarification or rationale
- **Suggestions**: Proposing alternative approaches
- **Issues**: Identifying problems that need to be fixed
- **Praise**: Acknowledging good work or improvements

**Comment Guidelines:**
- Be specific about what needs to change and why
- Provide examples or references when helpful
- Use GitHub's suggestion feature for simple fixes
- Distinguish between required changes and optional suggestions
- Group related comments together

**Example Comments:**
- "This method could benefit from additional error handling for network failures."
- "Consider using a more descriptive variable name here to improve readability."
- "Great job implementing the encryption with proper key management!"
- "This loop has O(n²) complexity. Consider using a HashMap to reduce it to O(n)."

### Review Workflow

Follow a structured workflow when reviewing PRs.

**Review Steps:**
1. Read the PR description to understand the context and purpose
2. Review the automated CI results
3. Check out the branch locally if needed for deeper testing
4. Review the code changes file by file
5. Test the changes if applicable
6. Provide feedback using GitHub's review features
7. Submit the review with appropriate approval status

**Approval Statuses:**
- **Approve**: Changes look good and are ready to merge
- **Comment**: Providing feedback without explicit approval or rejection
- **Request Changes**: Issues must be addressed before merging

**When to Approve:**
- The code works as intended
- It follows project standards and best practices
- Tests are adequate and pass
- No security or performance concerns
- Documentation is complete and accurate

## PR Metrics and Monitoring

Tracking PR metrics helps identify process improvements and bottlenecks.

### Key Metrics

The team tracks the following PR metrics:

**Process Metrics:**
- Time to first review
- Time to merge
- Number of review cycles
- PR size (lines of code)
- Review thoroughness (comments per line)

**Quality Metrics:**
- Test coverage changes
- Number of issues found in review
- Post-merge defects
- Code quality metrics (complexity, duplication, etc.)

**Target Values:**
- First review within 24 business hours
- Merge within 3 business days for standard PRs
- Maximum 2 review cycles for most PRs
- 90%+ test coverage for core functionality

### Continuous Improvement

The PR process is continuously evaluated and improved.

**Improvement Process:**
1. Regularly review PR metrics and identify bottlenecks
2. Collect feedback from team members on the PR process
3. Experiment with process changes to address issues
4. Measure the impact of changes
5. Document and standardize successful improvements

**Common Improvements:**
- Automating repetitive checks
- Refining code review guidelines
- Improving PR templates
- Enhancing CI/CD pipelines
- Providing additional training on code review best practices

## Tools and Resources

The following tools and resources support the PR process:

### GitHub Features

Utilize GitHub features to streamline the PR process.

**Useful Features:**
- **Draft PRs**: For work in progress that's not ready for review
- **Review Requests**: To explicitly request reviews from specific people
- **Suggested Changes**: To propose specific code changes
- **Review Required**: Branch protection to enforce review requirements
- **Status Checks**: To enforce CI passing before merge
- **Auto-merge**: To automatically merge when requirements are met

**GitHub Integrations:**
- **CodeQL**: For security vulnerability scanning
- **Dependabot**: For dependency vulnerability alerts
- **GitHub Actions**: For CI/CD workflows

### CI/CD Tools

CI/CD tools automate testing and deployment.

**Backend CI Tools:**
- **pytest**: For unit and integration testing
- **flake8/black/isort**: For code style checking
- **mypy**: For type checking
- **bandit**: For security scanning
- **safety**: For dependency vulnerability checking

**iOS CI Tools:**
- **SwiftLint**: For code style checking
- **XCTest**: For unit and UI testing
- **Fastlane**: For build and test automation
- **CocoaPods**: For dependency management

**Android CI Tools:**
- **ktlint**: For Kotlin code style checking
- **JUnit**: For unit testing
- **Espresso**: For UI testing
- **Gradle**: For build automation
- **OWASP Dependency Check**: For vulnerability scanning

### Documentation

Reference documentation for the PR process.

**Internal Documentation:**
- [Coding Standards](./coding-standards.md): Code style and best practices
- [Testing Guidelines](./testing.md): Testing requirements and approaches
- [Security Guidelines](../security/encryption.md): Security best practices
- [Architecture Overview](../architecture/overview.md): System architecture and design

**External Resources:**
- [GitHub Pull Request Documentation](https://docs.github.com/en/github/collaborating-with-pull-requests)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Google Engineering Practices: Code Review](https://google.github.io/eng-practices/review/)

## FAQ

Frequently asked questions about the PR process.

### General Questions

**Q: How big should my PR be?**
A: PRs should ideally be under 500 lines of code. Larger changes should be broken into smaller, logical PRs when possible.

**Q: How long should it take to get my PR reviewed?**
A: You should receive an initial review within 24 business hours. Complex PRs may take longer to fully review.

**Q: What should I do if my PR has merge conflicts?**
A: Rebase your branch on the latest version of the target branch to resolve conflicts, then push the updated branch.

**Q: Can I merge my own PR?**
A: No, PRs should be merged by someone other than the author after receiving the required approvals.

**Q: What if I need to make changes after approval?**
A: Make the changes and request a re-review. Minor changes may not require a full re-review.

### Process Questions

**Q: What if my PR fails CI checks?**
A: Investigate the failures, make necessary fixes, and push the changes. The CI checks will run again automatically.

**Q: How do I request a specific reviewer?**
A: You can manually add reviewers in the GitHub UI, but the CODEOWNERS file will automatically assign appropriate reviewers based on the files changed.

**Q: What if I disagree with a review comment?**
A: Explain your reasoning clearly and respectfully. If you can't reach agreement, involve a tech lead or architect for guidance.

**Q: How do I handle urgent fixes?**
A: Follow the hotfix process described in the "Special PR Types" section. Mark the PR with the `hotfix` label and request expedited review.

**Q: What should I do if my PR is blocked by another PR?**
A: You can either wait for the blocking PR to be merged or rebase your branch on the blocking PR's branch (with permission from the other PR's author).

### Technical Questions

**Q: How do I run the CI checks locally before pushing?**
A: You can run the same checks locally using the scripts in the repository:
- Backend: `cd src/backend && pytest && flake8`
- iOS: `cd src/ios/AmiraWellness && fastlane test`
- Android: `cd src/android && ./gradlew check`

**Q: How do I update the PR description after creating it?**
A: You can edit the PR description at any time using the "Edit" button at the top of the PR page.

**Q: How do I add labels to my PR?**
A: You can add labels using the "Labels" section in the right sidebar of the PR page.

**Q: How do I reference an issue in my PR?**
A: Include phrases like "Fixes #123" or "Relates to #456" in the PR description or commit messages.

**Q: How do I squash commits when merging?**
A: Use the "Squash and merge" option in the GitHub UI when merging the PR.

## Conclusion

Following this pull request process ensures that code changes to the Amira Wellness application are thoroughly reviewed, tested, and meet our quality standards. The process is designed to maintain code quality, ensure security and privacy, and facilitate collaboration among team members.

Remember that the ultimate goal of the PR process is to deliver high-quality features and fixes to our users while maintaining the security and privacy of their emotional data. By following these guidelines, we can achieve that goal efficiently and consistently.

## Appendix: PR Template

The following template is used for all pull requests and is available at `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
# Pull Request Description

## Changes Overview
*Provide a brief description of the changes in this PR*

## Related Issues
*Link to any related issues (e.g., Fixes #123)*

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring (no functional changes)
- [ ] DevOps/Infrastructure changes
- [ ] Other (please describe):

## Testing Performed
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] UI/UX tests performed
- [ ] Manual testing performed

*Describe the testing process and any test cases added*

## Security Considerations
- [ ] Changes include security-sensitive code (authentication, encryption, data handling)
- [ ] Security review needed
- [ ] Privacy impact assessment needed

*Describe any security implications of this change*

## Privacy Considerations
- [ ] Changes affect user data collection or processing
- [ ] Changes affect data encryption or security
- [ ] Changes affect data retention or deletion

*Describe any privacy implications of this change*

## Performance Impact
- [ ] Changes may affect application performance
- [ ] Performance testing performed

*Describe any performance implications and testing results*

## Screenshots/Videos
*If applicable, add screenshots or videos to help explain your changes*

## Additional Notes
*Any additional information that reviewers should know*

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published
- [ ] I have checked my code and corrected any misspellings