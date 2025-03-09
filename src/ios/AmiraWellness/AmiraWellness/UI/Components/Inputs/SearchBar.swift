//
//  SearchBar.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import SwiftUI // iOS SDK
import Combine // iOS SDK

/// A reusable search bar component that provides a consistent search experience
/// throughout the Amira Wellness app, following the app's minimalist, nature-inspired design.
struct SearchBar: View {
    // MARK: - Properties
    
    /// Binding to the search text value
    @Binding private var text: String
    
    /// Placeholder text shown when the search field is empty
    private let placeholder: String
    
    /// Binding to track whether the search field is focused
    @Binding private var isFocused: Bool
    
    /// Background color of the search bar
    private let backgroundColor: Color
    
    /// Text color for the search input
    private let textColor: Color
    
    /// Color for the placeholder text
    private let placeholderColor: Color
    
    /// Color for the icons (search and clear)
    private let iconColor: Color
    
    /// Height of the search bar
    private let height: CGFloat
    
    /// Corner radius of the search bar
    private let cornerRadius: CGFloat
    
    /// Whether to show a shadow under the search bar
    private let hasShadow: Bool
    
    /// Time interval to debounce search text changes
    private let debounceTime: TimeInterval
    
    /// Closure called when the search is submitted
    private let onSubmit: (() -> Void)?
    
    /// Closure called when the search text changes (after debounce)
    private let onTextChange: ((String) -> Void)?
    
    // MARK: - Publishers
    
    /// Publisher for debouncing search text changes
    private let searchTextPublisher = PassthroughSubject<String, Never>()
    
    /// Subscription for the debounced search text
    private var searchTextSubscription: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Initializes a new SearchBar with the specified parameters
    /// - Parameters:
    ///   - text: Binding to the search text
    ///   - placeholder: Placeholder text to display when empty (defaults to "Search")
    ///   - isFocused: Binding to track focus state (defaults to constant false)
    ///   - backgroundColor: Background color of the search bar (defaults to background color)
    ///   - textColor: Color of the input text (defaults to textPrimary)
    ///   - placeholderColor: Color of the placeholder text (defaults to semi-transparent textPrimary)
    ///   - iconColor: Color of the search and clear icons (defaults to textPrimary)
    ///   - height: Height of the search bar (defaults to 44)
    ///   - cornerRadius: Corner radius of the search bar (defaults to 8)
    ///   - hasShadow: Whether to show a shadow (defaults to false)
    ///   - debounceTime: Time interval to debounce text changes (defaults to 0.5 seconds)
    ///   - onSubmit: Closure called when search is submitted (defaults to nil)
    ///   - onTextChange: Closure called when text changes after debounce (defaults to nil)
    init(
        text: Binding<String>,
        placeholder: String = "Search",
        isFocused: Binding<Bool> = .constant(false),
        backgroundColor: Color = ColorConstants.background,
        textColor: Color = ColorConstants.textPrimary,
        placeholderColor: Color = ColorConstants.textPrimary.opacity(0.6),
        iconColor: Color = ColorConstants.textPrimary,
        height: CGFloat = 44,
        cornerRadius: CGFloat = 8,
        hasShadow: Bool = false,
        debounceTime: TimeInterval = 0.5,
        onSubmit: (() -> Void)? = nil,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self._isFocused = isFocused
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.iconColor = iconColor
        self.height = height
        self.cornerRadius = cornerRadius
        self.hasShadow = hasShadow
        self.debounceTime = debounceTime
        self.onSubmit = onSubmit
        self.onTextChange = onTextChange
        
        // Set up the debounced text change publisher
        self.searchTextSubscription = searchTextPublisher
            .debounce(for: .seconds(debounceTime), scheduler: RunLoop.main)
            .sink { [onTextChange] debouncedText in
                onTextChange?(debouncedText)
            }
    }
    
    // MARK: - Body
    
    /// The content and behavior of the search bar
    var body: some View {
        HStack(spacing: 8) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
                .padding(.leading, 8)
            
            // Search text field
            TextField(placeholder, text: $text, onEditingChanged: { isEditing in
                self.isFocused = isEditing
            })
            .foregroundColor(textColor)
            .font(.system(size: 16))
            .accentColor(ColorConstants.primary)
            .onChange(of: text) { newValue in
                searchTextPublisher.send(newValue)
            }
            .accessibilityLabel(placeholder)
            
            // Clear button
            if !text.isEmpty {
                IconButton(
                    systemName: "xmark.circle.fill",
                    label: "Clear search",
                    iconColor: iconColor.opacity(0.7),
                    backgroundColor: .clear,
                    size: 24,
                    iconSize: 16,
                    feedbackType: .light
                ) {
                    clearText()
                }
                .padding(.trailing, 8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: !text.isEmpty)
            }
        }
        .frame(height: height)
        .padding(.horizontal, 4)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(ColorConstants.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: hasShadow ? 4 : 0,
            x: 0,
            y: hasShadow ? 2 : 0
        )
        .onSubmit {
            onSubmit?()
        }
        .accessibilityHint("Enter text to search")
    }
    
    /// Clears the search text and provides haptic feedback
    func clearText() {
        text = ""
        HapticManager.shared.generateFeedback(.light)
        onTextChange?("")
    }
}

#if DEBUG
// MARK: - Preview
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default search bar
            SearchBar(
                text: .constant("")
            )
            
            // Search bar with text
            SearchBar(
                text: .constant("Nature"),
                placeholder: "Search for tools..."
            )
            
            // Customized search bar
            SearchBar(
                text: .constant("Meditation"),
                placeholder: "Find a tool",
                backgroundColor: ColorConstants.surface,
                iconColor: ColorConstants.primary,
                height: 50,
                cornerRadius: 25,
                hasShadow: true
            )
            
            // Dark theme search bar
            SearchBar(
                text: .constant(""),
                placeholder: "Search tools...",
                backgroundColor: Color.black.opacity(0.8),
                textColor: .white,
                placeholderColor: .white.opacity(0.6),
                iconColor: .white
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif