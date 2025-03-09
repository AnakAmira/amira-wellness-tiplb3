#warning("XCTest package version: Latest")
import XCTest // Apple's testing framework
#warning("Combine package version: Latest")
import Combine // For testing asynchronous operations and publishers

// Internal imports
import LoginViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Authentication/LoginViewModel.swift
import MockAuthService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockAuthService.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import AuthError // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import TestData // src/ios/AmiraWellness/AmiraWellnessTests/Helpers/TestData.swift

/// Test suite for the LoginViewModel class
class LoginViewModelTests: XCTestCase {
    
    /// Instance of LoginViewModel to be tested
    var viewModel: LoginViewModel!
    
    /// Mock AuthService to isolate LoginViewModel
    var mockAuthService: MockAuthService!
    
    /// Set to hold Combine subscriptions
    var cancellables: Set<AnyCancellable>!
    
    /// Set up test environment before each test
    override func setUp() {
        super.setUp()
        
        // Reset mockAuthService to clean state
        mockAuthService = MockAuthService.shared
        mockAuthService.reset()
        
        // Initialize cancellables as empty Set<AnyCancellable>()
        cancellables = Set<AnyCancellable>()
        
        // Create a new LoginViewModel with mockAuthService
        viewModel = LoginViewModel(authService: mockAuthService)
        
        // Set default test values for mockAuthService properties
        mockAuthService.isBiometricLoginAvailableResult = true
        mockAuthService.isBiometricLoginEnabledResult = true
        mockAuthService.validatePasswordResult = true
    }
    
    /// Clean up test environment after each test
    override func tearDown() {
        // Cancel all subscriptions in cancellables
        cancellables.forEach { $0.cancel() }
        
        // Set viewModel to nil
        viewModel = nil
        
        super.tearDown()
    }
    
