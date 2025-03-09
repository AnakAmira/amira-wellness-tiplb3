import SwiftUI // Latest - Framework for building the user interface
import Combine // Latest - For handling state updates and publishers

// Internal imports
import RegisterViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Authentication/RegisterViewModel.swift - Provides view model functionality for the registration screen
import CustomTextField // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/CustomTextField.swift - Reusable text field component for email and name input
import SecureField // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/SecureField.swift - Reusable secure text field component for password input
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift - Reusable primary button component for registration action
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift - Access to app's color constants for consistent styling
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift - Loading indicator for registration in progress

/// SwiftUI view that implements the registration screen for the Amira Wellness application
struct RegisterView: View {
    // MARK: - Properties

    /// Observed object for managing the registration state and logic
    @ObservedObject var viewModel: RegisterViewModel

    /// State variable to control the presentation of the terms and conditions sheet
    @State private var showingTermsSheet = false

    /// Closure to navigate to the login screen
    var onNavigateToLogin: () -> Void

    /// Closure to handle successful registration
    var onRegistrationSuccess: () -> Void

    // MARK: - Initializer

    /// Initializes the RegisterView with a view model and navigation closures
    /// - Parameters:
    ///   - viewModel: The view model for the registration screen
    ///   - onNavigateToLogin: Closure to navigate to the login screen
    ///   - onRegistrationSuccess: Closure to handle successful registration
    init(viewModel: RegisterViewModel,
         onNavigateToLogin: @escaping () -> Void,
         onRegistrationSuccess: @escaping () -> Void) {
        // Store the provided viewModel
        self.viewModel = viewModel
        // Initialize showingTermsSheet as false
        self._showingTermsSheet = State(initialValue: false)
        // Store the navigation closure for login screen
        self.onNavigateToLogin = onNavigateToLogin
        // Store the navigation closure for successful registration
        self.onRegistrationSuccess = onRegistrationSuccess
    }

    // MARK: - Body

