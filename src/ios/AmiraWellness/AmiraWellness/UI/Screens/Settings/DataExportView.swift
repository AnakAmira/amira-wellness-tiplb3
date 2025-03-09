import SwiftUI // iOS SDK
import UIKit // iOS SDK

import DataExportViewModel // ./DataExportViewModel
import PrimaryButton // ../../Components/Buttons/PrimaryButton
import SecondaryButton // ../../Components/Buttons/SecondaryButton
import ProgressBar // ../../Components/Loading/ProgressBar
import SuccessView // ../../Components/Feedback/SuccessView
import ErrorView // ../../Components/Feedback/ErrorView
import ColorConstants // ../../../Core/Constants/ColorConstants

/// A SwiftUI view that provides a user interface for exporting personal data from the application,
/// allowing users to select data types, choose export format, and optionally encrypt the exported data with a password.
struct DataExportView: View {
    // MARK: - Properties
    
    /// The view model that manages the data export logic and state.
    @StateObject var viewModel = DataExportViewModel()
    
    /// A state variable that controls the presentation of the share sheet.
    @State private var showingShareSheet = false
    
    /// A state variable that controls the presentation of the password information alert.
    @State private var showingPasswordInfo = false
    
    /// An environment variable that provides access to the presentation mode of the view.
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Initialization
    
    /// Initializes a new DataExportView with a view model
    init() {
        // Initialize the viewModel as a StateObject with DataExportViewModel()
    }
    
    // MARK: - Body
    
    /// Builds the main view hierarchy for the data export screen
    var body: some View {
        NavigationView {
            ZStack {
                // If viewModel.isExporting, show the exportProgressView
                if viewModel.isExporting {
                    exportProgressView()
                }
                // If viewModel.errorMessage is not nil, show the errorView
                else if viewModel.errorMessage != nil {
                    errorView()
                }
                // If viewModel.exportedFileURL is not nil, show the successView
                else if viewModel.exportedFileURL != nil {
                    successView()
                }
                // Otherwise, show the exportFormView
                else {
                    exportFormView()
                }
            }
            .navigationTitle("Exportar Datos") // Add a navigation title 'Exportar Datos'
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
            .sheet(isPresented: $showingShareSheet, content: {
                makeActivityViewController()
            })
            .alert(isPresented: $showingPasswordInfo) {
                Alert(
                    title: Text("Requisitos de Contraseña"),
                    message: Text("La contraseña debe tener al menos \(AppConstants.Security.passwordMinLength) caracteres y contener al menos un número, una mayúscula y un símbolo."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Creates the form for selecting export options
    private func exportFormView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Data Type Selection
                Section(header: Text("Tipos de Datos").font(.headline)) {
                    MultipleSelectionList(selection: $viewModel.selectedDataTypes)
                }
                
                // Export Format Selection
                Section(header: Text("Formato de Exportación").font(.headline)) {
                    Picker("Formato", selection: $viewModel.exportFormat) {
                        Text("JSON").tag(ExportFormat.json)
                        Text("Encriptado").tag(ExportFormat.encrypted)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Password Fields (Conditional)
                if viewModel.exportFormat == .encrypted {
                    Section(header: Text("Contraseña (para encriptado)").font(.headline)) {
                        SecureField("Contraseña", text: $viewModel.password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        HStack {
                            Spacer()
                            Button {
                                showingPasswordInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if !viewModel.isPasswordValid() {
                            Text("La contraseña debe tener al menos \(AppConstants.Security.passwordMinLength) caracteres y contener al menos un número, una mayúscula y un símbolo.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if !viewModel.passwordsMatch() {
                            Text("Las contraseñas no coinciden.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Action Buttons
                HStack {
                    Spacer()
                    SecondaryButton(title: "Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    PrimaryButton(title: "Exportar", isEnabled: viewModel.exportFormat == .json || (viewModel.exportFormat == .encrypted && viewModel.isPasswordValid() && viewModel.passwordsMatch())) {
                        viewModel.exportData()
                    }
                }
                .padding(.top)
            }
            .padding()
        }
    }
    
    /// Creates a view showing the export progress
    private func exportProgressView() -> some View {
        VStack(spacing: 20) {
            Text("Exportando datos...")
                .font(.title2)
                .fontWeight(.bold)
            
            ProgressBar(value: viewModel.exportProgress)
            
            Text("\(Int(viewModel.exportProgress * 100))%")
                .font(.headline)
                .foregroundColor(.secondary)
            
            SecondaryButton(title: "Cancelar") {
                viewModel.resetExport()
            }
        }
        .padding()
    }
    
    /// Creates a view showing the export success state
    private func successView() -> some View {
        SuccessView(
            title: "Exportación Completada",
            message: "Tus datos han sido exportados exitosamente.",
            buttonTitle: "Compartir",
            buttonAction: {
                showingShareSheet = true
            }
        )
    }
    
    /// Creates a view showing the export error state
    private func errorView() -> some View {
        ErrorView(
            title: "Error de Exportación",
            message: viewModel.errorMessage ?? "Ocurrió un error desconocido durante la exportación.",
            buttonTitle: "Reintentar",
            retryAction: {
                viewModel.resetExport()
                viewModel.exportData()
            }
        )
    }
    
    // MARK: - Actions
    
    /// Prepares and presents a share sheet for the exported file
    private func shareExportedFile() {
        if viewModel.shareExportFile() != nil {
            showingShareSheet = true
        }
    }
    
    // MARK: - UIActivityViewController
    
    /// Creates a UIActivityViewController for sharing the exported file
    private func makeActivityViewController() -> UIActivityViewController {
        let url = viewModel.shareExportFile()!
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    // MARK: - MultipleSelectionList
    
    /// A custom view for selecting multiple data types
    struct MultipleSelectionList: View {
        @Binding var selection: [ExportDataType]
        
        var body: some View {
            ForEach(ExportDataType.allCases) { dataType in
                Toggle(isOn: Binding(
                    get: {
                        selection.contains(dataType)
                    },
                    set: { isSelected in
                        if dataType == .all {
                            if isSelected {
                                selection = ExportDataType.allCases
                            } else {
                                selection = []
                            }
                        } else {
                            if isSelected {
                                selection.append(dataType)
                            } else {
                                selection.removeAll(where: { $0 == dataType })
                            }
                        }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text(dataTypeLabel(dataType: dataType))
                            .font(.headline)
                        Text(dataTypeDescription(dataType: dataType))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .disabled(dataType == .all && !selection.isEmpty && selection.count == ExportDataType.allCases.count)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Returns a user-friendly label for each data type
    private func dataTypeLabel(dataType: ExportDataType) -> String {
        switch dataType {
        case .journals:
            return "Diarios de voz"
        case .emotionalData:
            return "Datos emocionales"
        case .toolUsage:
            return "Uso de herramientas"
        case .progress:
            return "Datos de progreso"
        case .all:
            return "Todos los datos"
        }
    }
    
    /// Returns a description for each data type
    private func dataTypeDescription(dataType: ExportDataType) -> String {
        switch dataType {
        case .journals:
            return "Incluye todas tus grabaciones de voz y metadatos."
        case .emotionalData:
            return "Incluye todos tus registros de estados emocionales."
        case .toolUsage:
            return "Incluye información sobre las herramientas que has utilizado."
        case .progress:
            return "Incluye datos sobre tus rachas y logros."
        case .all:
            return "Incluye todos los tipos de datos disponibles."
        }
    }
}