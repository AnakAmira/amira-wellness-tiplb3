import SwiftUI // Latest
import Combine // Latest
import LocalAuthentication // Latest

// Internal imports
import LoginViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Authentication/LoginViewModel.swift
import CustomTextField // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/CustomTextField.swift
import SecureField // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/SecureField.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift

/// SwiftUI view that implements the login screen for the Amira Wellness application,
/// providing email/password authentication, biometric login options, and navigation to
/// registration and password recovery screens.
struct LoginView: View {
    // MARK: - Properties

    /// Observed object for managing the login state and authentication logic.
    @ObservedObject var viewModel: LoginViewModel

    /// State variable to control the display of the biometric authentication alert.
    @State private var showingBiometricAlert: Bool = false

    /// Closure to navigate to the registration screen.
    var onNavigateToRegister: () -> Void

    /// Closure to navigate to the forgot password screen.
    var onNavigateToForgotPassword: () -> Void

    /// Closure to navigate to the main tab view after successful login.
    var onNavigateToMainTabView: () -> Void

    // MARK: - Initializer

    /// Initializes the LoginView with a view model and navigation closures.
    /// - Parameters:
    ///   - viewModel: The view model for managing login state.
    ///   - onNavigateToRegister: Closure to navigate to the registration screen.
    ///   - onNavigateToForgotPassword: Closure to navigate to the forgot password screen.
    ///   - onNavigateToMainTabView: Closure to navigate to the main tab view.
    init(viewModel: LoginViewModel,
         onNavigateToRegister: @escaping () -> Void,
         onNavigateToForgotPassword: @escaping () -> Void,
         onNavigateToMainTabView: @escaping () -> Void) {
        // Store the provided viewModel
        self.viewModel = viewModel
        // Initialize showingBiometricAlert as false
        self._showingBiometricAlert = State(initialValue: false)
        // Store the navigation closure for register screen
        self.onNavigateToRegister = onNavigateToRegister
        // Store the navigation closure for forgot password screen
        self.onNavigateToForgotPassword = onNavigateToForgotPassword
        // Store the navigation closure for main tab view
        self.onNavigateToMainTabView = onNavigateToMainTabView
    }

    // MARK: - Body

