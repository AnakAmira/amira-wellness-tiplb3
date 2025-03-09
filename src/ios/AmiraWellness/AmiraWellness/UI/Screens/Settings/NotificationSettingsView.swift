import SwiftUI // iOS SDK
import Combine // iOS SDK

// Internal imports
import NotificationSettingsViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Settings/NotificationSettingsViewModel.swift
import NotificationAuthorizationStatus // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/NotificationManager.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import SecondaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/SecondaryButton.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import View // src/ios/AmiraWellness/AmiraWellness/Core/Extensions/View+Extensions.swift

/// A SwiftUI view that allows users to configure notification preferences
struct NotificationSettingsView: View {
    
    /// The view model for managing notification settings state and functionality
    @StateObject var viewModel: NotificationSettingsViewModel
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode
    
    /// State variable to control the visibility of the time picker
    @State private var showTimePicker: Bool = false
    
    /// Temporary storage for the selected hour before saving
    @State private var tempHour: Int
    
    /// Temporary storage for the selected minute before saving
    @State private var tempMinute: Int
    
    /// Initializes the notification settings view with an optional view model
    /// - Parameter viewModel: An optional NotificationSettingsViewModel instance. If nil, a new instance is created.
    init(viewModel: NotificationSettingsViewModel? = nil) {
        // Initialize the viewModel StateObject with the provided viewModel or create a new NotificationSettingsViewModel instance
        _viewModel = StateObject(wrappedValue: viewModel ?? NotificationSettingsViewModel(notificationService: .init()))
        
        // Initialize tempHour with viewModel.reminderHour
        _tempHour = State(initialValue: viewModel?.reminderHour ?? 10)
        
        // Initialize tempMinute with viewModel.reminderMinute
        _tempMinute = State(initialValue: viewModel?.reminderMinute ?? 0)
    }
    
