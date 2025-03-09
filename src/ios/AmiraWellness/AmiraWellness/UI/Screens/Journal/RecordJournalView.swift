# <file_path>
```swift
import SwiftUI // iOS SDK
import Combine // iOS SDK

// Internal imports
import RecordJournalViewModel // ./RecordJournalViewModel
import RecordJournalViewState // ./RecordJournalViewModel
import EmotionType // ../../../Models/EmotionalState
import WaveformAnimation // ../../Components/Animation/WaveformAnimation
import EmotionSelector // ../../Components/Inputs/EmotionSelector
import IntensitySlider // ../../Components/Inputs/IntensitySlider
import CustomTextField // ../../Components/Inputs/CustomTextField
import PrimaryButton // ../../Components/Buttons/PrimaryButton
import IconButton // ../../Components/Buttons/IconButton
import LoadingView // ../../Components/Loading/LoadingView
import SuccessView // ../../Components/Feedback/SuccessView
import ErrorView // ../../Components/Feedback/ErrorView
import ColorConstants // ../../../Core/Constants/ColorConstants

/// A SwiftUI view that implements the voice journaling feature with emotional check-ins
struct RecordJournalView: View {
    // MARK: - Properties

    /// The view model that manages the state and logic for this view
    @StateObject var viewModel: RecordJournalViewModel

    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode

    /// State variable to control the visibility of the cancel confirmation dialog
    @State private var showCancelConfirmation: Bool = false

    // MARK: - Initializer

    /// Initializes the RecordJournalView with an optional view model
    /// - Parameter viewModel: An optional RecordJournalViewModel instance
    init(viewModel: RecordJournalViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? RecordJournalViewModel())
        self._showCancelConfirmation = State(initialValue: false)
    }

    // MARK: - Body

    /// Builds the main view hierarchy based on the current view state
    var body: some View {
        ZStack {
            // Background color
            ColorConstants.background.ignoresSafeArea()

            VStack {
                // Navigation bar with back button and title
                NavigationBarView(title: "Diario de Voz", showBackButton: true, action: {
                    handleCancel()
                })

                // Content based on view state
                switch viewModel.viewState {
                case .preCheckIn:
                    PreRecordingView()
                case .recording:
                    RecordingView()
                case .postCheckIn:
                    PostRecordingView()
                case .saving:
                    LoadingView(message: "Guardando diario...")
                case .completed:
                    CompletionView()
                case .error:
                    ErrorView(message: viewModel.errorMessage ?? "Ocurrió un error inesperado.")
                }
            }
            .padding()
        }
        .confirmationDialog(
            "¿Estás seguro de que quieres cancelar la grabación?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancelar grabación", role: .destructive) {
                confirmCancel()
            }
            Button("Continuar grabando", role: .cancel) {
                showCancelConfirmation = false
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    /// Builds the view for the pre-recording emotional check-in
    @ViewBuilder
    private func PreRecordingView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Check-in emocional")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorConstants.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("¿Cómo te sientes antes de grabar?")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textSecondary)

                EmotionSelector(selectedEmotion: $viewModel.selectedEmotionType)

                Text("Intensidad:")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)

                IntensitySlider(value: $viewModel.emotionIntensity)

                CustomTextField(
                    title: "Notas (opcional):",
                    text: $viewModel.notes,
                    placeholder: "Añade detalles sobre tu estado emocional",
                    isMultiline: true
                )

                PrimaryButton(
                    title: "Comenzar a grabar",
                    isEnabled: viewModel.selectedEmotionType != nil
                ) {
                    viewModel.submitPreRecordingEmotionalState()
                }
            }
            .padding(.vertical)
        }
    }

    /// Builds the view for the audio recording process
    @ViewBuilder
    private func RecordingView() -> some View {
        VStack(spacing: 20) {
            Text("Diario de voz")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityAddTraits(.isHeader)

            WaveformAnimation()
                .frame(height: 100)

            Text(viewModel.formatDuration())
                .font(.title3)
                .foregroundColor(ColorConstants.textSecondary)

            HStack {
                IconButton(
                    systemName: viewModel.isPaused ? "record.circle" : "pause.circle",
                    label: viewModel.isPaused ? "Resume Recording" : "Pause Recording",
                    action: {
                        viewModel.toggleRecording()
                    }
                )

                IconButton(
                    systemName: "stop.circle",
                    label: "Stop Recording",
                    action: {
                        viewModel.stopRecording()
                    }
                )

                IconButton(
                    systemName: "xmark.circle",
                    label: "Cancel Recording",
                    action: {
                        handleCancel()
                    }
                )
            }

            Text("Consejos:")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("""
                 - Habla libremente sobre tus emociones
                 - No hay respuestas correctas o incorrectas
                 - Este es tu espacio seguro
                 """)
                .font(.callout)
                .foregroundColor(ColorConstants.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Builds the view for the post-recording emotional check-in
    @ViewBuilder
    private func PostRecordingView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Check-in emocional")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorConstants.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("¿Cómo te sientes después de grabar?")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textSecondary)

                EmotionSelector(selectedEmotion: $viewModel.selectedEmotionType)

                Text("Intensidad:")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)

                IntensitySlider(value: $viewModel.emotionIntensity)

                CustomTextField(
                    title: "Notas (opcional):",
                    text: $viewModel.notes,
                    placeholder: "Añade detalles sobre tu estado emocional",
                    isMultiline: true
                )

                CustomTextField(
                    title: "Título del diario:",
                    text: $viewModel.journalTitle,
                    placeholder: "Añade un título a tu diario",
                    maxLength: 50
                )

                PrimaryButton(
                    title: "Guardar diario",
                    isEnabled: viewModel.selectedEmotionType != nil && !viewModel.journalTitle.isEmpty
                ) {
                    viewModel.submitPostRecordingEmotionalState()
                }
            }
            .padding(.vertical)
        }
    }

    /// Builds the view for the successful completion state
    @ViewBuilder
    private func CompletionView() -> some View {
        SuccessView(
            title: "¡Grabación guardada!",
            message: viewModel.getEmotionalShiftSummary() ?? "Diario guardado exitosamente.",
            buttonTitle: "Volver al inicio"
        ) {
            viewModel.resetViewModel()
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Helper Functions

    /// Handles the cancel action with confirmation
    private func handleCancel() {
        if viewModel.isRecording {
            showCancelConfirmation = true
        } else {
            confirmCancel()
        }
    }

    /// Confirms cancellation after user confirmation
    private func confirmCancel() {
        viewModel.cancelRecording()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - NavigationBarView

struct NavigationBarView: View {
    let title: String
    let showBackButton: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            if showBackButton {
                Button(action: action) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(ColorConstants.primary)
                }
            }

            Spacer()

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)

            Spacer()

            if showBackButton {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.bottom, 10)
    }
}