    /// Builds the login view with all UI components.
    /// - Returns: The composed login view.
    var body: some View {
        ZStack {
            // Create a ZStack to handle loading overlay
            ScrollView {
                // Inside the ZStack, create a ScrollView for the main content
                VStack(alignment: .leading, spacing: 20) {
                    // Add a VStack to organize the login form elements
                    Image("app_logo") // Replace "app_logo" with your actual asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.bottom, 20)

                    Text("Bienvenido de nuevo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorConstants.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Inicia sesión para continuar tu camino hacia el bienestar emocional.")
                        .font(.body)
                        .foregroundColor(ColorConstants.textSecondary)
                        .lineSpacing(4)

                    // Add CustomTextField for email input with validation
                    CustomTextField(
                        title: "Correo electrónico",
                        text: $viewModel.email,
                        placeholder: "tu_correo@ejemplo.com",
                        errorMessage: viewModel.errorMessage,
                        keyboardType: .emailAddress,
                        autocapitalizationType: .none,
                        autocorrectionType: .no,
                        validator: { email in
                            viewModel.validateEmail(email: email)
                        }
                    )
                    .accessibilityHint("Ingresa tu correo electrónico")

                    // Add SecureField for password input with validation
                    SecureField(
                        title: "Contraseña",
                        text: $viewModel.password,
                        placeholder: "Contraseña",
                        errorMessage: viewModel.errorMessage,
                        autocapitalizationType: .none,
                        autocorrectionType: .no,
                        validator: { password in
                            viewModel.validatePassword(password: password)
                        }
                    )
                    .accessibilityHint("Ingresa tu contraseña")

                    // Add a remember me checkbox with Toggle
                    Toggle(isOn: $viewModel.rememberCredentials) {
                        Text("Recordarme")
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.textSecondary)
                    }
                    .padding(.top, 5)
                    .accessibilityLabel("Recordarme")

                    // Add PrimaryButton for login action
                    PrimaryButton(
                        title: "Iniciar Sesión",
                        isEnabled: viewModel.isFormValid,
                        isLoading: viewModel.loginState == .authenticating,
                        action: {
                            viewModel.login()
                        }
                    )
                    .accessibilityHint("Presiona para iniciar sesión")

                    // Add forgot password button that calls onNavigateToForgotPassword closure
                    Button(action: {
                        onNavigateToForgotPassword()
                    }) {
                        Text("¿Olvidaste tu contraseña?")
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                    .accessibilityHint("Presiona para recuperar tu contraseña")

                    // Add register account button that calls onNavigateToRegister closure
                    Button(action: {
                        onNavigateToRegister()
                    }) {
                        Text("¿No tienes una cuenta? Regístrate")
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHint("Presiona para crear una cuenta")

                    // Add social login options (Google, Apple, Facebook)
                    HStack {
                        // Google Login Button
                        Button(action: {
                            // Handle Google Login
                        }) {
                            Image(systemName: "google.logo.fill")
                                .foregroundColor(ColorConstants.textPrimary)
                        }
                        .accessibilityLabel("Iniciar sesión con Google")

                        // Apple Login Button
                        Button(action: {
                            // Handle Apple Login
                        }) {
                            Image(systemName: "applelogo")
                                .foregroundColor(ColorConstants.textPrimary)
                        }
                        .accessibilityLabel("Iniciar sesión con Apple")

                        // Facebook Login Button
                        Button(action: {
                            // Handle Facebook Login
                        }) {
                            Image(systemName: "facebook.logo.fill")
                                .foregroundColor(ColorConstants.textPrimary)
                        }
                        .accessibilityLabel("Iniciar sesión con Facebook")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)

                    // Add biometric login button if available
                    if viewModel.showBiometricLogin {
                        Button(action: {
                            attemptBiometricLogin()
                        }) {
                            HStack {
                                Image(systemName: LAContext().biometryType == .faceID ? "faceid" : "touchid")
                                Text("Iniciar sesión con biometría")
                            }
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                        .accessibilityHint("Presiona para iniciar sesión con Face ID o Touch ID")
                    }
                }
                .padding(30)
            }

            // Add loading overlay when authentication is in progress
            if viewModel.loginState == .authenticating {
                LoadingView(message: "Autenticando...")
                    .transition(.opacity)
            }

            // Add error message display when authentication fails
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(ColorConstants.error)
                    .padding()
                    .background(ColorConstants.surface)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom))
            }
        }
        .onReceive(viewModel.$loginState) { _ in
            handleLoginResult()
        }
        .alert(isPresented: $showingBiometricAlert) {
            Alert(
                title: Text("Biometrico no disponible"),
                message: Text("La autenticación biométrica no está configurada en este dispositivo."),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(ColorConstants.background.ignoresSafeArea())
    }

    // MARK: - Helper Functions

    /// Handles the result of the login attempt.
    func handleLoginResult() {
        switch viewModel.loginState {
        case .success:
            // For .success case, call onNavigateToMainTabView closure
            onNavigateToMainTabView()
        case .error(let message):
            // For .error case, display the error message
            viewModel.errorMessage = message
        case .authenticating:
            // For .authenticating case, show loading indicator
            break
        case .idle:
            // For .idle case, do nothing
            break
        }
    }

    /// Attempts to authenticate the user using biometrics.
    func attemptBiometricLogin() {
        // Check if biometric login is available
        if viewModel.showBiometricLogin {
            // If available, call viewModel.loginWithBiometrics()
            viewModel.loginWithBiometrics()
        } else {
            // If not available, set showingBiometricAlert to true
            showingBiometricAlert = true
        }
    }
}