    /// Builds the notification settings view with all sections and components
    var body: some View {
        ScrollView { // Create a ScrollView containing a VStack for all settings
            VStack(alignment: .leading, spacing: 20) {
                permissionSection() // Add the permission section showing notification authorization status
                
                notificationTypesSection() // Add the notification types section with toggles for different notification types
                
                dailyReminderSection() // Add the daily reminder section with time picker and day selection
                
                actionsSection() // Add the actions section with save, reset, and system settings buttons
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showPermissionAlert) { // Add alert for permission denied
            Alert(
                title: Text("Permiso denegado"), // Permission denied
                message: Text("Por favor, habilita las notificaciones en la configuración de tu dispositivo para recibir recordatorios."), // Please enable notifications in your device settings to receive reminders.
                primaryButton: .default(Text("Ir a la configuración"), action: { // Go to settings
                    viewModel.openSystemSettings()
                }),
                secondaryButton: .cancel(Text("Cancelar")) // Cancel
            )
        }
        .alert(isPresented: $viewModel.showError) { // Add alert for error messages
            Alert(
                title: Text("Error"), // Error
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK")) // OK
            )
        }
        .overlay(viewModel.isLoading ? ProgressView().centerInScreen() : nil) // Add loading overlay for operations in progress
        .navigationTitle("Notificaciones") // Set the navigation title to "Notificaciones"
        .onAppear { // Add .onAppear modifier to call viewModel.loadNotificationSettings()
            viewModel.loadNotificationSettings()
        }
    }
    
    /// Creates the permission section showing notification authorization status
    @ViewBuilder private func permissionSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title "Permisos"
            sectionHeader(title: "Permisos") // Add a section header with the title "Permisos"
            
            if viewModel.authorizationStatus == .notDetermined { // If status is notDetermined, add a button to request permissions
                Text("La aplicación necesita permiso para enviarte notificaciones. ¿Quieres permitirlo?") // The application needs permission to send you notifications. Do you want to allow it?
                    .foregroundColor(ColorConstants.textSecondary)
                
                PrimaryButton(title: "Permitir notificaciones") { // Allow notifications
                    viewModel.requestNotificationPermissions()
                }
            } else if viewModel.authorizationStatus == .denied { // If status is denied, add a button to open system settings
                Text("Las notificaciones están desactivadas. Por favor, habilítalas en la configuración de tu dispositivo.") // Notifications are disabled. Please enable them in your device settings.
                    .foregroundColor(ColorConstants.textSecondary)
                
                PrimaryButton(title: "Abrir configuración") { // Open settings
                    viewModel.openSystemSettings()
                }
            } else if viewModel.authorizationStatus == .authorized { // If status is authorized, show a confirmation message
                Text("Las notificaciones están habilitadas.") // Notifications are enabled.
                    .foregroundColor(ColorConstants.success)
            }
        }
        .cardStyle() // Apply consistent styling with dividers and padding
    }
    
    /// Creates the notification types section with toggles
    @ViewBuilder private func notificationTypesSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title "Tipos de notificaciones"
            sectionHeader(title: "Tipos de notificaciones") // Add a section header with the title "Tipos de notificaciones"
            
            Toggle("Recordatorios diarios", isOn: $viewModel.dailyRemindersEnabled) // Add a Toggle for daily reminders bound to viewModel.dailyRemindersEnabled
            
            Divider().background(ColorConstants.divider) // Add a Divider
            
            Toggle("Recordatorios de racha", isOn: $viewModel.streakRemindersEnabled) // Add a Toggle for streak reminders bound to viewModel.streakRemindersEnabled
            
            Divider().background(ColorConstants.divider) // Add a Divider
            
            Toggle("Logros desbloqueados", isOn: $viewModel.achievementsEnabled) // Add a Toggle for achievements bound to viewModel.achievementsEnabled
            
            Divider().background(ColorConstants.divider) // Add a Divider
            
            Toggle("Afirmaciones diarias", isOn: $viewModel.affirmationsEnabled) // Add a Toggle for affirmations bound to viewModel.affirmationsEnabled
            
            Divider().background(ColorConstants.divider) // Add a Divider
            
            Toggle("Consejos de bienestar", isOn: $viewModel.wellnessTipsEnabled) // Add a Toggle for wellness tips bound to viewModel.wellnessTipsEnabled
            
            Divider().background(ColorConstants.divider) // Add a Divider
            
            Toggle("Actualizaciones de la app", isOn: $viewModel.appUpdatesEnabled) // Add a Toggle for app updates bound to viewModel.appUpdatesEnabled
        }
        .disabled(!viewModel.notificationsEnabled) // Disable toggles if notifications are not authorized
        .cardStyle() // Apply consistent styling with dividers between options
    }
    
    /// Creates the daily reminder section with time picker and day selection
    @ViewBuilder private func dailyReminderSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with section title "Recordatorios diarios"
            sectionHeader(title: "Recordatorios diarios") // Add a section header with the title "Recordatorios diarios"
            
            Button { // Add a button to show time picker with current time
                showTimePicker.toggle()
            } label: {
                HStack {
                    Text("Hora: \(viewModel.getFormattedTime())") // Time: [formatted time]
                    Spacer()
                    Image(systemName: "clock")
                }
                .foregroundColor(ColorConstants.textPrimary)
                .padding()
                .background(ColorConstants.surface)
                .cornerRadius(8)
            }
            .disabled(!viewModel.dailyRemindersEnabled || !viewModel.notificationsEnabled) // Disable controls if daily reminders are not enabled or notifications are not authorized
            
            if showTimePicker { // Add a time picker when showTimePicker is true
                timePicker()
            }
            
            Text("Días:") // Days:
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            daySelectionRow() // Add day selection buttons for each day of the week
        }
        .disabled(!viewModel.dailyRemindersEnabled || !viewModel.notificationsEnabled) // Disable controls if daily reminders are not enabled or notifications are not authorized
        .cardStyle() // Apply consistent styling with dividers and padding
    }
    
    /// Creates a time picker for selecting reminder time
    @ViewBuilder private func timePicker() -> some View {
        VStack { // Create a VStack with time picker controls
            HStack { // Add a HStack with hour and minute pickers
                Picker("Hora", selection: $tempHour) { // Add Picker for hour selection (0-23)
                    ForEach(0..<24) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .labelsHidden()
                
                Text(":") // Add a colon separator
                
                Picker("Minuto", selection: $tempMinute) { // Add Picker for minute selection (0-59)
                    ForEach(0..<60) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .labelsHidden()
            }
            
            HStack { // Add buttons to confirm or cancel time selection
                Button("Cancelar") { // Cancel
                    showTimePicker = false
                    tempHour = viewModel.reminderHour
                    tempMinute = viewModel.reminderMinute
                }
                .padding()
                
                Button("Guardar") { // Save
                    viewModel.reminderHour = tempHour
                    viewModel.reminderMinute = tempMinute
                    showTimePicker = false
                }
                .padding()
            }
        }
    }
    
    /// Creates a row of day selection buttons
    @ViewBuilder private func daySelectionRow() -> some View {
        HStack { // Create a HStack with day selection buttons
            ForEach(1..<8) { day in // For each day (1-7), create a circular button
                Button {
                    viewModel.toggleDay(day: day) // Set button action to toggle day selection using viewModel.toggleDay
                } label: {
                    Text(viewModel.getDayName(day: day))
                        .font(.system(size: 14))
                        .frame(width: 30, height: 30)
                        .foregroundColor(viewModel.isDaySelected(day: day) ? .white : ColorConstants.textPrimary) // Style selected days differently from unselected days
                        .background(viewModel.isDaySelected(day: day) ? ColorConstants.primary : ColorConstants.surface)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    /// Creates the actions section with buttons
    @ViewBuilder private func actionsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // Create a VStack with action buttons
            sectionHeader(title: "Acciones") // Add a section header with the title "Acciones"
            
            PrimaryButton(title: "Guardar", isEnabled: !viewModel.isLoading) { // Add a PrimaryButton to save settings that calls viewModel.saveNotificationSettings()
                viewModel.saveNotificationSettings()
            }
            
            SecondaryButton(title: "Restablecer valores predeterminados", isEnabled: !viewModel.isLoading) { // Add a SecondaryButton to reset to defaults that calls viewModel.resetToDefaults()
                viewModel.resetToDefaults()
            }
            
            if viewModel.authorizationStatus == .denied { // If permissions are denied, add a button to open system settings
                SecondaryButton(title: "Abrir configuración del sistema", isEnabled: !viewModel.isLoading) { // Open system settings
                    viewModel.openSystemSettings()
                }
            }
        }
        .cardStyle() // Apply consistent styling with appropriate spacing
    }
    
    /// Creates a consistent section header with the given title
    @ViewBuilder private func sectionHeader(title: String) -> some View { // Create a Text view with the provided title
        Text(title) // Apply consistent styling (font, color, alignment)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(ColorConstants.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading) // Add appropriate padding and frame
    }
}