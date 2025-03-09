import SwiftUI // iOS SDK
import Combine // For handling asynchronous events and state changes

// Internal imports
import ToolCompletionViewModel // Provides the business logic and state management for the tool completion screen
import EmotionalCheckinView // Provides the emotional check-in interface after tool completion
import EmotionalCheckinViewModel // Provides the view model for the emotional check-in screen
import PrimaryButton // Reusable primary button component for main actions
import SecondaryButton // Reusable secondary button component for alternative actions
import SuccessView // Reusable component for displaying success feedback
import ToolCard // Reusable component for displaying tool information
import Tool // Model representing a tool in the tool library
import EmotionalState // Model representing a user's emotional state
import CheckInContext // Enum defining the context of an emotional check-in
import ColorConstants // Provides consistent color constants throughout the app

/// A SwiftUI view that displays the completion screen after a user finishes using a tool from the tool library.
/// It shows a success message, provides options for emotional check-in, displays emotional shift insights if applicable,
/// and offers recommended tools based on the user's emotional state.
struct ToolCompletionView: View {
    
    /// Observed object for managing the state of the view
    @ObservedObject var viewModel: ToolCompletionViewModel
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    /// Callback to handle navigation to a specific tool
    var onNavigateToTool: ((String) -> Void)?
    
    /// Callback to handle navigation to the home screen
    var onNavigateToHome: (() -> Void)?
    
