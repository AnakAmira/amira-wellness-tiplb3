import SwiftUI // iOS SDK
import Combine // For handling asynchronous events and state changes

// Internal imports
import EmotionalCheckinViewModel // Provides the business logic and state management for the emotional check-in screen
import EmotionalCheckinResultView // View for displaying the results of an emotional check-in
import EmotionalCheckinResultViewModel // ViewModel for the emotional check-in result screen
import EmotionSelector // Reusable component for selecting emotion types
import IntensitySlider // Reusable component for selecting emotion intensity
import PrimaryButton // Reusable component for primary action buttons
import LoadingView // Reusable component for displaying loading state
import EmotionType // Enumeration of emotion types
import ColorConstants // Access to app's color constants for consistent styling

/// SwiftUI view for the emotional check-in screen
struct EmotionalCheckinView: View {
    
    /// Observed object for managing the state of the view
    @ObservedObject var viewModel: EmotionalCheckinViewModel
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    /// Optional closure to handle completion of the check-in
    var onComplete: ((EmotionalState) -> Void)?
    
    /// Optional closure to handle dismissal of the view
    var onDismiss: (() -> Void)?
    
    /// State variable to control navigation to the result view
    @State private var showingResultView: Bool = false
    
    /// Initializes the EmotionalCheckinView with a view model and navigation closures
    /// - Parameters:
    ///   - viewModel: The view model for the emotional check-in screen
    ///   - onComplete: Optional closure to handle completion of the check-in
    ///   - onDismiss: Optional closure to handle dismissal of the view
    init(viewModel: EmotionalCheckinViewModel, onComplete: ((EmotionalState) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        // Store the provided viewModel
        self.viewModel = viewModel
        // Store the provided onComplete closure (defaults to nil)
        self.onComplete = onComplete
        // Store the provided onDismiss closure (defaults to nil)
        self.onDismiss = onDismiss
        // Initialize showingResultView to false
        self._showingResultView = State(initialValue: false)
    }
    
    /// Builds the emotional check-in view with all its components
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        headerView()
                        emotionSelectionSection()
                        intensitySection()
                        notesSection()
                        submitButtonSection()
                    }
                    .padding()
                    .background(ColorConstants.background)
                }
                
                if viewModel.isLoading {
                    LoadingView(isLoading: viewModel.isLoading)
                }
                
                NavigationLink(destination: EmotionalCheckinResultView(
                    viewModel: createResultViewModel(),
                    onDismiss: {
                        handleDismiss()
                    }
                ), isActive: $showingResultView) {
                    EmptyView()
                }
                .hidden()
                .onReceive(viewModel.$navigateToResult) { navigate in
                    if navigate {
                        handleCompletion()
                    }
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
    }
    
    /// Creates the header section with title and close button
    private func headerView() -> some View {
        HStack {
            Text("Check-in emocional")
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
    
    /// Creates the emotion selection section with the EmotionSelector component
    private func emotionSelectionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emoción principal:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            EmotionSelector(selectedEmotion: $viewModel.selectedEmotion, onEmotionSelected: { emotion in
                viewModel.selectEmotion(emotion: emotion)
            })
        }
    }
    
    /// Creates the intensity selection section with the IntensitySlider component
    private func intensitySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensidad:")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            IntensitySlider(value: $viewModel.intensity, emotionType: viewModel.selectedEmotion)
        }
    }
    
    /// Creates the notes section with a TextField for optional notes
    private func notesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Hay algo específico que te haga sentir así? (opcional)")
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            TextField("Escribe tus notas aquí", text: $viewModel.notes)
                .padding()
                .background(ColorConstants.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorConstants.border, lineWidth: 1)
                )
        }
    }
    
    /// Creates the submit button section with a PrimaryButton
    private func submitButtonSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PrimaryButton(title: "Guardar", action: {
                viewModel.submitEmotionalState()
            })
        }
    }
    
    /// Handles the dismissal of the view
    private func handleDismiss() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Handles the completion of the emotional check-in
    private func handleCompletion() {
        if viewModel.recordedState != nil {
            onComplete?(viewModel.recordedState!)
            showingResultView = true
        }
    }
    
    /// Creates a view model for the result view
    private func createResultViewModel() -> EmotionalCheckinResultViewModel {
        return EmotionalCheckinResultViewModel(currentState: viewModel.recordedState ?? EmotionalState(emotionType: .joy, intensity: 5, context: .standalone))
    }
}