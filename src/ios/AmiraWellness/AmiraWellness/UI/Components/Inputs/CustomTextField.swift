//
//  CustomTextField.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK
import Combine // iOS SDK

/// A customizable text field component that follows the app's design system
struct CustomTextField: View {
    // MARK: - Properties
    
    // Content properties
    let title: String
    @Binding var text: String
    let placeholder: String
    var errorMessage: String?
    
    // State properties
    var isDisabled: Bool
    var isFirstResponder: Bool
    var validator: ((String) -> Bool)?
    
    // Styling properties
    var font: Font
    var textColor: Color
    var backgroundColor: Color
    var showBorder: Bool
    var cornerRadius: CGFloat
    
    // Keyboard properties
    var keyboardType: UIKeyboardType
    var autocapitalizationType: UITextAutocapitalizationType
    var autocorrectionType: UITextAutocorrectionType
    var isMultiline: Bool
    var maxLength: Int?
    
    // Internal state
    @State private var isFocused: Bool = false
    
    // MARK: - Initializer
    
    /// Initializes a new CustomTextField with the specified parameters
    /// - Parameters:
    ///   - title: The label text to display above the text field
    ///   - text: Binding to the text value
    ///   - placeholder: The placeholder text to display when empty
    ///   - errorMessage: Optional error message to display below the text field
    ///   - isDisabled: Whether the text field is disabled
    ///   - isFirstResponder: Whether the text field should become first responder on appear
    ///   - validator: Optional function to validate the text input
    ///   - font: The font for the text input
    ///   - textColor: The color of the text
    ///   - backgroundColor: The background color of the text field
    ///   - showBorder: Whether to show a border around the text field
    ///   - cornerRadius: The corner radius of the text field
    ///   - keyboardType: The type of keyboard to display
    ///   - autocapitalizationType: The auto-capitalization style
    ///   - autocorrectionType: The auto-correction style
    ///   - isMultiline: Whether the text field allows multiple lines
    ///   - maxLength: Optional maximum character length
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        errorMessage: String? = nil,
        isDisabled: Bool = false,
        isFirstResponder: Bool = false,
        validator: ((String) -> Bool)? = nil,
        font: Font? = nil,
        textColor: Color? = nil,
        backgroundColor: Color? = nil,
        showBorder: Bool = true,
        cornerRadius: CGFloat = 8,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .sentences,
        autocorrectionType: UITextAutocorrectionType = .default,
        isMultiline: Bool = false,
        maxLength: Int? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.errorMessage = errorMessage
        self.isDisabled = isDisabled
        self.isFirstResponder = isFirstResponder
        self.validator = validator
        self.font = font ?? .body
        self.textColor = textColor ?? ColorConstants.textPrimary
        self.backgroundColor = backgroundColor ?? ColorConstants.background
        self.showBorder = showBorder
        self.cornerRadius = cornerRadius
        self.keyboardType = keyboardType
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType
        self.isMultiline = isMultiline
        self.maxLength = maxLength
    }
    
    // MARK: - Body
    
    /// Builds the text field view with all styling and functionality
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title label if provided
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(textColor)
                    .padding(.bottom, 2)
                    .accessibilityHidden(true) // Hide from VoiceOver since it's included in the field's label
            }
            
            // Text field implementation
            if isMultiline {
                // Multi-line implementation using TextEditor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(font)
                        .foregroundColor(textColor)
                        .autocapitalization(autocapitalizationType)
                        .disableAutocorrection(autocorrectionType == .no)
                        .disabled(isDisabled)
                        .modifier(TextFieldModifier(
                            font: font,
                            textColor: textColor,
                            backgroundColor: backgroundColor,
                            cornerRadius: cornerRadius,
                            showBorder: showBorder
                        ))
                        .onChange(of: text) { newValue in
                            enforceMaxLength()
                            _ = validate()
                        }
                    
                    // Placeholder for TextEditor when empty
                    if text.isEmpty {
                        Text(placeholder)
                            .font(font)
                            .foregroundColor(ColorConstants.textPrimary.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 100)
            } else {
                // Single-line implementation using TextField
                TextField(placeholder, text: $text, onCommit: {
                    onReturn()
                })
                .font(font)
                .foregroundColor(textColor)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalizationType)
                .disableAutocorrection(autocorrectionType == .no)
                .disabled(isDisabled)
                .modifier(TextFieldModifier(
                    font: font,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cornerRadius: cornerRadius,
                    showBorder: showBorder
                ))
                .onChange(of: text) { newValue in
                    enforceMaxLength()
                    _ = validate()
                }
            }
            
            // Error message if provided
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(ColorConstants.error)
                    .padding(.top, 2)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
        .onAppear {
            // Set focus if this field should be first responder
            if isFirstResponder {
                isFocused = true
                // Use a small delay to ensure the view is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This is a workaround for direct focus, which may need OS-specific handling
                    // In a real implementation, we'd use FocusState on iOS 15+
                }
            }
        }
        // Accessibility configuration
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.isEmpty ? placeholder : "\(title), \(placeholder)")
        .accessibilityValue(text)
        .accessibilityHint(errorMessage ?? "")
    }
    
    // MARK: - Helper Methods
    
    /// Validates the current text input using the provided validator
    func validate() -> Bool {
        guard let validator = validator else {
            return true // No validator means always valid
        }
        return validator(text)
    }
    
    /// Enforces the maximum character length on the text if specified
    func enforceMaxLength() {
        if let maxLength = maxLength, text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
    }
    
    /// Handles the return key press on the keyboard
    func onReturn() {
        hideKeyboard()
        isFocused = false
    }
}