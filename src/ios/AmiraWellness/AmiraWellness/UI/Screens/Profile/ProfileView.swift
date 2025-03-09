# src/ios/AmiraWellness/AmiraWellness/UI/Screens/Profile/ProfileView.swift
import SwiftUI // SwiftUI - iOS SDK
import SwiftUI // SwiftUI - iOS SDK

// Internal imports
import ProfileViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Profile/ProfileViewModel.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import SubscriptionTier // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import ProfileError // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Profile/ProfileViewModel.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import SecondaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/SecondaryButton.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import ErrorView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/ErrorView.swift
import ConfirmationDialog // src/ios/AmiraWellness/AmiraWellness/UI/Components/Modals/ConfirmationDialog.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import CardModifier // src/ios/AmiraWellness/AmiraWellness/Core/Modifiers/CardModifier.swift

/// A SwiftUI view that displays the user's profile information and account management options
struct ProfileView: View {
    
    // MARK: - Properties
    
    /// View model for managing profile data and operations
    @StateObject private var viewModel = ProfileViewModel()
    
    /// State variable to control the visibility of the logout confirmation dialog
    @State private var showLogoutConfirmation = false
    
    /// State variable to control the visibility of the delete account confirmation dialog
    @State private var showDeleteAccountConfirmation = false
    
    /// State variable to control the visibility of the export data confirmation dialog
    @State private var showExportConfirmation = false
    
    /// State variable to control the visibility of the share sheet
    @State private var showShareSheet = false
    
    /// State variable to store the password for account deletion
    @State private var deleteAccountPassword = ""
    
    /// State variable to control the visibility of the password field
    @State private var showPasswordField = false
    
    /// State variable to control navigation to the settings screen
    @State private var navigateToSettings = false
    
    /// State variable to control navigation to the login screen
    @State private var navigateToLogin = false
    
    /// Presentation mode for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Body
    
