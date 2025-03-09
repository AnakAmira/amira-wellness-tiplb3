import SwiftUI // iOS SDK
import Combine // For handling asynchronous events and state changes

// Internal imports
import EmotionalCheckinResultViewModel // Provides the business logic and state management for the emotional check-in result screen
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import EmotionalInsight // Model for emotional insights derived from analysis
import InsightType // Enumeration of insight types
import Tool // Model for emotional regulation tools
import EmotionCard // Reusable component for displaying emotional states
import ToolCard // Reusable component for displaying tool information
import PrimaryButton // Reusable component for primary action buttons
import SecondaryButton // Reusable component for secondary action buttons
import LoadingView // Reusable component for displaying loading state
import ColorConstants // Access to app's color constants for consistent styling

/// A SwiftUI view that displays the results of an emotional check-in
struct EmotionalCheckinResultView: View {
    
    /// Observed object for managing the state of the view
    @ObservedObject var viewModel: EmotionalCheckinResultViewModel
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    /// Optional closure to handle tool selection
    var onToolSelected: ((String) -> Void)?
    
    /// Optional closure to handle navigation to the tool library
    var onViewAllTools: (() -> Void)?
    
    /// Optional closure to handle dismissal of the view
    var onDismiss: (() -> Void)?
    
    /// Initializes the EmotionalCheckinResultView with a view model and navigation options
    /// - Parameters:
    ///   - viewModel: The view model for the emotional check-in result
    ///   - onToolSelected: Optional closure to handle tool selection
    ///   - onViewAllTools: Optional closure to handle navigation to the tool library
    ///   - onDismiss: Optional closure to handle dismissal of the view
    init(
        viewModel: EmotionalCheckinResultViewModel,
        onToolSelected: ((String) -> Void)? = nil,
        onViewAllTools: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        // Store the provided viewModel
        self.viewModel = viewModel
        // Store the provided onToolSelected closure (defaults to nil)
        self.onToolSelected = onToolSelected
        // Store the provided onViewAllTools closure (defaults to nil)
        self.onViewAllTools = onViewAllTools
        // Store the provided onDismiss closure (defaults to nil)
        self.onDismiss = onDismiss
    }
    
    /// Builds the emotional check-in result view with all its components
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView()
                    currentEmotionSection()
                    emotionalShiftSection()
                    insightsSection()
                    recommendedToolsSection()
                    actionButtonsSection()
                }
                .padding()
                .background(ColorConstants.background)
            }
            
            if viewModel.isLoading {
                LoadingView(isLoading: viewModel.isLoading)
            }
            
            if viewModel.showError {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"), action: {
                        viewModel.dismissError()
                    })
                )
            }
        }
    }
    
    /// Creates the header section with title and close button
    private func headerView() -> some View {
        HStack {
            Text("Resultados del check-in")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            Button(action: {
                handleDismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorConstants.textSecondary)
            }
        }
    }
    
    /// Creates a section showing the current emotional state
    private func currentEmotionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tu emoción actual:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            EmotionCard(emotionalState: viewModel.currentState)
        }
    }
    
    /// Creates a section showing the emotional shift if applicable
    private func emotionalShiftSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tu cambio emocional:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(viewModel.getEmotionalShiftDescription())
                .font(.body)
                .foregroundColor(ColorConstants.textPrimary)
        }
        .opacity(viewModel.previousState != nil ? 1 : 0)
    }
    
    /// Creates a section showing emotional insights if available
    private func insightsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            ForEach(viewModel.insights, id: \.description) { insight in
                HStack {
                    Image(systemName: insight.type.icon())
                        .foregroundColor(ColorConstants.primary)
                    Text(insight.description)
                        .font(.body)
                        .foregroundColor(ColorConstants.textPrimary)
                }
            }
        }
        .opacity(!viewModel.insights.isEmpty ? 1 : 0)
    }
    
    /// Creates a section showing recommended tools
    private func recommendedToolsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Herramientas recomendadas:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            ForEach(viewModel.recommendedTools, id: \.id) { tool in
                ToolCard(tool: tool) {
                    handleToolSelection(tool: tool)
                }
            }
        }
        .opacity(!viewModel.recommendedTools.isEmpty ? 1 : 0)
    }
    
    /// Creates a section with action buttons
    private func actionButtonsSection() -> some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Ver todas las herramientas") {
                navigateToToolLibrary()
            }
            
            SecondaryButton(title: "Volver al inicio") {
                handleDismiss()
            }
        }
    }
    
    /// Handles the dismissal of the view
    private func handleDismiss() {
        viewModel.dismissResult()
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Handles the selection of a recommended tool
    private func handleToolSelection(tool: Tool) {
        viewModel.selectTool(tool.id.uuidString)
        if let onToolSelected = onToolSelected {
            onToolSelected(tool.id.uuidString)
        } else {
            // Handle tool selection locally
        }
    }
    
    /// Navigates to the tool library
    private func navigateToToolLibrary() {
        if let onViewAllTools = onViewAllTools {
            onViewAllTools()
        } else {
            // Handle navigation locally or dismiss
        }
    }
}

/// Provides preview functionality for SwiftUI Canvas
struct EmotionalCheckinResultView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = EmotionalCheckinResultViewModel(
            currentState: EmotionalState(
                emotionType: .joy,
                intensity: 7,
                context: .postJournaling
            ),
            previousState: EmotionalState(
                emotionType: .anxiety,
                intensity: 5,
                context: .preJournaling
            )
        )
        
        Group {
            EmotionalCheckinResultView(viewModel: mockViewModel)
                .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
                .preferredColorScheme(.light)
                .previewDisplayName("Default")
            
            EmotionalCheckinResultView(viewModel: mockViewModel)
                .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}