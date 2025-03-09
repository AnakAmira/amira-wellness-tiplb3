import SwiftUI // iOS SDK - Latest
// Internal imports
import '../../../Core/Constants/ColorConstants' // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import '../../Components/Buttons/PrimaryButton' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import '../../Components/Buttons/SecondaryButton' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/SecondaryButton.swift
import '../../Components/Modals/ConfirmationDialog' // src/ios/AmiraWellness/AmiraWellness/UI/Components/Modals/ConfirmationDialog.swift
import './DataExportView' // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/DataExportView.swift
import './PrivacySettingsViewModel' // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/PrivacySettingsViewModel.swift

/// A SwiftUI view that displays and manages privacy and security settings for the Amira Wellness application
struct PrivacySettingsView: View {
    // MARK: - Properties

    /// The view model that manages the privacy settings state and functionality
    @StateObject var viewModel: PrivacySettingsViewModel

    /// An environment variable that provides access to the presentation mode of the view
    @Environment(\.presentationMode) var presentationMode

    /// A state variable that controls the presentation of the DataExportView
    @State private var showDataExport = false

    // MARK: - Initialization

    /// Initializes the privacy settings view with an optional view model
    /// - Parameter viewModel: An optional PrivacySettingsViewModel instance
    init(viewModel: PrivacySettingsViewModel? = nil) {
        // Initialize the viewModel StateObject with the provided viewModel or create a new PrivacySettingsViewModel instance
        _viewModel = StateObject(wrappedValue: viewModel ?? PrivacySettingsViewModel())
        // Initialize showDataExport to false
        self._showDataExport = State(initialValue: false)
    }

    // MARK: - Body

    /// Builds the privacy settings view with all sections and components
    /// - Returns: The composed view hierarchy
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Add the encryption section with toggle for enabling/disabling encryption
                    encryptionSection()

                    // Add the biometric authentication section if available on the device
                    if viewModel.isBiometricAuthAvailable {
                        biometricSection()
                    }

                    // Add the data management section with data export and deletion options
                    dataManagementSection()

                    // Add the account deletion section with warning and confirmation
                    accountDeletionSection()
                }
                .padding()
                .background(ColorConstants.background)
                // Set the navigation title to 'Privacidad y Seguridad'
                .navigationTitle("Privacidad y Seguridad")
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
                // Add .onAppear modifier to call viewModel.onAppear()
                .onAppear {
                    viewModel.onAppear()
                }
                // Add NavigationLink to DataExportView controlled by showDataExport
                .background(
                    NavigationLink(destination: DataExportView(), isActive: $showDataExport) {
                        EmptyView()
                    }
                    .hidden()
                )
            }
            // Add confirmation dialogs for data deletion and account deletion
            .confirmationDialog(
                "¿Estás seguro de que quieres eliminar estos datos? Esta acción no se puede deshacer.",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteData()
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Esta acción eliminará permanentemente los datos seleccionados.")
            }
            .confirmationDialog(
                "¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.",
                isPresented: $viewModel.showAccountDeletionConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteAccount()
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Esta acción eliminará permanentemente tu cuenta y todos los datos asociados.")
            }
            // Add alerts for success and error messages
            .alert(viewModel.successMessage, isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert(viewModel.errorMessage, isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            }
            // Add loading overlay for operations in progress
            .overlay(viewModel.isProcessing ? Color.black.opacity(0.4) : Color.clear)
            .overlay(viewModel.isProcessing ? ProgressView().tint(.white) : nil)
        }
    }

    /// Creates the encryption section with toggle for enabling/disabling encryption
    /// - Returns: The encryption section view
    @ViewBuilder private func encryptionSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            sectionHeader(title: "Cifrado")

            // Description text
            Text("Cifrado de extremo a extremo para proteger tus datos personales.")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)

            // Toggle for enabling/disabling encryption
            Toggle(isOn: $viewModel.isEncryptionEnabled) {
                Text("Habilitar cifrado de extremo a extremo")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
            }
            .onChange(of: viewModel.isEncryptionEnabled) { _ in
                viewModel.toggleEncryption()
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Creates the biometric authentication section if available on the device
    /// - Returns: The biometric authentication section view
    @ViewBuilder private func biometricSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            sectionHeader(title: "Autenticación Biométrica")

            // Description text
            Text("Protege tus claves de cifrado con \(viewModel.getBiometricTypeText()).")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)

            // Toggle for enabling/disabling biometric authentication
            Toggle(isOn: $viewModel.isBiometricAuthEnabled) {
                Text("Habilitar \(viewModel.getBiometricTypeText())")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
            }
            .onChange(of: viewModel.isBiometricAuthEnabled) { _ in
                viewModel.toggleBiometricAuth()
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Creates the data management section with data export and deletion options
    /// - Returns: The data management section view
    @ViewBuilder private func dataManagementSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            sectionHeader(title: "Gestión de Datos")

            // Button to navigate to data export
            Button {
                showDataExport = true
                viewModel.navigateToDataExport()
            } label: {
                HStack {
                    Text("Exportar mis datos")
                        .font(.headline)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
            .padding(.vertical, 5)

            Divider()
                .background(ColorConstants.divider)

            // Data deletion picker
            Text("Eliminar datos:")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)

            Picker("Tipo de datos", selection: $viewModel.selectedDataDeletionType) {
                ForEach(DataDeletionType.allCases, id: \.self) { type in
                    Text(viewModel.getDataDeletionTypeText(type: type))
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .padding(.vertical, 5)

            // Button to confirm data deletion
            Button {
                viewModel.confirmDataDeletion()
            } label: {
                HStack {
                    Text("Eliminar datos seleccionados")
                        .font(.headline)
                        .foregroundColor(ColorConstants.textPrimary)
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Creates the account deletion section with warning and confirmation
    /// - Returns: The account deletion section view
    @ViewBuilder private func accountDeletionSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            sectionHeader(title: "Eliminación de Cuenta")

            // Warning text
            Text("Eliminar tu cuenta es una acción permanente y no se puede deshacer. Todos tus datos serán eliminados.")
                .font(.subheadline)
                .foregroundColor(ColorConstants.error)

            // Button to confirm account deletion
            PrimaryButton(
                title: "Eliminar mi cuenta",
                backgroundColor: ColorConstants.error,
                textColor: ColorConstants.textOnPrimary
            ) {
                viewModel.confirmAccountDeletion()
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Creates a consistent section header with the given title
    /// - Parameter title: The title for the section
    /// - Returns: The section header view
    @ViewBuilder private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(ColorConstants.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
    }
}