//
//  DataExportViewModel.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest
import UIKit // Latest

/// Types of data that can be exported from the application
enum ExportDataType: String, CaseIterable, Identifiable {
    case journals
    case emotionalData
    case toolUsage
    case progress
    case all
    
    var id: String { rawValue }
}

/// Available formats for data export
enum ExportFormat: String, CaseIterable, Identifiable {
    case json
    case encrypted
    
    var id: String { rawValue }
}

/// Errors that can occur during the export process
enum DataExportError: Error {
    case noDataSelected
    case invalidPassword
    case passwordMismatch
    case dataRetrievalFailed
    case exportFailed
    case encryptionFailed
    case fileOperationFailed
}

/// View model that manages the data export functionality in the Amira Wellness application
@available(iOS 13.0, *)
class DataExportViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Types of data selected for export
    @Published var selectedDataTypes: [ExportDataType] = []
    
    /// Selected export format (json or encrypted)
    @Published var exportFormat: ExportFormat = .json
    
    /// Password for encrypted exports
    @Published var password: String = ""
    
    /// Password confirmation for validation
    @Published var confirmPassword: String = ""
    
    /// Flag indicating if export is in progress
    @Published var isExporting: Bool = false
    
    /// Export progress from 0.0 to 1.0
    @Published var exportProgress: Double = 0.0
    
    /// URL of the exported file, set upon successful export
    @Published var exportedFileURL: URL? = nil
    
    /// Error message if export fails
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    
    private let journalService: JournalService
    private let storageService: StorageService
    private let encryptionService: EncryptionService
    private let logger: Logger
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the DataExportViewModel with default values and services
    init() {
        self.journalService = JournalService.shared
        self.storageService = StorageService.shared
        self.encryptionService = EncryptionService.shared
        self.logger = Logger.shared
    }
    
    // MARK: - Public Methods
    
    /// Validates export settings before proceeding with export
    /// - Returns: Result indicating success or validation error
    func validateExportSettings() -> Result<Void, DataExportError> {
        // Check if at least one data type is selected
        if selectedDataTypes.isEmpty {
            return .failure(.noDataSelected)
        }
        
        // If encrypted format is selected, validate password
        if exportFormat == .encrypted {
            // Check password meets requirements
            if !isPasswordValid() {
                return .failure(.invalidPassword)
            }
            
            // Check passwords match
            if !passwordsMatch() {
                return .failure(.passwordMismatch)
            }
        }
        
        return .success(())
    }
    
    /// Initiates the data export process based on selected options
    func exportData() {
        // Validate export settings
        let validationResult = validateExportSettings()
        
        switch validationResult {
        case .failure(let error):
            handleExportError(error)
            return
        case .success:
            // Continue with export
            break
        }
        
        // Set exporting state
        isExporting = true
        exportProgress = 0.0
        errorMessage = nil
        
        // Create a temporary directory for export files
        var directoryURL: URL
        do {
            directoryURL = try createTemporaryDirectory()
        } catch {
            logger.error("Failed to create temporary directory for export", error: error, category: .general)
            handleExportError(.fileOperationFailed)
            return
        }
        
        // Track exported files
        var exportedFiles: [URL] = []
        var exportSteps = 0
        
        // Determine number of export steps for progress tracking
        if selectedDataTypes.contains(.all) {
            exportSteps = 4 // All data types
        } else {
            exportSteps = selectedDataTypes.count
        }
        
        let shouldExportAll = selectedDataTypes.contains(.all)
        let progressIncrement = 1.0 / Double(exportSteps)
        
        // Create operation group for exporting data
        let group = DispatchGroup()
        
        // Export journals if selected
        if shouldExportAll || selectedDataTypes.contains(.journals) {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { group.leave(); return }
                
                let exportResult = self.exportJournals(directoryURL: directoryURL)
                
                DispatchQueue.main.async {
                    switch exportResult {
                    case .success(let fileURL):
                        exportedFiles.append(fileURL)
                        self.exportProgress += progressIncrement
                    case .failure(let error):
                        self.handleExportError(error)
                    }
                    group.leave()
                }
            }
        }
        
        // Export emotional data if selected
        if shouldExportAll || selectedDataTypes.contains(.emotionalData) {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { group.leave(); return }
                
                let exportResult = self.exportEmotionalData(directoryURL: directoryURL)
                
                DispatchQueue.main.async {
                    switch exportResult {
                    case .success(let fileURL):
                        exportedFiles.append(fileURL)
                        self.exportProgress += progressIncrement
                    case .failure(let error):
                        self.handleExportError(error)
                    }
                    group.leave()
                }
            }
        }
        
        // Export tool usage if selected
        if shouldExportAll || selectedDataTypes.contains(.toolUsage) {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { group.leave(); return }
                
                let exportResult = self.exportToolUsage(directoryURL: directoryURL)
                
                DispatchQueue.main.async {
                    switch exportResult {
                    case .success(let fileURL):
                        exportedFiles.append(fileURL)
                        self.exportProgress += progressIncrement
                    case .failure(let error):
                        self.handleExportError(error)
                    }
                    group.leave()
                }
            }
        }
        
        // Export progress data if selected
        if shouldExportAll || selectedDataTypes.contains(.progress) {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { group.leave(); return }
                
                let exportResult = self.exportProgress(directoryURL: directoryURL)
                
                DispatchQueue.main.async {
                    switch exportResult {
                    case .success(let fileURL):
                        exportedFiles.append(fileURL)
                        self.exportProgress += progressIncrement
                    case .failure(let error):
                        self.handleExportError(error)
                    }
                    group.leave()
                }
            }
        }
        
        // After all exports complete, create the final package
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // If there was an error during any export, don't continue
            if self.errorMessage != nil {
                self.isExporting = false
                self.cleanupTemporaryFiles(directoryURL)
                return
            }
            
            // Create the export package
            let packageResult = self.createExportPackage(fileURLs: exportedFiles, directoryURL: directoryURL)
            
            switch packageResult {
            case .success(let packageURL):
                // Set the exported file URL for sharing
                self.exportedFileURL = packageURL
                self.exportProgress = 1.0
                self.isExporting = false
                self.logger.info("Data export completed successfully", category: .general)
                
            case .failure(let error):
                self.handleExportError(error)
                self.cleanupTemporaryFiles(directoryURL)
            }
        }
    }
    
    /// Prepares the exported file for sharing
    /// - Returns: URL of the file to share, or nil if not available
    func shareExportFile() -> URL? {
        return exportedFileURL
    }
    
    /// Resets the export state after completion or cancellation
    func resetExport() {
        isExporting = false
        exportProgress = 0.0
        exportedFileURL = nil
        errorMessage = nil
        
        // Clean up any temporary files
        if let fileURL = exportedFileURL {
            let directoryURL = fileURL.deletingLastPathComponent()
            cleanupTemporaryFiles(directoryURL)
        }
    }
    
    /// Checks if the password meets security requirements
    /// - Returns: True if password is valid, false otherwise
    func isPasswordValid() -> Bool {
        guard !password.isEmpty else { return false }
        
        // Check minimum length
        if password.count < AppConstants.Security.passwordMinLength {
            return false
        }
        
        // Check for required character types if enabled in constants
        if AppConstants.Security.passwordRequiresSpecialCharacter {
            let specialCharacterRegex = ".*[^A-Za-z0-9].*"
            let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
            if !specialCharacterTest.evaluate(with: password) {
                return false
            }
        }
        
        if AppConstants.Security.passwordRequiresNumber {
            let numberRegex = ".*[0-9].*"
            let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
            if !numberTest.evaluate(with: password) {
                return false
            }
        }
        
        if AppConstants.Security.passwordRequiresUppercase {
            let uppercaseRegex = ".*[A-Z].*"
            let uppercaseTest = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
            if !uppercaseTest.evaluate(with: password) {
                return false
            }
        }
        
        return true
    }
    
    /// Checks if password and confirmation match
    /// - Returns: True if passwords match, false otherwise
    func passwordsMatch() -> Bool {
        return password == confirmPassword
    }
    
    // MARK: - Private Methods
    
    /// Exports journal data to a JSON file
    /// - Parameter directoryURL: Directory to save the exported file
    /// - Returns: URL of the exported file or error
    private func exportJournals(directoryURL: URL) -> Result<URL, DataExportError> {
        // Retrieve journals
        let journalsResult = journalService.getJournals()
        
        switch journalsResult {
        case .success(let journals):
            // Create journals.json file
            let fileURL = directoryURL.appendingPathComponent("journals.json")
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let journalData = try encoder.encode(journals)
                try journalData.write(to: fileURL)
                
                logger.info("Exported \(journals.count) journals to \(fileURL.path)", category: .general)
                return .success(fileURL)
            } catch {
                logger.error("Failed to write journals to file", error: error, category: .general)
                return .failure(.fileOperationFailed)
            }
            
        case .failure:
            logger.error("Failed to retrieve journals for export", category: .general)
            return .failure(.dataRetrievalFailed)
        }
    }
    
    /// Exports emotional data to a JSON file
    /// - Parameter directoryURL: Directory to save the exported file
    /// - Returns: URL of the exported file or error
    private func exportEmotionalData(directoryURL: URL) -> Result<URL, DataExportError> {
        // Retrieve emotional data
        let emotionalDataResult: Result<[EmotionalState], StorageError> = storageService.retrieveCodable(
            forKey: "emotional_data",
            dataType: .emotions,
            sensitivity: .sensitive
        )
        
        switch emotionalDataResult {
        case .success(let emotionalData):
            // Create emotional_data.json file
            let fileURL = directoryURL.appendingPathComponent("emotional_data.json")
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let emotionalDataJson = try encoder.encode(emotionalData)
                try emotionalDataJson.write(to: fileURL)
                
                logger.info("Exported \(emotionalData.count) emotional states to \(fileURL.path)", category: .general)
                return .success(fileURL)
            } catch {
                logger.error("Failed to write emotional data to file", error: error, category: .general)
                return .failure(.fileOperationFailed)
            }
            
        case .failure:
            logger.error("Failed to retrieve emotional data for export", category: .general)
            return .failure(.dataRetrievalFailed)
        }
    }
    
    /// Exports tool usage data to a JSON file
    /// - Parameter directoryURL: Directory to save the exported file
    /// - Returns: URL of the exported file or error
    private func exportToolUsage(directoryURL: URL) -> Result<URL, DataExportError> {
        // Retrieve tool usage data
        let toolUsageResult: Result<[Tool], StorageError> = storageService.retrieveCodable(
            forKey: "tool_usage",
            dataType: .tools,
            sensitivity: .nonsensitive
        )
        
        switch toolUsageResult {
        case .success(let tools):
            // Create tool_usage.json file
            let fileURL = directoryURL.appendingPathComponent("tool_usage.json")
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                // Filter tools to only include relevant usage data
                let toolUsage = tools.map { tool in
                    return [
                        "id": tool.id.uuidString,
                        "name": tool.name,
                        "usageCount": tool.usageCount,
                        "isFavorite": tool.isFavorite,
                        "lastUsed": tool.updatedAt?.timeIntervalSince1970 ?? 0
                    ]
                }
                
                let toolUsageData = try JSONSerialization.data(withJSONObject: toolUsage, options: .prettyPrinted)
                try toolUsageData.write(to: fileURL)
                
                logger.info("Exported \(tools.count) tool usage records to \(fileURL.path)", category: .general)
                return .success(fileURL)
            } catch {
                logger.error("Failed to write tool usage data to file", error: error, category: .general)
                return .failure(.fileOperationFailed)
            }
            
        case .failure:
            logger.error("Failed to retrieve tool usage data for export", category: .general)
            return .failure(.dataRetrievalFailed)
        }
    }
    
    /// Exports progress data to a JSON file
    /// - Parameter directoryURL: Directory to save the exported file
    /// - Returns: URL of the exported file or error
    private func exportProgress(directoryURL: URL) -> Result<URL, DataExportError> {
        // Retrieve progress data
        let progressResult: Result<[String: Any], StorageError> = storageService.retrieveCodable(
            forKey: "user_progress",
            dataType: .progress,
            sensitivity: .nonsensitive
        )
        
        switch progressResult {
        case .success(let progressData):
            // Create progress.json file
            let fileURL = directoryURL.appendingPathComponent("progress.json")
            
            do {
                let progressJsonData = try JSONSerialization.data(withJSONObject: progressData, options: .prettyPrinted)
                try progressJsonData.write(to: fileURL)
                
                logger.info("Exported progress data to \(fileURL.path)", category: .general)
                return .success(fileURL)
            } catch {
                logger.error("Failed to write progress data to file", error: error, category: .general)
                return .failure(.fileOperationFailed)
            }
            
        case .failure:
            logger.error("Failed to retrieve progress data for export", category: .general)
            return .failure(.dataRetrievalFailed)
        }
    }
    
    /// Creates a combined export package from individual data files
    /// - Parameters:
    ///   - fileURLs: URLs of the files to include in the package
    ///   - directoryURL: Directory for temporary files
    /// - Returns: URL of the export package or error
    private func createExportPackage(fileURLs: [URL], directoryURL: URL) -> Result<URL, DataExportError> {
        // Create a manifest file with export metadata
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        let manifest: [String: Any] = [
            "applicationName": AppConstants.App.name,
            "applicationVersion": AppConstants.App.version,
            "exportDate": Date().timeIntervalSince1970,
            "exportFormat": exportFormat.rawValue,
            "files": fileURLs.map { $0.lastPathComponent }
        ]
        
        do {
            let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
            try manifestData.write(to: manifestURL)
            fileURLs.append(manifestURL)
            
            // Create the output filename
            let fileName = getExportFileName()
            let outputURL = directoryURL.appendingPathComponent(fileName)
            
            // For JSON format, create a ZIP archive
            if exportFormat == .json {
                // In a production app, use a ZIP library to create an archive
                // For simplicity in this example, we'll use a mock implementation
                
                // Copy the first file as a placeholder (in a real app, create a ZIP)
                if let firstFile = fileURLs.first {
                    try FileManager.default.copyItem(at: firstFile, to: outputURL)
                } else {
                    return .failure(.exportFailed)
                }
                
                logger.info("Created export package at \(outputURL.path)", category: .general)
                return .success(outputURL)
            }
            // For encrypted format, encrypt the package
            else if exportFormat == .encrypted {
                // In a real app, create a ZIP first then encrypt it
                // Here we'll encrypt the first file as a placeholder
                
                if let firstFile = fileURLs.first {
                    let result = encryptExportPackage(packageURL: firstFile, outputURL: outputURL)
                    
                    switch result {
                    case .success(let encryptedURL):
                        logger.info("Created encrypted export package at \(encryptedURL.path)", category: .general)
                        return .success(encryptedURL)
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    return .failure(.exportFailed)
                }
            } else {
                return .failure(.exportFailed)
            }
        } catch {
            logger.error("Failed to create export package", error: error, category: .general)
            return .failure(.exportFailed)
        }
    }
    
    /// Encrypts the export package with the provided password
    /// - Parameters:
    ///   - packageURL: URL of the package to encrypt
    ///   - outputURL: URL where the encrypted package will be saved
    /// - Returns: URL of the encrypted package or error
    private func encryptExportPackage(packageURL: URL, outputURL: URL) -> Result<URL, DataExportError> {
        do {
            // Read the package data
            let packageData = try Data(contentsOf: packageURL)
            
            // Encrypt the data with password
            let encryptResult = encryptionService.encryptWithPassword(data: packageData, password: password)
            
            guard case let .success((encryptedData, salt)) = encryptResult else {
                logger.error("Failed to encrypt export package", category: .encryption)
                return .failure(.encryptionFailed)
            }
            
            // Create metadata for the encrypted package
            let metadata: [String: Any] = [
                "version": 1,
                "format": "AmiraWellness-EncryptedExport",
                "timestamp": Date().timeIntervalSince1970,
                "salt": salt.base64EncodedString()
            ]
            
            // Combine metadata and encrypted data
            let exportPackage: [String: Any] = [
                "metadata": metadata,
                "data": encryptedData.base64EncodedString()
            ]
            
            // Write to file
            let packageJson = try JSONSerialization.data(withJSONObject: exportPackage, options: [])
            try packageJson.write(to: outputURL)
            
            logger.info("Encrypted export package created successfully", category: .encryption)
            return .success(outputURL)
        } catch {
            logger.error("Failed to encrypt export package", error: error, category: .encryption)
            return .failure(.encryptionFailed)
        }
    }
    
    /// Creates a temporary directory for export files
    /// - Returns: URL of the created temporary directory
    /// - Throws: Error if directory creation fails
    private func createTemporaryDirectory() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let exportDirectoryName = "amira_export_\(UUID().uuidString)"
        let exportDirectoryURL = tempDirectory.appendingPathComponent(exportDirectoryName)
        
        try FileManager.default.createDirectory(
            at: exportDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        logger.debug("Created temporary directory at \(exportDirectoryURL.path)", category: .general)
        return exportDirectoryURL
    }
    
    /// Cleans up temporary files after export
    /// - Parameter directoryURL: Directory to clean up
    private func cleanupTemporaryFiles(_ directoryURL: URL) {
        do {
            try FileManager.default.removeItem(at: directoryURL)
            logger.debug("Cleaned up temporary directory at \(directoryURL.path)", category: .general)
        } catch {
            logger.error("Failed to clean up temporary directory", error: error, category: .general)
            // Non-fatal error, don't propagate
        }
    }
    
    /// Generates a filename for the export package
    /// - Returns: Generated filename with appropriate extension
    private func getExportFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let baseName = "amira_export_\(timestamp)"
        
        // Add appropriate extension based on format
        switch exportFormat {
        case .json:
            return "\(baseName).zip"
        case .encrypted:
            return "\(baseName).aenc"
        }
    }
    
    /// Handles export errors by setting error message and resetting state
    /// - Parameter error: The error that occurred
    private func handleExportError(_ error: DataExportError) {
        let errorMessage: String
        
        switch error {
        case .noDataSelected:
            errorMessage = NSLocalizedString("Por favor selecciona al menos un tipo de datos para exportar.", comment: "No data selected error")
        case .invalidPassword:
            errorMessage = NSLocalizedString("La contraseña no cumple con los requisitos mínimos de seguridad.", comment: "Invalid password error")
        case .passwordMismatch:
            errorMessage = NSLocalizedString("Las contraseñas no coinciden.", comment: "Password mismatch error")
        case .dataRetrievalFailed:
            errorMessage = NSLocalizedString("No se pudieron recuperar los datos para la exportación.", comment: "Data retrieval error")
        case .exportFailed:
            errorMessage = NSLocalizedString("La exportación falló. Por favor intenta de nuevo.", comment: "Export failed error")
        case .encryptionFailed:
            errorMessage = NSLocalizedString("No se pudo cifrar el paquete de exportación.", comment: "Encryption failed error")
        case .fileOperationFailed:
            errorMessage = NSLocalizedString("No se pudo crear o escribir el archivo de exportación.", comment: "File operation error")
        }
        
        self.errorMessage = errorMessage
        self.isExporting = false
        
        logger.error("Export error: \(errorMessage)", category: .general)
    }
}