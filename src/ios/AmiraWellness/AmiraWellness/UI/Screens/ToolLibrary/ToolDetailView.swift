# <file_path>
```swift
import SwiftUI // Version: iOS SDK
import Combine // Version: standard library

// Internal imports
import ToolDetailViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolDetailViewModel.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import ToolContentType // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolInProgressView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolInProgressView.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import IconButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/IconButton.swift
import CardModifier // src/ios/AmiraWellness/AmiraWellness/Core/Modifiers/CardModifier.swift
import WaveformAnimation // src/ios/AmiraWellness/AmiraWellness/UI/Components/Animation/WaveformAnimation.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import EmotionColors // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// A SwiftUI view that displays detailed information about a tool from the tool library
struct ToolDetailView: View {
    // MARK: - Properties
    
    /// The ID of the tool to display
    let toolId: String
    
    /// The view model for the tool detail screen
    @StateObject var viewModel: ToolDetailViewModel
    
    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    /// State variable to control the visibility of the share sheet
    @State private var showShareSheet: Bool = false
    
    /// State variable to store the URL to share
    @State private var shareURL: URL? = nil
    
    // MARK: - Initialization
    
    /// Initializes a new ToolDetailView with the specified tool ID
    /// - Parameters:
    ///   - toolId: The ID of the tool to display
    ///   - viewModel: An optional ToolDetailViewModel instance. If nil, a new one will be created.
    init(toolId: String, viewModel: ToolDetailViewModel? = nil) {
        // Store the toolId parameter
        self.toolId = toolId
        
        // Initialize viewModel as a StateObject with the provided viewModel or create a new one with the toolId
        _viewModel = StateObject(wrappedValue: viewModel ?? ToolDetailViewModel(toolId: toolId))
        
        // Initialize showShareSheet to false
        self.showShareSheet = false
        
        // Initialize shareURL to nil
        self.shareURL = nil
    }
    
    // MARK: - Body
    
    /// Builds the view's body with the tool detail UI
    /// - Returns: The composed view hierarchy
    var body: some View {
        ZStack {
            // Create a ZStack to layer the content
            
            // Add a background color using ColorConstants.background
            ColorConstants.background
                .edgesIgnoringSafeArea(.all)
            
            // If viewModel.isLoading is true, show LoadingView
            if viewModel.isLoading {
                LoadingView(message: "Cargando herramienta...")
            } else {
                // Otherwise, show the main content in a ScrollView
                ScrollView {
                    // Add a VStack containing the main content sections
                    VStack(alignment: .leading, spacing: 16) {
                        // Include a header section with tool name, category, and actions
                        headerView()
                        
                        // Include a media preview section if the tool has media content
                        if viewModel.tool?.hasMediaContent() == true {
                            mediaPreviewView()
                        }
                        
                        // Include a description section with the tool's description
                        descriptionView()
                        
                        // Include a metadata section with duration, difficulty, and target emotions
                        metadataView()
                        
                        // Include an instructions section with the tool's instructions
                        instructionsView()
                        
                        // Include a steps section if the tool has step-by-step instructions
                        if viewModel.tool?.hasSteps() == true {
                            stepsView()
                        }
                        
                        // Include a resources section if the tool has additional resources
                        if viewModel.tool?.hasAdditionalResources() == true {
                            resourcesView()
                        }
                        
                        // Include a start button at the bottom to begin using the tool
                        startButtonView()
                    }
                    .padding()
                }
            }
        }
        // Add navigation to ToolInProgressView when viewModel.navigateToToolInProgress is true
        .navigationBarHidden(true)
        .background(
            NavigationLink(
                destination: ToolInProgressView(viewModel: ToolInProgressViewModel(tool: viewModel.tool!)),
                isActive: $viewModel.navigateToToolInProgress,
                label: { EmptyView() }
            )
            .hidden()
        )
        // Add error alert when viewModel.showError is true
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.dismissError()
                })
            )
        }
        // Add confirmation dialog when viewModel.showConfirmation is true
        .confirmationDialog(
            viewModel.confirmationMessage,
            isPresented: $viewModel.showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Compartir", action: {
                viewModel.confirmAction()
            })
            Button("Cancelar", role: .cancel) {
                viewModel.dismissConfirmation()
            }
        }
        // Add share sheet when showShareSheet is true
        .sheet(isPresented: $showShareSheet) {
            if let shareURL = shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        // Add onAppear lifecycle hook to load the tool
        .onAppear {
            viewModel.loadTool()
        }
        // Add onDisappear lifecycle hook for cleanup
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    /// Creates the header section with tool name, category, and actions
    /// - Returns: The header view
    @ViewBuilder
    private func headerView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Create a VStack for the header content
            
            HStack {
                // Add an HStack with back button and favorite/share actions
                
                Button(action: {
                    // Configure back button to dismiss the view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(ColorConstants.textPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    // Configure favorite button to toggle favorite status
                    viewModel.toggleFavorite()
                }) {
                    Image(systemName: viewModel.tool?.isFavorite == true ? "heart.fill" : "heart")
                        .foregroundColor(ColorConstants.primary)
                }
                
                Button(action: {
                    // Configure share button to show share options
                    viewModel.shareToolLink()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(ColorConstants.primary)
                }
            }
            
            Text(viewModel.tool?.name ?? "Nombre de la herramienta")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            HStack {
                Image(systemName: viewModel.tool?.category.iconName() ?? "questionmark.circle")
                    .foregroundColor(viewModel.tool?.category.color() ?? ColorConstants.secondary)
                Text(viewModel.tool?.category.displayName() ?? "Categoría")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
            }
        }
    }
    
    /// Creates a media preview section for tools with audio or video content
    /// - Returns: The media preview view
    @ViewBuilder
    private func mediaPreviewView() -> some View {
        if let tool = viewModel.tool, tool.hasMediaContent() {
            VStack(alignment: .leading) {
                Text("Vista previa")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                    .padding(.bottom, 8)
                
                ZStack {
                    WaveformAnimation()
                        .frame(height: 100)
                    
                    Button(action: {
                        if viewModel.isPlaying {
                            viewModel.stopPreview()
                        } else {
                            viewModel.playPreview()
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                }
                .cardStyle()
            }
        }
    }
    
    /// Creates a view showing the tool's description
    /// - Returns: The description view
    @ViewBuilder
    private func descriptionView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acerca de")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text(viewModel.tool?.description ?? "Descripción no disponible")
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates a view showing the tool's metadata (duration, difficulty, target emotions)
    /// - Returns: The metadata view
    @ViewBuilder
    private func metadataView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(ColorConstants.textTertiary)
                Text("Duración: \(viewModel.tool?.formattedDuration() ?? "Desconocida")")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Spacer()
                
                Image(systemName: "gauge")
                    .foregroundColor(ColorConstants.textTertiary)
                Text("Dificultad: \(viewModel.tool?.difficulty.displayName() ?? "Desconocida")")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
            }
            
            HStack {
                Text("Emociones objetivo:")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textTertiary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.tool?.targetEmotions ?? [], id: \.self) { emotion in
                            emotionTag(emotion: emotion)
                        }
                    }
                }
            }
        }
    }
    
    /// Creates a view showing the tool's instructions
    /// - Returns: The instructions view
    @ViewBuilder
    private func instructionsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instrucciones")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text(viewModel.tool?.content.instructions ?? "Instrucciones no disponibles")
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
        }
        .cardStyle()
    }
    
    /// Creates a view showing step-by-step instructions if available
    /// - Returns: The steps view
    @ViewBuilder
    private func stepsView() -> some View {
        if let steps = viewModel.tool?.content.steps {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pasos")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                ForEach(steps) { step in
                    VStack(alignment: .leading) {
                        Text("Paso \(step.order): \(step.title)")
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.textPrimary)
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(ColorConstants.textSecondary)
                    }
                    .padding(.bottom, 8)
                }
            }
            .cardStyle()
        }
    }
    
    /// Creates a view showing additional resources if available
    /// - Returns: The resources view
    @ViewBuilder
    private func resourcesView() -> some View {
        if let resources = viewModel.tool?.content.additionalResources {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recursos adicionales")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                ForEach(resources) { resource in
                    VStack(alignment: .leading) {
                        Text(resource.title)
                            .font(.subheadline)
                            .foregroundColor(ColorConstants.textPrimary)
                        Text(resource.description)
                            .font(.body)
                            .foregroundColor(ColorConstants.textSecondary)
                    }
                    .padding(.bottom, 8)
                }
            }
            .cardStyle()
        }
    }
    
    /// Creates a view with the start button to begin using the tool
    /// - Returns: The start button view
    @ViewBuilder
    private func startButtonView() -> some View {
        VStack {
            PrimaryButton(title: "Comenzar", action: {
                viewModel.startTool()
            })
            .padding(.bottom)
        }
    }
    
    /// Creates a tag view for displaying a target emotion
    /// - Parameter emotion: The emotion to display
    /// - Returns: The emotion tag view
    @ViewBuilder
    private func emotionTag(emotion: EmotionType) -> some View {
        Text(emotion.displayName())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(EmotionColors.forEmotionType(emotionType: emotion))
            .foregroundColor(.white)
            .font(.caption)
            .cornerRadius(8)
    }
}

// A simple ShareSheet wrapper for sharing content
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    
    let items: [Any]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {
        // Nothing to do here
    }
}