    /// Builds the tool completion view with all its components
    var body: some View {
        NavigationView { // NV1: Create a NavigationView as the main container
            ZStack { // ZS1: Add a ZStack to layer content and loading overlay
                ScrollView { // SV1: Add a ScrollView with the main content
                    VStack(spacing: 20) { // VS1: Add a VStack to organize the content vertically
                        if viewModel.showEmotionalCheckIn { // IF1: If viewModel.showEmotionalCheckIn is true, show the emotional check-in section
                            emotionalCheckInSection()
                        }
                        
                        if viewModel.showRecommendations { // IF2: If viewModel.showRecommendations is true, show the recommendations section
                            recommendationsSection()
                        }
                    }
                    .padding() // P1: Apply appropriate spacing
                    .background(ColorConstants.background) // BG1: Apply appropriate background color
                }
                
                if viewModel.isLoading { // IF3: Add a loading overlay when viewModel.isLoading is true
                    loadingOverlay()
                }
                
                if viewModel.showError { // IF4: Add an alert for error messages that shows when viewModel.showError is true
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.errorMessage ?? "Unknown error"),
                        dismissButton: .default(Text("OK"), action: {
                            viewModel.dismissError()
                        })
                    )
                }
            }
            .onAppear {
                viewModel.navigateToHome = false
                viewModel.navigateToTool = false
            }
            .onChange(of: viewModel.navigateToHome) { _ in
                handleHomeNavigation() // NH1: Add navigation handling for home and tool navigation
            }
            .onChange(of: viewModel.navigateToTool) { _ in
                handleToolNavigation() // NH2: Add navigation handling for home and tool navigation
            }
        }
    }
    
    /// Initializes the ToolCompletionView with a view model
    /// - Parameters:
    ///   - viewModel: The view model for the tool completion screen
    ///   - onNavigateToTool: Callback to handle navigation to a specific tool
    ///   - onNavigateToHome: Callback to handle navigation to the home screen
    init(viewModel: ToolCompletionViewModel, onNavigateToTool: ((String) -> Void)? = nil, onNavigateToHome: (() -> Void)? = nil) {
        // S1: Store the provided viewModel
        self.viewModel = viewModel
        // S2: Store the navigation callbacks
        self.onNavigateToTool = onNavigateToTool
        self.onNavigateToHome = onNavigateToHome
    }
    
    /// Creates the emotional check-in section with embedded EmotionalCheckinView
    private func emotionalCheckInSection() -> some View {
        VStack(alignment: .center, spacing: 20) { // VS1: Create a VStack for vertical layout
            Text("Herramienta completada") // T1: Add a title 'Herramienta completada'
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            SuccessView( // SV1: Add a SuccessView with appropriate animation and message
                message: "¿Cómo te sientes ahora?" // M1: Add a subtitle asking about emotional state
            )
            
            if viewModel.showEmotionalCheckIn {
                let checkinViewModel = EmotionalCheckinViewModel(emotionService: viewModel.emotionService, context: .toolUsage)
                EmotionalCheckinView(viewModel: checkinViewModel, onComplete: { emotionalState in // EV1: Embed an EmotionalCheckinView with the view model
                    viewModel.recordEmotionalState(emotionalState: emotionalState) // OC1: Configure the EmotionalCheckinView with onComplete callback that calls viewModel.recordEmotionalState
                }, onDismiss: {
                    viewModel.skipEmotionalCheckIn()
                })
                .frame(height: 400)
            }
            
            SecondaryButton(title: "Omitir", action: { // SB1: Add a SecondaryButton to skip the check-in that calls viewModel.skipEmotionalCheckIn
                viewModel.skipEmotionalCheckIn() // SC1: Add a SecondaryButton to skip the check-in that calls viewModel.skipEmotionalCheckIn
            })
        }
        .padding() // P1: Apply appropriate styling and spacing
    }
    
    /// Creates the recommendations section with emotional insights and tool recommendations
    private func recommendationsSection() -> some View {
        VStack(alignment: .center, spacing: 20) { // VS1: Create a VStack for vertical layout
            SuccessView( // SV1: Add a SuccessView with appropriate animation and message
                message: "¡Recomendaciones personalizadas!"
            )
            
            if viewModel.emotionalShiftAnalyzed { // IF1: If viewModel.emotionalShiftAnalyzed is true, add the emotional shift insights section
                emotionalShiftSection()
            }
            
            Text("Herramientas recomendadas:") // T1: Add a section title for recommended tools
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            ForEach(viewModel.recommendedTools, id: \.id) { tool in // FE1: Add a ForEach loop to display ToolCard for each recommended tool
                ToolCard(tool: tool) { // TC1: Configure each ToolCard with onTap callback that calls viewModel.selectRecommendedTool
                    viewModel.selectRecommendedTool(tool: tool) // SC1: Configure each ToolCard with onTap callback that calls viewModel.selectRecommendedTool
                }
            }
            
            PrimaryButton(title: "Volver al inicio", action: { // PB1: Add a PrimaryButton to return to home that calls viewModel.navigateToHomeScreen
                viewModel.navigateToHomeScreen() // NH1: Add a PrimaryButton to return to home that calls viewModel.navigateToHomeScreen
            })
        }
        .padding() // P1: Apply appropriate styling and spacing
    }
    
    /// Creates the emotional shift insights section
    private func emotionalShiftSection() -> some View {
        VStack(alignment: .leading, spacing: 10) { // VS1: Create a VStack for vertical layout
            Text("Tu cambio emocional:") // T1: Add a section title 'Tu cambio emocional:'
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(viewModel.emotionChanged ? "Tu emoción ha cambiado." : "Tu emoción no ha cambiado.") // T2: Add text showing if emotion changed and intensity change
                .font(.body)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text("Cambio de intensidad: \(viewModel.intensityChange)") // T3: Add text showing if emotion changed and intensity change
                .font(.body)
                .foregroundColor(ColorConstants.textPrimary)
            
            ForEach(viewModel.emotionalInsights, id: \.self) { insight in // FE1: Add a ForEach loop to display each insight from viewModel.emotionalInsights
                Text(insight) // T4: Add a ForEach loop to display each insight from viewModel.emotionalInsights
                    .font(.body)
                    .foregroundColor(ColorConstants.textSecondary)
            }
        }
        .padding() // P1: Apply appropriate styling and spacing
    }
    
    /// Creates a loading overlay for async operations
    private func loadingOverlay() -> some View {
        ZStack { // ZS1: Create a ZStack with a semi-transparent background
            Color.black.opacity(0.5) // C1: Create a ZStack with a semi-transparent background
                .edgesIgnoringSafeArea(.all)
            
            ProgressView("Cargando...") // PV1: Add a ProgressView with a loading message
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .foregroundColor(.white)
        }
    }
    
    /// Handles navigation to a selected tool
    private func handleToolNavigation() {
        // C1: Check if viewModel.selectedTool is not nil
        guard let selectedToolId = viewModel.selectedTool?.id.uuidString else {
            return
        }
        // C2: If not nil, call onNavigateToTool with the tool ID
        onNavigateToTool?(selectedToolId)
        // D1: Dismiss the current view using presentationMode
        presentationMode.wrappedValue.dismiss()
    }
    
    /// Handles navigation to the home screen
    private func handleHomeNavigation() {
        // C1: Call onNavigateToHome
        onNavigateToHome?()
        // D1: Dismiss the current view using presentationMode
        presentationMode.wrappedValue.dismiss()
    }
}