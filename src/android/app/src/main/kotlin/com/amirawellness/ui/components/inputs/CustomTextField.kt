package com.amirawellness.ui.components.inputs

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.MaterialTheme
import androidx.compose.material.OutlinedTextField
import androidx.compose.material.Text
import androidx.compose.material.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.amirawellness.ui.theme.Border
import com.amirawellness.ui.theme.Error
import com.amirawellness.ui.theme.InputFieldShape
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary

/**
 * A custom text field component that follows Amira Wellness design guidelines.
 * Features a nature-inspired design with rounded corners and appropriate colors
 * for different states (normal, focused, error).
 * 
 * @param value The input text to be shown in the text field
 * @param onValueChange The callback that is triggered when the input service updates the text
 * @param label The label to be displayed inside or above the text field
 * @param modifier Modifier to be applied to the text field
 * @param isError Indicates if the text field is in error state
 * @param errorMessage The error message to display if isError is true
 * @param enabled Controls the enabled state of the text field
 * @param readOnly Controls if the text field is editable
 * @param keyboardOptions Software keyboard options that contain configuration such as KeyboardType and ImeAction
 * @param keyboardActions The actions to perform when keyboard action buttons are pressed
 * @param visualTransformation Transforms the visual representation of the input value
 * @param leadingIcon The leading icon to be displayed at the beginning of the text field
 * @param trailingIcon The trailing icon to be displayed at the end of the text field
 * @param maxLines The maximum number of visible lines
 * @param singleLine When set to true, this text field becomes a single horizontally scrolling text field
 */
@Composable
fun CustomTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String = "",
    enabled: Boolean = true,
    readOnly: Boolean = false,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    maxLines: Int = Int.MAX_VALUE,
    singleLine: Boolean = false
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(text = label) },
            modifier = Modifier.fillMaxWidth(),
            isError = isError,
            enabled = enabled,
            readOnly = readOnly,
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            visualTransformation = visualTransformation,
            leadingIcon = leadingIcon,
            trailingIcon = trailingIcon,
            maxLines = maxLines,
            singleLine = singleLine,
            colors = TextFieldDefaults.outlinedTextFieldColors(
                textColor = TextPrimary,
                backgroundColor = Surface,
                focusedBorderColor = Primary,
                unfocusedBorderColor = Border,
                focusedLabelColor = Primary,
                unfocusedLabelColor = TextSecondary,
                errorBorderColor = Error,
                errorLabelColor = Error,
                cursorColor = Primary
            ),
            shape = InputFieldShape
        )
        
        if (isError && errorMessage.isNotEmpty()) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = errorMessage,
                color = Error,
                style = MaterialTheme.typography.caption,
                modifier = Modifier.padding(start = 4.dp)
            )
        }
    }
}

/**
 * A variant of CustomTextField that accepts TextFieldValue instead of String,
 * providing more control over text selection and composition.
 * 
 * @param value The input TextFieldValue to be shown in the text field
 * @param onValueChange The callback that is triggered when the input service updates the text value
 * @param label The label to be displayed inside or above the text field
 * @param modifier Modifier to be applied to the text field
 * @param isError Indicates if the text field is in error state
 * @param errorMessage The error message to display if isError is true
 * @param enabled Controls the enabled state of the text field
 * @param readOnly Controls if the text field is editable
 * @param keyboardOptions Software keyboard options that contain configuration such as KeyboardType and ImeAction
 * @param keyboardActions The actions to perform when keyboard action buttons are pressed
 * @param visualTransformation Transforms the visual representation of the input value
 * @param leadingIcon The leading icon to be displayed at the beginning of the text field
 * @param trailingIcon The trailing icon to be displayed at the end of the text field
 * @param maxLines The maximum number of visible lines
 * @param singleLine When set to true, this text field becomes a single horizontally scrolling text field
 */
@Composable
fun CustomTextFieldWithValue(
    value: TextFieldValue,
    onValueChange: (TextFieldValue) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String = "",
    enabled: Boolean = true,
    readOnly: Boolean = false,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    maxLines: Int = Int.MAX_VALUE,
    singleLine: Boolean = false
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(text = label) },
            modifier = Modifier.fillMaxWidth(),
            isError = isError,
            enabled = enabled,
            readOnly = readOnly,
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            visualTransformation = visualTransformation,
            leadingIcon = leadingIcon,
            trailingIcon = trailingIcon,
            maxLines = maxLines,
            singleLine = singleLine,
            colors = TextFieldDefaults.outlinedTextFieldColors(
                textColor = TextPrimary,
                backgroundColor = Surface,
                focusedBorderColor = Primary,
                unfocusedBorderColor = Border,
                focusedLabelColor = Primary,
                unfocusedLabelColor = TextSecondary,
                errorBorderColor = Error,
                errorLabelColor = Error,
                cursorColor = Primary
            ),
            shape = InputFieldShape
        )
        
        if (isError && errorMessage.isNotEmpty()) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = errorMessage,
                color = Error,
                style = MaterialTheme.typography.caption,
                modifier = Modifier.padding(start = 4.dp)
            )
        }
    }
}