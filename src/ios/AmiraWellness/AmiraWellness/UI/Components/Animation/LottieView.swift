import SwiftUI
import Lottie // Version ~> 4.3.3

struct LottieView: UIViewRepresentable {
    // MARK: - Properties
    private let animationName: String
    private let loopMode: Bool
    private let speed: CGFloat
    private let tintColor: Color?
    private let contentMode: ContentMode
    @Binding private var isPlaying: Bool
    
    // MARK: - Initializer
    init(
        animationName: String,
        loopMode: Bool = true,
        speed: CGFloat = 1.0,
        tintColor: Color? = nil,
        contentMode: ContentMode = .fit,
        isPlaying: Binding<Bool> = .constant(true)
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.speed = speed
        self.tintColor = tintColor
        self.contentMode = contentMode
        self._isPlaying = isPlaying
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> LottieAnimationView {
        // Create and configure the Lottie animation view
        let animationView = LottieAnimationView()
        
        // Load animation from the bundle
        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
            
            // Configure loop mode
            animationView.loopMode = loopMode ? .loop : .playOnce
            
            // Set animation speed
            animationView.animationSpeed = speed
            
            // Set content mode based on SwiftUI ContentMode
            switch contentMode {
            case .fill:
                animationView.contentMode = .scaleToFill
            case .fit:
                animationView.contentMode = .scaleAspectFit
            @unknown default:
                animationView.contentMode = .scaleAspectFit
            }
            
            // Apply tint color if provided
            if let tintColor = tintColor {
                let colorProvider = ColorValueProvider(UIColor(tintColor).lottieColorValue)
                let keypath = AnimationKeypath(keys: ["**", "Fill", "**", "Color"])
                animationView.setValueProvider(colorProvider, keypath: keypath)
            }
            
            // Set accessibility properties
            animationView.accessibilityLabel = "Animation: \(animationName)"
            animationView.isAccessibilityElement = true
            
            // Play animation if isPlaying is true
            if isPlaying {
                animationView.play()
            }
        }
        
        // Store reference to animation view in coordinator
        context.coordinator.animationView = animationView
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: UIViewRepresentableContext<LottieView>) {
        // Handle play/pause based on isPlaying binding
        if isPlaying && !uiView.isAnimationPlaying {
            uiView.play()
        } else if !isPlaying && uiView.isAnimationPlaying {
            uiView.pause()
        }
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: LottieView
        var animationView: LottieAnimationView?
        
        init(_ parent: LottieView) {
            self.parent = parent
        }
    }
    
    // MARK: - Animation Control Methods
    
    /// Starts or resumes the animation
    func play() {
        isPlaying = true
    }
    
    /// Pauses the animation
    func pause() {
        isPlaying = false
    }
    
    /// Stops the animation and resets to the beginning
    func stop() {
        isPlaying = false
        // Note: This method only pauses the animation.
        // The animation will be reset to the beginning the next time play() is called.
    }
}