    /// Test that the view model initializes with correct default values
    func testInitialState() {
        // Assert that email is empty string
        XCTAssertEqual(viewModel.email, "")
        
        // Assert that password is empty string
        XCTAssertEqual(viewModel.password, "")
        
        // Assert that rememberCredentials is false
        XCTAssertFalse(viewModel.rememberCredentials)
        
        // Assert that loginState is .idle
        XCTAssertEqual(viewModel.loginState, .idle)
        
        // Assert that errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test email validation logic
    func testEmailValidation() {
        // Test that empty email is invalid
        XCTAssertFalse(viewModel.validateEmail(email: ""))
        
        // Test that malformed email is invalid
        XCTAssertFalse(viewModel.validateEmail(email: "invalid-email"))
        
        // Test that valid email format is valid
        XCTAssertTrue(viewModel.validateEmail(email: "test@example.com"))
        
        // Test edge cases for email validation
        XCTAssertTrue(viewModel.validateEmail(email: "test.user@sub.example.co.uk"))
        XCTAssertTrue(viewModel.validateEmail(email: "test_user123@example.museum"))
    }
    
    /// Test password validation logic
    func testPasswordValidation() {
        // Configure mockAuthService.validatePasswordResult
        mockAuthService.validatePasswordResult = true
        
        // Test that empty password is invalid
        XCTAssertFalse(viewModel.validatePassword(password: ""))
        
        // Test that password validation delegates to authService
        _ = viewModel.validatePassword(password: "testPassword")
        
        // Verify validatePasswordCalled flag is set
        XCTAssertTrue(mockAuthService.validatePasswordCalled)
    }
    
    /// Test overall form validation logic
    func testFormValidation() {
        // Configure mockAuthService.validatePasswordResult
        mockAuthService.validatePasswordResult = true
        
        // Test form is invalid with empty email and password
        viewModel.email = ""
        viewModel.password = ""
        XCTAssertFalse(viewModel.isFormValid)
        
        // Test form is invalid with valid email but invalid password
        viewModel.email = "test@example.com"
        viewModel.password = ""
        mockAuthService.validatePasswordResult = false
        XCTAssertFalse(viewModel.isFormValid)
        
        // Test form is invalid with invalid email but valid password
        viewModel.email = "invalid-email"
        viewModel.password = "testPassword"
        mockAuthService.validatePasswordResult = true
        XCTAssertFalse(viewModel.isFormValid)
        
        // Test form is valid with valid email and password
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        mockAuthService.validatePasswordResult = true
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    /// Test successful login flow
    func testLoginSuccess() {
        // Create mock user for successful login
        let mockUser = TestData.mockUser()
        
        // Configure mockAuthService.loginResult with success
        mockAuthService.loginResult = .success(mockUser)
        
        // Set valid email and password in viewModel
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        
        // Call viewModel.login()
        viewModel.login()
        
        // Verify loginCalled flag is set
        XCTAssertTrue(mockAuthService.loginCalled)
        
        // Verify lastLoginEmail and lastLoginPassword match input
        XCTAssertEqual(mockAuthService.lastLoginEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastLoginPassword, "testPassword")
        
        // Assert that loginState is .success with correct user
        if case .success(let user) = viewModel.loginState {
            XCTAssertEqual(user, mockUser)
        } else {
            XCTFail("Login should be successful")
        }
        
        // Assert that errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test login failure handling
    func testLoginFailure() {
        // Configure mockAuthService.loginResult with error
        mockAuthService.loginResult = .failure(.invalidCredentials)
        
        // Set valid email and password in viewModel
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        
        // Call viewModel.login()
        viewModel.login()
        
        // Verify loginCalled flag is set
        XCTAssertTrue(mockAuthService.loginCalled)
        
        // Assert that loginState is .error
        if case .error(let message) = viewModel.loginState {
            // Assert that errorMessage contains appropriate error message
            XCTAssertEqual(message, "Invalid email or password")
        } else {
            XCTFail("Login should fail")
        }
    }
    
    /// Test login attempt with empty credentials
    func testLoginWithEmptyCredentials() {
        // Leave email and password empty
        
        // Call viewModel.login()
        viewModel.login()
        
        // Verify loginCalled flag is not set
        XCTAssertFalse(mockAuthService.loginCalled)
        
        // Assert that loginState remains .idle
        XCTAssertEqual(viewModel.loginState, .idle)
        
        // Assert that errorMessage is set appropriately
        XCTAssertEqual(viewModel.errorMessage, "Please enter email and password")
    }
    
    /// Test async login method
    @available(iOS 15.0, *)
    func testLoginAsync() async {
        // Create mock user for successful login
        let mockUser = TestData.mockUser()
        
        // Configure mockAuthService.loginAsyncResult with success
        mockAuthService.loginAsyncResult = .success(mockUser)
        
        // Set valid email and password in viewModel
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        
        // Await viewModel.loginAsync()
        await viewModel.loginAsync()
        
        // Verify loginAsyncCalled flag is set
        XCTAssertTrue(mockAuthService.loginAsyncCalled)
        
        // Verify lastLoginEmail and lastLoginPassword match input
        XCTAssertEqual(mockAuthService.lastLoginEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastLoginPassword, "testPassword")
        
        // Assert that loginState is .success with correct user
        if case .success(let user) = viewModel.loginState {
            XCTAssertEqual(user, mockUser)
        } else {
            XCTFail("Login should be successful")
        }
        
        // Assert that errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test async login failure handling
    @available(iOS 15.0, *)
    func testLoginAsyncFailure() async {
        // Configure mockAuthService.loginAsyncResult with error
        mockAuthService.loginAsyncResult = .failure(.invalidCredentials)
        
        // Set valid email and password in viewModel
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        
        // Await viewModel.loginAsync()
        await viewModel.loginAsync()
        
        // Verify loginAsyncCalled flag is set
        XCTAssertTrue(mockAuthService.loginAsyncCalled)
        
        // Assert that loginState is .error
        if case .error(let message) = viewModel.loginState {
            // Assert that errorMessage contains appropriate error message
            XCTAssertEqual(message, "Invalid email or password")
        } else {
            XCTFail("Login should fail")
        }
    }
    
    /// Test biometric login availability check
    func testBiometricLoginAvailability() {
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as true
        mockAuthService.isBiometricLoginEnabledResult = true
        
        // Assert that viewModel.showBiometricLogin is true
        XCTAssertTrue(viewModel.showBiometricLogin)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as false
        mockAuthService.isBiometricLoginAvailableResult = false
        
        // Assert that viewModel.showBiometricLogin is false
        XCTAssertFalse(viewModel.showBiometricLogin)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as false
        mockAuthService.isBiometricLoginEnabledResult = false
        
        // Assert that viewModel.showBiometricLogin is false
        XCTAssertFalse(viewModel.showBiometricLogin)
    }
    
    /// Test successful biometric login
    func testBiometricLoginSuccess() {
        // Create mock user for successful login
        let mockUser = TestData.mockUser()
        
        // Configure mockAuthService.loginWithBiometricsResult with success
        mockAuthService.loginWithBiometricsResult = .success(mockUser)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as true
        mockAuthService.isBiometricLoginEnabledResult = true
        
        // Call viewModel.loginWithBiometrics()
        viewModel.loginWithBiometrics()
        
        // Verify loginWithBiometricsCalled flag is set
        XCTAssertTrue(mockAuthService.loginWithBiometricsCalled)
        
        // Assert that loginState is .success with correct user
        if case .success(let user) = viewModel.loginState {
            XCTAssertEqual(user, mockUser)
        } else {
            XCTFail("Login should be successful")
        }
        
        // Assert that errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test biometric login failure handling
    func testBiometricLoginFailure() {
        // Configure mockAuthService.loginWithBiometricsResult with error
        mockAuthService.loginWithBiometricsResult = .failure(.biometricAuthFailed)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as true
        mockAuthService.isBiometricLoginEnabledResult = true
        
        // Call viewModel.loginWithBiometrics()
        viewModel.loginWithBiometrics()
        
        // Verify loginWithBiometricsCalled flag is set
        XCTAssertTrue(mockAuthService.loginWithBiometricsCalled)
        
        // Assert that loginState is .error
        if case .error(let message) = viewModel.loginState {
            // Assert that errorMessage contains appropriate error message
            XCTAssertEqual(message, "Biometric authentication failed")
        } else {
            XCTFail("Login should fail")
        }
    }
    
    /// Test biometric login when unavailable
    func testBiometricLoginUnavailable() {
        // Configure mockAuthService.isBiometricLoginAvailableResult as false
        mockAuthService.isBiometricLoginAvailableResult = false
        
        // Call viewModel.loginWithBiometrics()
        viewModel.loginWithBiometrics()
        
        // Verify loginWithBiometricsCalled flag is not set
        XCTAssertFalse(mockAuthService.loginWithBiometricsCalled)
        
        // Assert that loginState remains .idle
        XCTAssertEqual(viewModel.loginState, .idle)
        
        // Assert that errorMessage is set appropriately
        XCTAssertEqual(viewModel.errorMessage, "Biometric login is not available")
    }
    
    /// Test successful async biometric login
    @available(iOS 15.0, *)
    func testBiometricLoginAsyncSuccess() async {
        // Create mock user for successful login
        let mockUser = TestData.mockUser()
        
        // Configure mockAuthService.loginWithBiometricsAsyncResult with success
        mockAuthService.loginWithBiometricsAsyncResult = .success(mockUser)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as true
        mockAuthService.isBiometricLoginEnabledResult = true
        
        // Await viewModel.loginWithBiometricsAsync()
        await viewModel.loginWithBiometricsAsync()
        
        // Verify loginWithBiometricsAsyncCalled flag is set
        XCTAssertTrue(mockAuthService.loginWithBiometricsAsyncCalled)
        
        // Assert that loginState is .success with correct user
        if case .success(let user) = viewModel.loginState {
            XCTAssertEqual(user, mockUser)
        } else {
            XCTFail("Login should be successful")
        }
        
        // Assert that errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test async biometric login failure handling
    @available(iOS 15.0, *)
    func testBiometricLoginAsyncFailure() async {
        // Configure mockAuthService.loginWithBiometricsAsyncResult with error
        mockAuthService.loginWithBiometricsAsyncResult = .failure(.biometricAuthFailed)
        
        // Configure mockAuthService.isBiometricLoginAvailableResult as true
        mockAuthService.isBiometricLoginAvailableResult = true
        
        // Configure mockAuthService.isBiometricLoginEnabledResult as true
        mockAuthService.isBiometricLoginEnabledResult = true
        
        // Await viewModel.loginWithBiometricsAsync()
        await viewModel.loginWithBiometricsAsync()
        
        // Verify loginWithBiometricsAsyncCalled flag is set
        XCTAssertTrue(mockAuthService.loginWithBiometricsAsyncCalled)
        
        // Assert that loginState is .error
        if case .error(let message) = viewModel.loginState {
            // Assert that errorMessage contains appropriate error message
            XCTAssertEqual(message, "Biometric authentication failed")
        } else {
            XCTFail("Login should fail")
        }
    }
    
    /// Test resetting the login state
    func testResetState() {
        // Set loginState to .error with message
        viewModel.loginState = .error("Test Error")
        
        // Set errorMessage to a test error message
        viewModel.errorMessage = "Test Error Message"
        
        // Call viewModel.resetState()
        viewModel.resetState()
        
        // Assert that loginState is reset to .idle
        XCTAssertEqual(viewModel.loginState, .idle)
        
        // Assert that errorMessage is reset to nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test that login state changes are properly published
    func testLoginStatePublishing() {
        // Create expectation for state change
        let expectation = XCTestExpectation(description: "Login state should change to .success")
        
        // Subscribe to loginState changes
        viewModel.$loginState
            .dropFirst() // Drop initial .idle state
            .sink { state in
                // Assert that received state is .success with correct user
                if case .success(let user) = state {
                    XCTAssertEqual(user.email, "test@example.com")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Create mock user for successful login
        let mockUser = TestData.mockUser(email: "test@example.com")
        
        // Configure mockAuthService.loginResult with success
        mockAuthService.loginResult = .success(mockUser)
        
        // Set valid email and password in viewModel
        viewModel.email = "test@example.com"
        viewModel.password = "testPassword"
        
        // Call viewModel.login()
        viewModel.login()
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
}