    /// Builds the registration view with all UI components
    /// - Returns: The composed registration view
    var body: some View {
        ZStack { // Create a ZStack to handle loading overlay
            ScrollView { // Inside the ZStack, create a ScrollView for the main content
                VStack(alignment: .leading, spacing: 20) { // Add a VStack to organize the registration form elements
                    Text("Crear una cuenta") // Add a welcome title and subtitle
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorConstants.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Únete a Amira Wellness y comienza tu camino hacia el bienestar emocional.")
                        .font(.subheadline)
                        .foregroundColor(ColorConstants.textSecondary)

                    CustomTextField( // Add CustomTextField for email input with validation
                        title: "Correo electrónico",
                        text: $viewModel.email,
                        placeholder: "tu_correo@ejemplo.com",
                        errorMessage: viewModel.errorMessage,
                        keyboardType: .emailAddress,
                        autocapitalizationType: .none,
                        autocorrectionType: .no
                    )
                    .accessibilityLabel("Correo electrónico")
                    .accessibilityHint("Ingresa tu dirección de correo electrónico")

                    CustomTextField( // Add CustomTextField for name input with validation
                        title: "Nombre completo",
                        text: $viewModel.name,
                        placeholder: "Tu nombre",
                        errorMessage: viewModel.errorMessage,
                        autocapitalizationType: .words
                    )
                    .accessibilityLabel("Nombre completo")
                    .accessibilityHint("Ingresa tu nombre completo")

                    SecureField( // Add SecureField for password input with validation
                        title: "Contraseña",
                        text: $viewModel.password,
                        placeholder: "Contraseña",
                        errorMessage: viewModel.errorMessage
                    )
                    .accessibilityLabel("Contraseña")
                    .accessibilityHint("Ingresa tu contraseña")

                    SecureField( // Add SecureField for password confirmation with validation
                        title: "Confirmar contraseña",
                        text: $viewModel.confirmPassword,
                        placeholder: "Confirmar contraseña",
                        errorMessage: viewModel.errorMessage
                    )
                    .accessibilityLabel("Confirmar contraseña")
                    .accessibilityHint("Confirma tu contraseña")

                    Text(viewModel.getPasswordRequirements()) // Add password requirements text with formatting
                        .font(.footnote)
                        .foregroundColor(ColorConstants.textSecondary)
                        .accessibilityLabel("Requisitos de contraseña")

                    Picker("Idioma preferido", selection: $viewModel.languagePreference) { // Add language preference picker with Spanish and English options
                        ForEach(RegisterViewModel.LanguagePreference.allCases) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    .accessibilityLabel("Idioma preferido")
                    .accessibilityHint("Selecciona tu idioma preferido")

                    HStack { // Add terms and conditions checkbox with Toggle
                        Toggle(isOn: $viewModel.agreeToTerms) {
                            Text("Acepto los términos y condiciones")
                                .font(.subheadline)
                                .foregroundColor(ColorConstants.textSecondary)
                        }
                        .accessibilityLabel("Acepto los términos y condiciones")
                        .accessibilityHint("Debes aceptar los términos y condiciones para crear una cuenta")
                    }

                    Button { // Add terms and conditions text with link to show terms sheet
                        showingTermsSheet = true
                    } label: {
                        Text("Ver términos y condiciones")
                            .font(.footnote)
                            .foregroundColor(ColorConstants.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Ver términos y condiciones")
                    .accessibilityHint("Muestra los términos y condiciones en una hoja")

                    PrimaryButton( // Add PrimaryButton for registration action
                        title: "Crear cuenta",
                        isEnabled: viewModel.isFormValid && viewModel.registerState != .registering,
                        isLoading: viewModel.registerState == .registering,
                        action: {
                            if #available(iOS 15.0, *) {
                                Task {
                                    await viewModel.registerAsync()
                                }
                            } else {
                                viewModel.register()
                            }
                        }
                    )
                    .accessibilityLabel("Crear cuenta")
                    .accessibilityHint("Crea una nueva cuenta con la información proporcionada")

                    Button { // Add login account button that calls onNavigateToLogin closure
                        onNavigateToLogin()
                    } label: {
                        Text("¿Ya tienes una cuenta? Iniciar sesión")
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("¿Ya tienes una cuenta? Iniciar sesión")
                    .accessibilityHint("Navega a la pantalla de inicio de sesión")
                }
                .padding()
            }

            if viewModel.registerState == .registering { // Add loading overlay when registration is in progress
                LoadingView(message: "Creando cuenta...", isLoading: true)
            }

            if let errorMessage = viewModel.errorMessage { // Add error message display when registration fails
                Text(errorMessage)
                    .foregroundColor(ColorConstants.error)
                    .padding()
                    .accessibilityLabel("Error de registro: \(errorMessage)")
            }
        }
        .onChange(of: viewModel.registerState) { _ in // Add success handling to call onRegistrationSuccess when registration succeeds
            handleRegistrationResult()
        }
        .sheet(isPresented: $showingTermsSheet) { // Add sheet presentation for terms and conditions
            termsAndConditionsView()
        }
        .accessibilityElement(children: .combine) // Configure accessibility labels and hints for all elements
        .accessibilityLabel("Pantalla de registro")
        .accessibilityHint("Ingresa tus datos para crear una nueva cuenta")
    }

    // MARK: - Helper Functions

    /// Handles the result of the registration attempt
    func handleRegistrationResult() {
        switch viewModel.registerState {
        case .success: // For .success case, call onRegistrationSuccess closure
            onRegistrationSuccess()
            viewModel.resetState()
        case .error(let message): // For .error case, display the error message
            print("Registration failed with error: \(message)")
        case .registering: // For .registering case, show loading indicator
            print("Registering...")
        case .idle: // For .idle case, do nothing
            print("Registration idle")
        }
    }

    /// Creates a view for displaying the terms and conditions
    /// - Returns: The terms and conditions view
    private func termsAndConditionsView() -> some View {
        VStack { // Create a VStack with the terms and conditions content
            Text("Términos y Condiciones") // Add a title for the terms and conditions
                .font(.title)
                .padding()

            ScrollView { // Add a ScrollView for the terms text content
                Text("""
                    Estos son los términos y condiciones de uso de Amira Wellness.
                    Por favor, léelos cuidadosamente antes de usar la aplicación.
                    ... (Texto completo de los términos y condiciones) ...
                    """) // Add the full terms and conditions text
                    .padding()
            }

            Button("Aceptar") { // Add a dismiss button at the bottom
                showingTermsSheet = false
            }
            .padding()
        }
        .padding() // Apply appropriate styling and padding
    }
    
    /// Creates a view for displaying password requirements
    /// - Returns: The password requirements view
    private func passwordRequirementsView() -> some View {
        Text(viewModel.getPasswordRequirements()) // Create a Text view with the password requirements
            .font(.footnote) // Get the requirements text from viewModel.getPasswordRequirements()
            .foregroundColor(ColorConstants.textSecondary) // Apply appropriate styling (font size, color)
            .accessibilityLabel("Requisitos de contraseña") // Add proper accessibility label
    }
}