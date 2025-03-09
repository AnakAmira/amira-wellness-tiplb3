import SwiftUI // Version: iOS SDK
import Combine // Version: iOS SDK

// Internal imports
import ToolInProgressViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolInProgressViewModel.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolContentType // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolStep // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import IconButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/IconButton.swift
import ProgressBar // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/ProgressBar.swift
import WaveformAnimation // src/ios/AmiraWellness/AmiraWellness/UI/Components/Animation/WaveformAnimation.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import ConfirmationDialog // src/ios/AmiraWellness/AmiraWellness/UI/Components/Modals/ConfirmationDialog.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// A SwiftUI view that displays and manages the in-progress state of a tool being used by the user
struct ToolInProgressView: View {
    
    // MARK: - Observed Object
    
    /// Observed object for managing the tool in progress state
    @ObservedObject var viewModel: ToolInProgressViewModel
    
    // MARK: - Environment
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    /// Closure to be executed when the tool is completed
    var onToolCompleted: ((String) -> Void)?
    
    /// Closure to be executed when the view is dismissed
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes the ToolInProgressView with a view model and navigation closures
    /// - Parameters:
    ///   - viewModel: The view model for the tool in progress
    ///   - onToolCompleted: Closure to be executed when the tool is completed (optional)
    ///   - onDismiss: Closure to be executed when the view is dismissed (optional)
    init(viewModel: ToolInProgressViewModel, onToolCompleted: ((String) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        // Store the provided viewModel
        self.viewModel = viewModel
        
        // Store the provided onToolCompleted closure (or nil)
        self.onToolCompleted = onToolCompleted
        
        // Store the provided onDismiss closure (or nil)
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    /// Builds the tool in progress view with all its components
    /// - Returns: The composed view hierarchy
    var body: some View {
        ZStack {
            // Create a ZStack as the main container
            
            // Add a background color using ColorConstants.background
            ColorConstants.background
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Add a VStack to organize the content vertically
                
                // Add a header section with tool name and close button
                headerSection()
                
                // If isLoading is true, display LoadingView
                if viewModel.isLoading {
                    LoadingView(message: "Cargando herramienta...")
                } else {
                    // Otherwise, display the appropriate content based on tool.contentType
                    contentSection()
                }
                
                // Add a progress section with ProgressBar and time remaining
                progressSection()
                
                // Add control buttons for pause/resume, stop, and restart
                controlsSection()
                
                // For guided exercises, add next/previous step buttons
                if viewModel.tool.contentType == .guidedExercise {
                    stepNavigationSection()
                }
            }
            // Apply appropriate spacing, padding, and styling
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // Add navigation handling for tool completion
            .navigationBarHidden(true)
            .onReceive(viewModel.$navigateToCompletion) { shouldNavigate in
                if shouldNavigate {
                    handleToolCompletion()
                }
            }
            
            // Add confirmation dialog for exit confirmation
            ConfirmationDialog(
                title: "Salir de la herramienta",
                message: "¿Estás seguro de que quieres salir? El progreso no guardado se perderá.",
                confirmButtonTitle: "Salir",
                cancelButtonTitle: "Cancelar",
                isShowing: $viewModel.showConfirmExit,
                onConfirm: {
                    viewModel.confirmExitAndStop()
                    handleDismiss()
                },
                onCancel: {
                    viewModel.cancelExit()
                }
            )
            
            // Add error alert that shows when viewModel.showError is true
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"), action: {
                        viewModel.dismissError()
                    })
                )
            }
        }
        // Add onAppear modifier to start the tool
        .onAppear {
            viewModel.startTool()
        }
        // Add onDisappear modifier to clean up resources
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    /// Creates the header section with tool name and close button
    /// - Returns: The header section view
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            // Create an HStack for the header content
            
            // Add the tool name as a Text view with appropriate styling
            Text(viewModel.tool.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            // Add Spacer() to push content to edges
            Spacer()
            
            // Add a close button using IconButton with system name 'xmark'
            IconButton(
                systemName: "xmark",
                action: {
                    // Configure close button to call viewModel.confirmExit()
                    viewModel.confirmExit()
                }
            )
        }
        // Apply appropriate padding and styling
        .padding(.bottom)
    }
    
    /// Creates the main content section based on tool content type
    /// - Returns: The content section view
    @ViewBuilder
    private func contentSection() -> some View {
        GeometryReader { geometry in
            // Create a GeometryReader to get available space
            
            // Switch on viewModel.tool.contentType to determine the appropriate content view
            switch viewModel.tool.contentType {
            case .text:
                // For .text, create a ScrollView with the tool's instructions
                ScrollView {
                    Text(viewModel.tool.content.instructions)
                        .font(.body)
                        .foregroundColor(ColorConstants.textSecondary)
                        .padding(.bottom)
                }
            case .audio:
                // For .audio, create an audio visualization with WaveformAnimation
                WaveformAnimation()
                    .frame(height: geometry.size.height * 0.3)
            case .video:
                // For .video, create a placeholder for video content
                Text("Video content will be available soon")
                    .font(.title3)
                    .foregroundColor(ColorConstants.textSecondary)
            case .interactive:
                // For .interactive, create a placeholder for interactive content
                Text("Interactive content will be available soon")
                    .font(.title3)
                    .foregroundColor(ColorConstants.textSecondary)
            case .guidedExercise:
                // For .guidedExercise, create a step-based view with current step information
                stepContentView()
            }
        }
    }
    
    /// Creates the content view for a guided exercise step
    /// - Returns: The step content view
    @ViewBuilder
    private func stepContentView() -> some View {
        VStack {
            // Create a VStack for the step content
            
            // Add a step indicator (e.g., 'Step 2 of 5')
            Text("Paso \(viewModel.currentStepIndex + 1) de \(viewModel.steps?.count ?? 0)")
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
                .padding(.bottom, 4)
            
            // Add the step title with appropriate styling
            Text(viewModel.currentStep?.title ?? "Sin título")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .padding(.bottom, 8)
            
            // Add the step description with appropriate styling
            Text(viewModel.currentStep?.description ?? "Sin descripción")
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .padding(.bottom, 16)
            
            // Add step duration information
            Text("Duración: \(viewModel.currentStep?.formattedDuration() ?? "00:00")")
                .font(.callout)
                .foregroundColor(ColorConstants.textTertiary)
        }
        // Apply appropriate spacing and styling
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    /// Creates the progress section with progress bar and time remaining
    /// - Returns: The progress section view
    @ViewBuilder
    private func progressSection() -> some View {
        VStack {
            // Create a VStack for the progress content
            
            // Add a ProgressBar with viewModel.progress value
            ProgressBar(value: viewModel.progress)
                .padding(.bottom, 4)
            
            HStack {
                // Add an HStack for time information
                
                // Display the formatted time remaining
                Text("Tiempo restante: \(viewModel.formattedTimeRemaining)")
                    .font(.footnote)
                    .foregroundColor(ColorConstants.textTertiary)
            }
        }
        // Apply appropriate spacing and styling
        .padding(.bottom)
    }
    
    /// Creates the control buttons section
    /// - Returns: The controls section view
    @ViewBuilder
    private func controlsSection() -> some View {
        HStack {
            // Create an HStack for the control buttons
            
            // Add a restart button using IconButton with system name 'arrow.counterclockwise'
            IconButton(
                systemName: "arrow.counterclockwise",
                action: {
                    // Configure button to call viewModel.restartTool()
                    viewModel.restartTool()
                }
            )
            
            Spacer()
            
            // Add a play/pause button that changes based on viewModel.isPaused
            IconButton(
                systemName: viewModel.isPaused ? "play.fill" : "pause.fill",
                action: {
                    // Configure button to call appropriate viewModel methods
                    if viewModel.isPaused {
                        viewModel.resumeTool()
                    } else {
                        viewModel.pauseTool()
                    }
                }
            )
            
            Spacer()
            
            // Add a stop button using IconButton with system name 'stop.fill'
            IconButton(
                systemName: "stop.fill",
                action: {
                    // Configure button to call viewModel.stopTool()
                    viewModel.confirmExit()
                }
            )
        }
        // Apply appropriate spacing and styling
        .padding(.bottom)
    }
    
    /// Creates the step navigation section for guided exercises
    /// - Returns: The step navigation section view
    @ViewBuilder
    private func stepNavigationSection() -> some View {
        HStack {
            // Create an HStack for the navigation buttons
            
            // Add a previous step button using IconButton with system name 'chevron.left'
            IconButton(
                systemName: "chevron.left",
                isEnabled: viewModel.currentStepIndex > 0,
                action: {
                    // Configure button to call viewModel.previousStep()
                    viewModel.previousStep()
                }
            )
            
            Spacer()
            
            // Add a next step button using IconButton with system name 'chevron.right'
            IconButton(
                systemName: "chevron.right",
                isEnabled: viewModel.currentStepIndex < (viewModel.steps?.count ?? 0) - 1,
                action: {
                    // Configure button to call viewModel.nextStep()
                    viewModel.nextStep()
                }
            )
        }
        // Apply appropriate spacing and styling
        .padding(.bottom)
    }
    
    /// Handles the completion of a tool
    private func handleToolCompletion() {
        // If onToolCompleted is provided, call it with the tool ID
        if let onToolCompleted = onToolCompleted {
            onToolCompleted(viewModel.tool.id.uuidString)
        } else {
            // Otherwise, dismiss the current view using presentationMode
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Handles dismissal of the view
    private func handleDismiss() {
        // If onDismiss is provided, call it
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            // Otherwise, dismiss the current view using presentationMode
            presentationMode.wrappedValue.dismiss()
        }
    }
}