//
//  SecureField.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // SwiftUI - iOS SDK
import Combine // Combine - iOS SDK

/// A customizable secure text field component that implements the Amira Wellness app's design system,
/// providing a consistent, accessible password input experience with validation, styling, and security features.
struct SecureField: View {
    // MARK: - Properties
    
    /// The title label for the text field
    let title: String
    
    /// The binding to the text value
    @Binding var text: String
    
    /// The placeholder text to display when the field is empty
    let placeholder: String
    
    /// The error message to display (if any)
    let errorMessage: String?
    
    /// Whether the text field is disabled
    let isDisabled: Bool
    
    /// Whether the text field should be the first responder
    let isFirstResponder: Bool
    
    /// Optional validator function to check text validity
    let validator: ((String) -> Bool)?
    
    /// The font for the text field
    let font: Font
    
    /// The text color for the text field
    let textColor: Color
    
    /// The background color for the text field
    let backgroundColor: Color
    
    /// Whether to show a border around the text field
    let showBorder: Bool
    
    /// The corner radius for the text field
    let cornerRadius: CGFloat
    
    /// The autocapitalization type for the text field
    let autocapitalizationType: UITextAutocapitalizationType
    
    /// The autocorrection type for the text field
    let autocorrectionType: UITextAutocorrectionType
    
    /// The maximum allowed length for the text (if any)
    let maxLength: Int?
    
    /// Whether the text field is currently focused
    @State private var isFocused: Bool = false
    
    /// Whether the password is currently visible
    @State private var isPasswordVisible: Bool = false
    
    // MARK: - Initializer
    
    /// Initializes a new SecureField with the specified parameters
    /// - Parameters:
    ///   - title: The title label for the text field
    ///   - text: The binding to the text value
    ///   - placeholder: The placeholder text to display when the field is empty
    ///   - errorMessage: The error message to display (if any)
    ///   - isDisabled: Whether the text field is disabled
    ///   - isFirstResponder: Whether the text field should be the first responder
    ///   - validator: Optional validator function to check text validity
    ///   - font: The font for the text field
    ///   - textColor: The text color for the text field
    ///   - backgroundColor: The background color for the text field
    ///   - showBorder: Whether to show a border around the text field
    ///   - cornerRadius: The corner radius for the text field
    ///   - autocapitalizationType: The autocapitalization type for the text field
    ///   - autocorrectionType: The autocorrection type for the text field
    ///   - maxLength: The maximum allowed length for the text (if any)
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
        autocapitalizationType: UITextAutocapitalizationType = .none,
        autocorrectionType: UITextAutocorrectionType = .no,
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
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType
        self.maxLength = maxLength
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title label if provided
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textPrimary)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true) // Hide for accessibility since it's included in the field's label
            }
            
            // Password field with visibility toggle
            ZStack(alignment: .trailing) {
                Group {
                    if isPasswordVisible {
                        // Regular text field when password is visible
                        TextField(placeholder, text: $text, onCommit: onReturn)
                            .keyboardType(.default)
                            .textContentType(.password) // Suggests password autofill but doesn't enforce it
                    } else {
                        // Secure text field when password is hidden
                        SwiftUI.SecureField(placeholder, text: $text, onCommit: onReturn)
                            .textContentType(.password)
                    }
                }
                .modifier(TextFieldModifier(
                    font: font,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    borderColor: errorMessage != nil ? ColorConstants.error : nil,
                    showBorder: showBorder,
                    cornerRadius: cornerRadius
                ))
                .autocapitalization(autocapitalizationType)
                .disableAutocorrection(autocorrectionType == .no)
                .disabled(isDisabled)
                .onChange(of: text) { _ in 
                    enforceMaxLength()
                }
                
                // Visibility toggle button
                Button(action: togglePasswordVisibility) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(ColorConstants.primary)
                        .padding(.trailing, 12)
                        .frame(width: 44, height: 44) // Minimum tap target size for accessibility
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }
            
            // Error message if any
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(ColorConstants.error)
                    .padding(.top, 4)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(errorMessage != nil ? "Error: \(errorMessage!)" : "")")
    }
    
    // MARK: - Helper Methods
    
    /// Validates the current text input using the provided validator function
    /// - Returns: Whether the current text passes validation
    func validate() -> Bool {
        guard let validator = validator else {
            return true
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
    
    /// Toggles the visibility of the password text
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
}