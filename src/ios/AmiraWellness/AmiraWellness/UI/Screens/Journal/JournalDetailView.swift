import SwiftUI // iOS SDK
import Combine // iOS SDK
import Foundation // iOS SDK

// Internal Imports
import struct AmiraWellness.Journal // src/ios/AmiraWellness/AmiraWellness/Models/Journal.swift
import struct AmiraWellness.EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import struct AmiraWellness.EmotionalShift // src/ios/AmiraWellness/AmiraWellness/Models/Journal.swift
import enum AmiraWellness.PlaybackState // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioPlaybackService.swift
import class AmiraWellness.JournalDetailViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Journal/JournalDetailViewModel.swift
import struct AmiraWellness.WaveformAnimation // src/ios/AmiraWellness/AmiraWellness/UI/Components/Animation/WaveformAnimation.swift
import struct AmiraWellness.PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import struct AmiraWellness.IconButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/IconButton.swift
import struct AmiraWellness.LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import struct AmiraWellness.ErrorView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/ErrorView.swift
import struct AmiraWellness.ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import struct AmiraWellness.EmotionColors // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// A SwiftUI view that displays detailed information about a voice journal entry, including playback controls, emotional shift visualization, and journal management options.
/// This screen allows users to play, pause, and control their voice journal recordings while visualizing the emotional shift that occurred during the journaling session.
struct JournalDetailView: View {
    
    /// Observed object for managing the journal detail view's state and business logic.
    @ObservedObject var viewModel: JournalDetailViewModel
    
    /// Environment variable for controlling the presentation mode (e.g., dismissing the view).
    @Environment(\.presentationMode) var presentationMode
    
    /// State variable to control the presentation of the share sheet for exporting the journal.
    @State private var isShareSheetPresented: Bool = false
    
    /// Initializes a new JournalDetailView with a journal ID.
    /// - Parameter journalId: The UUID of the journal entry to display.
    init(journalId: UUID) {
        self.viewModel = JournalDetailViewModel(journalId: journalId)
        self._isShareSheetPresented = State(initialValue: false)
    }
    