    /// Builds the profile view with user information and account options
    var body: some View {
        NavigationView { // Create a NavigationView as the container
            ZStack { // Inside the NavigationView, create a ZStack to handle loading and content states
                if viewModel.isLoading { // If viewModel.isLoading is true, display a LoadingView
                    LoadingView(message: "Cargando perfil...")
                } else if let error = viewModel.error { // If viewModel.error is not nil, display an ErrorView with retry action
                    ErrorView(
                        message: "Error al cargar el perfil: \(error.localizedDescription)",
                        retryAction: {
                            viewModel.clearError()
                            viewModel.fetchUserProfile()
                        }
                    )
                } else { // Otherwise, display the main content in a ScrollView
                    ScrollView {
                        VStack(spacing: 20) {
                            profileHeaderView() // Display the profile header
                            
                            statisticsView() // Display user statistics
                            
                            accountActionsView() // Display account management actions
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.fetchUserProfile()
                    }
                }
            }
            .navigationTitle("Mi Perfil") // Add a navigation title "Mi Perfil" (My Profile)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Text("Settings Screen")) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .background(ColorConstants.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToSettings) {
                Text("Settings Screen")
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                Text("Login Screen")
            }
            .confirmationDialog(
                "¿Estás seguro que quieres cerrar sesión?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible,
                actions: {
                    Button("Cerrar sesión", role: .destructive) {
                        handleLogout()
                    }
                    Button("Cancelar", role: .cancel) {
                        showLogoutConfirmation = false
                    }
                },
                message: {
                    Text("Se borrarán todos los datos de la sesión actual.")
                }
            )
            .confirmationDialog(
                "¿Estás seguro que quieres eliminar tu cuenta?",
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible,
                actions: {
                    if showPasswordField {
                        SecureField("Contraseña", text: $deleteAccountPassword)
                            .textContentType(.password)
                            .border(.secondary)
                    }
                    Button("Eliminar cuenta", role: .destructive) {
                        handleDeleteAccount()
                    }
                    Button("Cancelar", role: .cancel) {
                        showDeleteAccountConfirmation = false
                        showPasswordField = false
                    }
                },
                message: {
                    Text("Esta acción es irreversible. Todos tus datos serán eliminados.")
                }
            )
            .confirmationDialog(
                "¿Estás seguro que quieres exportar tus datos?",
                isPresented: $showExportConfirmation,
                titleVisibility: .visible,
                actions: {
                    Button("Exportar", role: .destructive) {
                        handleExportData()
                    }
                    Button("Cancelar", role: .cancel) {
                        showExportConfirmation = false
                    }
                },
                message: {
                    Text("Se creará un archivo con toda tu información.")
                }
            )
            .sheet(isPresented: $showShareSheet, onDismiss: {
                viewModel.exportURL = nil
            }, content: {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                } else {
                    Text("No se pudo exportar los datos.")
                }
            })
        }
        .accessibilityLabel("Perfil del usuario")
    }
    
    /// Creates the header section with user profile information
    @ViewBuilder
    private func profileHeaderView() -> some View {
        VStack(alignment: .center, spacing: 8) { // Create a VStack for the header content
            Image(systemName: "person.circle.fill") // Display user avatar or placeholder
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(ColorConstants.primary)
            
            Text(viewModel.userProfile?.name ?? "Usuario") // Display user name with primary text style
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text(viewModel.userProfile?.email ?? "correo@ejemplo.com") // Display user email with secondary text style
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(viewModel.isPremiumUser() ? "Premium" : "Gratis") // Display membership status (premium or free)
                .font(.footnote)
                .foregroundColor(ColorConstants.secondary)
            
            Text("Miembro desde: \(viewModel.getMemberSince())") // Display member since date
                .font(.caption)
                .foregroundColor(ColorConstants.textTertiary)
        }
        .padding() // Apply appropriate styling and spacing
        .cardStyle() // Apply cardStyle modifier for consistent styling
    }
    
    /// Creates a view showing user statistics and achievements
    @ViewBuilder
    private func statisticsView() -> some View {
        VStack(alignment: .leading, spacing: 12) { // Create a VStack for the statistics content
            Text("Estadísticas") // Add a section title "Estadísticas" (Statistics)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .padding(.bottom, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { // Create a grid layout for statistics items
                statisticsItemView(title: "Diarios de voz", value: "\(viewModel.getJournalCount())", icon: "mic.fill") // Add statistics items for journal count
                statisticsItemView(title: "Check-ins emocionales", value: "\(viewModel.getCheckinCount())", icon: "heart.fill") // Add statistics items for check-in count
                statisticsItemView(title: "Herramientas usadas", value: "\(viewModel.getToolUsageCount())", icon: "wrench.and.screwdriver.fill") // Add statistics items for tool usage count
                statisticsItemView(title: "Racha actual", value: "\(viewModel.getCurrentStreak()) días", icon: "flame.fill") // Add statistics items for current streak
                statisticsItemView(title: "Racha más larga", value: "\(viewModel.getLongestStreak()) días", icon: "crown.fill") // Add statistics items for longest streak
                statisticsItemView(title: "Logros", value: "\(viewModel.getAchievementCount())", icon: "trophy.fill") // Add statistics items for achievements count
            }
        }
        .padding() // Apply appropriate styling and spacing
        .cardStyle() // Apply cardStyle modifier for consistent styling
    }
    
    /// Creates a view for an individual statistics item
    @ViewBuilder
    private func statisticsItemView(title: String, value: String, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) { // Create a VStack for the item content
            if let icon = icon { // If icon is provided, display the icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(ColorConstants.secondary)
            }
            
            Text(value) // Display the value with large, bold text
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text(title) // Display the title with secondary text style
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates a view with account management actions
    @ViewBuilder
    private func accountActionsView() -> some View {
        VStack(alignment: .leading, spacing: 12) { // Create a VStack for the actions content
            Text("Cuenta") // Add a section title "Cuenta" (Account)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .padding(.bottom, 4)
            
            actionButtonView(title: "Configuración", icon: "gearshape", iconColor: ColorConstants.primary) { // Add a button to navigate to settings
                navigateToSettings = true
            }
            
            actionButtonView(title: "Exportar mis datos", icon: "square.and.arrow.up", iconColor: ColorConstants.secondary) { // Add a button to export user data
                showExportConfirmation = true
            }
            
            actionButtonView(title: "Cerrar sesión", icon: "arrow.left.square", iconColor: ColorConstants.warning) { // Add a button to log out
                showLogoutConfirmation = true
            }
            
            actionButtonView(title: "Eliminar cuenta", icon: "xmark.seal", iconColor: ColorConstants.error) { // Add a button to delete account
                showDeleteAccountConfirmation = true
                showPasswordField = true
            }
        }
        .padding() // Apply appropriate styling and spacing
        .cardStyle() // Apply cardStyle modifier for consistent styling
    }
    
    /// Creates a button view for account actions
    @ViewBuilder
    private func actionButtonView(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { // Create a Button with the provided action
            HStack { // Inside the button, create an HStack for layout
                Image(systemName: icon) // Display the icon with the specified color
                    .foregroundColor(iconColor)
                
                Text(title) // Display the title text
                    .foregroundColor(ColorConstants.textPrimary)
                
                Spacer() // Add a spacer to push content to the left
                
                Image(systemName: "chevron.right") // Add a chevron icon to indicate the button is tappable
                    .foregroundColor(ColorConstants.textSecondary)
            }
            .padding(.vertical, 8) // Apply appropriate styling and spacing
        }
    }
    
    // MARK: - Action Handlers
    
    /// Handles the logout action
    private func handleLogout() {
        viewModel.logout { result in
            switch result {
            case .success:
                navigateToLogin = true
            case .failure(let error):
                print("Logout failed: \(error)")
            }
        }
    }
    
    /// Handles the delete account action
    private func handleDeleteAccount() {
        viewModel.deleteAccount(password: deleteAccountPassword) { result in
            switch result {
            case .success:
                navigateToLogin = true
            case .failure(let error):
                print("Account deletion failed: \(error)")
            }
            deleteAccountPassword = ""
        }
    }
    
    /// Handles the export data action
    private func handleExportData() {
        viewModel.exportUserData { result in
            switch result {
            case .success(let url):
                viewModel.exportURL = url
                showShareSheet = true
            case .failure(let error):
                print("Data export failed: \(error)")
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    
    var items: [Any]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {
        
    }
}