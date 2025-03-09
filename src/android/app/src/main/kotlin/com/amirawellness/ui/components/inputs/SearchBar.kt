package com.amirawellness.ui.components.inputs

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.material.OutlinedTextField // version: 1.5.0
import androidx.compose.material.TextFieldDefaults // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.text.KeyboardOptions // version: 1.5.0
import androidx.compose.foundation.text.KeyboardActions // version: 1.5.0
import androidx.compose.ui.text.input.ImeAction // version: 1.5.0
import androidx.compose.ui.text.input.KeyboardType // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.Search // version: 1.5.0
import androidx.compose.material.icons.filled.Clear // version: 1.5.0

import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Border
import com.amirawellness.ui.theme.InputFieldShape

/**
 * A reusable search bar component that follows Amira Wellness design language.
 * 
 * The search bar features a minimalist design with a search icon, text input,
 * and a clear button that appears when text is entered. It adheres to the 
 * application's nature-inspired design approach with rounded corners and
 * calming colors.
 *
 * @param query The current search query text
 * @param onQueryChange Callback invoked when search text changes
 * @param placeholder Hint text displayed when the search field is empty
 * @param modifier Optional Modifier for customizing layout
 * @param enabled Whether the search bar is interactive
 * @param keyboardOptions Options controlling keyboard behavior
 * @param keyboardActions Actions to perform based on keyboard input
 */
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    placeholder: String = "Buscar",
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions(
        keyboardType = KeyboardType.Text,
        imeAction = ImeAction.Search
    ),
    keyboardActions: KeyboardActions = KeyboardActions()
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = {
            Text(
                text = placeholder,
                color = TextSecondary,
                style = MaterialTheme.typography.body1
            )
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.Filled.Search,
                contentDescription = "Search Icon",
                tint = TextSecondary
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(
                    onClick = { onQueryChange("") }
                ) {
                    Icon(
                        imageVector = Icons.Filled.Clear,
                        contentDescription = "Clear Search",
                        tint = TextSecondary
                    )
                }
            }
        },
        singleLine = true,
        colors = TextFieldDefaults.outlinedTextFieldColors(
            textColor = TextPrimary,
            backgroundColor = Surface,
            cursorColor = Primary,
            focusedBorderColor = Primary,
            unfocusedBorderColor = Border
        ),
        shape = InputFieldShape,
        modifier = modifier.fillMaxWidth(),
        enabled = enabled,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions
    )
}