    /// Builds the view hierarchy for the journal detail screen.
    /// - Returns: The composed view hierarchy.
    var body: some View {
        ZStack {
            ColorConstants.background.ignoresSafeArea()
            
            VStack {
                if viewModel.isLoading {
                    LoadingView(message: "Cargando diario...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.preparePlayback()
                    }
                } else if let journal = viewModel.journal {
                    journalContent()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    IconButton(systemName: "chevron.backward", action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.journal?.title ?? "Diario de voz")
                        .font(.headline)
                }
            }
            .confirmationDialog(
                "¿Estás seguro de que quieres eliminar este diario?",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    viewModel.confirmDelete()
                }
                Button("Cancelar", role: .cancel) {
                    viewModel.cancelDelete()
                }
            }
            .alert(isPresented: $viewModel.showExportPasswordPrompt) {
                Alert(
                    title: Text("Proteger exportación"),
                    message: Text("Introduce una contraseña para proteger el archivo exportado."),
                    textField: { (textField) in
                        textField.placeholder = "Contraseña"
                        textField.isSecure = true
                    },
                    primaryButton: .default(Text("Exportar"), action: {
                        viewModel.confirmExport()
                    }),
                    secondaryButton: .cancel(Text("Cancelar"), action: {
                        viewModel.cancelExport()
                    })
                )
            }
            .sheet(isPresented: $isShareSheetPresented, onDismiss: {
                viewModel.clearExportURL()
            }, content: {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                } else {
                    Text("No se pudo exportar el diario.")
                }
            })
        }
    }
    
    /// Creates the main content view for the journal details.
    /// - Returns: The journal content view.
    @ViewBuilder
    private func journalContent() -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                journalHeaderView()
                playbackControlsView()
                emotionalShiftView()
                insightsView()
                actionButtonsView()
            }
            .padding()
        }
    }
    
    /// Creates the header section with journal title and metadata.
    /// - Returns: The journal header view.
    @ViewBuilder
    private func journalHeaderView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.journal?.title ?? "Sin título")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                Text(viewModel.journal?.formattedDate() ?? "Fecha desconocida")
                Spacer()
                Text(viewModel.journal?.formattedDuration() ?? "Duración desconocida")
                
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: (viewModel.journal?.isFavorite ?? false) ? "heart.fill" : "heart")
                        .foregroundColor(ColorConstants.secondary)
                }
            }
            .font(.subheadline)
            .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates the audio playback controls section.
    /// - Returns: The playback controls view.
    @ViewBuilder
    private func playbackControlsView() -> some View {
        VStack(spacing: 16) {
            WaveformAnimation()
                .frame(height: 50)
            
            Slider(
                value: $viewModel.playbackProgress,
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing {
                        viewModel.seekTo(position: viewModel.duration * viewModel.playbackProgress)
                    }
                }
            )
            
            HStack {
                Text(viewModel.formatTimeInterval(interval: viewModel.currentPosition))
                Spacer()
                Text(viewModel.formatTimeInterval(interval: viewModel.duration))
            }
            .font(.caption)
            .foregroundColor(ColorConstants.textSecondary)
            
            HStack {
                Spacer()
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(ColorConstants.primary)
                }
                Spacer()
            }
        }
    }
    
    /// Creates a view displaying the emotional shift between pre and post recording.
    /// - Returns: The emotional shift view.
    @ViewBuilder
    private func emotionalShiftView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cambio Emocional")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            if let emotionalShift = viewModel.emotionalShift {
                HStack {
                    VStack {
                        Text("Antes")
                            .font(.headline)
                        Text(emotionalShift.preEmotionalState.emotionType.displayName())
                            .foregroundColor(EmotionColors.forEmotionType(emotionType: emotionalShift.preEmotionalState.emotionType))
                        Text("Intensidad: \(emotionalShift.preEmotionalState.intensity)")
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title)
                    
                    VStack {
                        Text("Después")
                            .font(.headline)
                        Text(emotionalShift.postEmotionalState.emotionType.displayName())
                            .foregroundColor(EmotionColors.forEmotionType(emotionType: emotionalShift.postEmotionalState.emotionType))
                        Text("Intensidad: \(emotionalShift.postEmotionalState.intensity)")
                    }
                }
                
                Text(viewModel.getEmotionalShiftDescription())
                    .font(.body)
                    .foregroundColor(ColorConstants.textSecondary)
            } else {
                Text("No hay datos de cambio emocional disponibles.")
                    .foregroundColor(ColorConstants.textSecondary)
            }
        }
        .padding()
        .cardStyle()
    }
    
    /// Creates a view displaying insights derived from the emotional shift.
    /// - Returns: The insights view.
    @ViewBuilder
    private func insightsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            if let emotionalShift = viewModel.emotionalShift {
                ForEach(emotionalShift.insights, id: \.self) { insight in
                    Text(insight)
                        .font(.body)
                        .foregroundColor(ColorConstants.textSecondary)
                        .padding(.vertical, 4)
                }
            } else {
                Text("No hay insights disponibles.")
                    .foregroundColor(ColorConstants.textSecondary)
            }
        }
        .padding()
        .cardStyle()
    }
    
    /// Creates a view with action buttons for journal management.
    /// - Returns: The action buttons view.
    @ViewBuilder
    private func actionButtonsView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button("Exportar") {
                    viewModel.exportJournal()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteJournal()
                }
                Spacer()
            }
        }
    }
    
    /// Creates a confirmation dialog for journal deletion.
    /// - Returns: The confirmation dialog.
    @ViewBuilder
    private func deleteConfirmationDialog() -> some View {
        EmptyView()
    }
    
    /// Creates a dialog for entering export password.
    /// - Returns: The export password dialog.
    @ViewBuilder
    private func exportPasswordPrompt() -> some View {
        EmptyView()
    }
    
    /// Creates a share sheet for exporting the journal.
    /// - Returns: The share sheet.
    @ViewBuilder
    private func shareSheet() -> some View {
        EmptyView()
    }
}

/// A structure to present the share sheet
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    
    var items: [Any]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {
        // Nothing to do
    }
}