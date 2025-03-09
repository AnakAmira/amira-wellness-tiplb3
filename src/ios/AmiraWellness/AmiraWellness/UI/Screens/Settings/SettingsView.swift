//
//  SettingsView.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import SwiftUI // iOS SDK - Latest

// Internal imports
import './SettingsViewModel' // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/SettingsViewModel.swift
import '../../../Managers/ThemeManager' // src/ios/AmiraWellness/AmiraWellness/Managers/ThemeManager.swift
import '../../Components/Buttons/PrimaryButton' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import '../../Components/Buttons/SecondaryButton' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/SecondaryButton.swift
import '../../Components/Modals/ConfirmationDialog' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Modals/ConfirmationDialog.swift
import '../../../Core/Constants/ColorConstants' // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import './NotificationSettingsView' // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/NotificationSettingsView.swift
import './PrivacySettingsView' // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/PrivacySettingsView.swift

/// A SwiftUI view that displays and manages application settings
struct SettingsView: View {
    // MARK: - Properties

    /// The view model that manages the settings state and functionality
    @StateObject var viewModel: SettingsViewModel

    /// An environment variable that provides access to the presentation mode of the view
    @Environment(\\.presentationMode) var presentationMode

    /// A state variable that controls the presentation of the NotificationSettingsView
    @State private var showNotificationSettings: Bool = false

    /// A state variable that controls the presentation of the PrivacySettingsView
    @State private var showPrivacySettings: Bool = false

    // MARK: - Initialization

    /// Initializes the settings view with an optional view model
    /// - Parameter viewModel: An optional SettingsViewModel instance
    init(viewModel: SettingsViewModel? = nil) {
        // Initialize the viewModel StateObject with the provided viewModel or create a new SettingsViewModel instance
        _viewModel = StateObject(wrappedValue: viewModel ?? SettingsViewModel())
        // Initialize showNotificationSettings to false
        self._showNotificationSettings = State(initialValue: false)
        // Initialize showPrivacySettings to false
        self._showPrivacySettings = State(initialValue: false)
    }

    // MARK: - Body

    /// Builds the settings view with all sections and components
    /// - Returns: The composed view hierarchy
    var body: some View {
        NavigationView {
            ScrollView { // Create a NavigationView containing a ScrollView
                VStack(spacing: 20) { // Add a VStack with spacing to contain all settings sections
                    accountSection() // Add the account section showing user email
                    preferencesSection() // Add the preferences section with theme and language options
                    notificationsSection() // Add the notifications section with toggle
                    securitySection() // Add the security section with biometric authentication option
                    helpAndSupportSection() // Add the help and support section with links
                    logoutButton() // Add the logout button at the bottom
                }
                .padding()
                .background(ColorConstants.background)
                .confirmationDialog( // Add confirmation dialog for logout
                    "¿Estás seguro de que quieres cerrar sesión?",
                    isPresented: $viewModel.showLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Cerrar sesión", role: .destructive) { // Logout
                        viewModel.logout()
                    }
                    Button("Cancelar", role: .cancel) { } // Cancel
                } message: {
                    Text("Se borrarán todos los datos locales.") // All local data will be cleared.
                }
                .alert(isPresented: $viewModel.showErrorAlert) { // Add alert for error messages
                    Alert(
                        title: Text("Error"), // Error
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("OK")) // OK
                    )
                }
                .overlay(viewModel.isLoggingOut ? ProgressView().centerInScreen() : nil) // Add loading overlay for logout in progress
                .navigationTitle("Configuración") // Set the navigation title to 'Configuración'
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ColorConstants.textSecondary)
                        }
                    }
                }
                .onAppear { // Add .onAppear modifier to call viewModel.onAppear()
                    viewModel.onAppear()
                }
                .background(
                    NavigationLink(destination: NotificationSettingsView(), isActive: $showNotificationSettings) {
                        EmptyView()
                    }
                    .hidden()
                )
                .background(
                    NavigationLink(destination: PrivacySettingsView(), isActive: $showPrivacySettings) {
                        EmptyView()
                    }
                    .hidden()
                )
            }
        }
    }

    /// Creates the account section showing user email
    /// - Returns: The account section view
    @ViewBuilder private func accountSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title 'Cuenta'
            sectionHeader(title: "Cuenta") // Add a section header with the title 'Cuenta'
            HStack { // Add a HStack showing the user's email address from viewModel.userEmail
                Text(viewModel.userEmail)
                    .font(.body)
                    .foregroundColor(ColorConstants.textPrimary)
                Spacer()
            }
        }
        .cardStyle() // Apply consistent styling with dividers and padding
    }

    /// Creates the preferences section with theme and language options
    /// - Returns: The preferences section view
    @ViewBuilder private func preferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title 'Preferencias'
            sectionHeader(title: "Preferencias") // Add a section header with the title 'Preferencias'

            Picker("Tema", selection: $viewModel.selectedThemeMode) { // Add a theme picker with options for system, light, and dark modes
                Text("Sistema").tag(ThemeMode.system)
                Text("Claro").tag(ThemeMode.light)
                Text("Oscuro").tag(ThemeMode.dark)
            }
            .onChange(of: viewModel.selectedThemeMode) { _ in
                viewModel.updateThemeMode()
            }

            Divider().background(ColorConstants.divider) // Add a Divider

            Picker("Idioma", selection: $viewModel.selectedLanguage) { // Add a language picker with options from viewModel.getAvailableLanguages()
                ForEach(viewModel.getAvailableLanguages(), id: \\.self) { language in
                    Text(viewModel.getLanguageDisplayName(languageCode: language)).tag(language)
                }
            }
            .onChange(of: viewModel.selectedLanguage) { _ in
                viewModel.updateLanguage()
            }
        }
        .cardStyle() // Apply consistent styling with dividers between options
    }

    /// Creates the notifications section with toggle and settings link
    /// - Returns: The notifications section view
    @ViewBuilder private func notificationsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title 'Notificaciones'
            sectionHeader(title: "Notificaciones") // Add a section header with the title 'Notificaciones'

            Toggle("Permitir notificaciones", isOn: $viewModel.isNotificationsEnabled) // Add a Toggle for enabling/disabling notifications
                .onChange(of: viewModel.isNotificationsEnabled) { _ in
                    viewModel.toggleNotifications()
                }

            Divider().background(ColorConstants.divider) // Add a Divider

            Button { // Add a button for notification settings that sets showNotificationSettings to true
                showNotificationSettings = true
                viewModel.navigateToNotificationSettings()
            } label: {
                HStack {
                    Text("Configuraci\u00f3n de notificaciones")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
        }
        .cardStyle() // Apply consistent styling with dividers between options
    }

    /// Creates the security section with privacy settings and biometric options
    /// - Returns: The security section view
    @ViewBuilder private func securitySection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title 'Privacidad y seguridad'
            sectionHeader(title: "Privacidad y seguridad") // Add a section header with the title 'Privacidad y seguridad'

            Button { // Add a button to privacy settings that sets showPrivacySettings to true
                showPrivacySettings = true
                viewModel.navigateToPrivacySettings()
            } label: {
                HStack {
                    Text("Configuraci\u00f3n de privacidad")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }

            Divider().background(ColorConstants.divider) // Add a Divider

            if viewModel.isBiometricAuthAvailable { // If biometric authentication is available, add a Toggle for biometric authentication
                Toggle("Usar \(viewModel.biometricType == .faceID ? "Face ID" : "Touch ID")", isOn: $viewModel.isBiometricAuthEnabled) // Bind the biometric toggle to viewModel.isBiometricAuthEnabled with viewModel.toggleBiometricAuth action
                    .onChange(of: viewModel.isBiometricAuthEnabled) { _ in
                        viewModel.toggleBiometricAuth()
                    }
            }
        }
        .cardStyle() // Apply consistent styling with dividers between options
    }

    /// Creates the help and support section with links
    /// - Returns: The help and support section view
    @ViewBuilder private func helpAndSupportSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title 'Ayuda y soporte'
            sectionHeader(title: "Ayuda y soporte") // Add a section header with the title 'Ayuda y soporte'

            Button { // Add a button to open help center that calls viewModel.openHelpCenter()
                viewModel.openHelpCenter()
            } label: {
                HStack {
                    Text("Centro de ayuda")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }

            Divider().background(ColorConstants.divider) // Add a Divider

            Button { // Add a button to contact support that calls viewModel.contactSupport()
                viewModel.contactSupport()
            } label: {
                HStack {
                    Text("Contactar soporte")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }

            Divider().background(ColorConstants.divider) // Add a Divider

            Button { // Add a button to open privacy policy that calls viewModel.openPrivacyPolicy()
                viewModel.openPrivacyPolicy()
            } label: {
                HStack {
                    Text("Pol\u00edtica de privacidad")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }

            Divider().background(ColorConstants.divider) // Add a Divider

            Button { // Add a button to open terms of service that calls viewModel.openTermsOfService()
                viewModel.openTermsOfService()
            } label: {
                HStack {
                    Text("T\u00e9rminos de servicio")
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
        }
        .cardStyle() // Apply consistent styling with dividers between options
    }

    /// Creates the logout button
    /// - Returns: The logout button view
    @ViewBuilder private func logoutButton() -> some View {
        PrimaryButton( // Create a PrimaryButton with title 'Cerrar sesión'
            title: "Cerrar sesión",
            backgroundColor: ColorConstants.error,
            textColor: ColorConstants.textOnPrimary,
            action: { // Set button action to call viewModel.confirmLogout()
                viewModel.confirmLogout()
            }
        )
    }

    /// Creates a consistent section header with the given title
    /// - Parameter title: The title for the section
    /// - Returns: The section header view
    @ViewBuilder private func sectionHeader(title: String) -> some View { // Create a Text view with the provided title
        Text(title) // Apply consistent styling (font, color, alignment)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(ColorConstants.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading) // Add appropriate padding and frame
    }
}