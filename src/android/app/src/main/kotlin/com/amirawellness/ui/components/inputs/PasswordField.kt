package com.amirawellness.ui.components.inputs

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.amirawellness.ui.theme.Error
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Success
import com.amirawellness.ui.theme.Warning

/**
 * A composable function that renders a password input field with visibility toggle 
 * and optional strength indicator.
 *
 * @param value The current password text
 * @param onValueChange Callback when password text changes
 * @param label Label for the password field
 * @param modifier Optional modifier for customizing the layout
 * @param isError Whether the input is in an error state
 * @param errorMessage Error message to display when isError is true
 * @param enabled Whether the input field is enabled
 * @param showStrengthIndicator Whether to show password strength indicator
 * @param keyboardOptions Keyboard options to use (defaults to password keyboard)
 * @param keyboardActions Actions to perform for keyboard events
 * @param maxLines Maximum number of lines to display
 * @param singleLine Whether the input field is single line
 */
@Composable
fun PasswordField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorMessage: String = "",
    enabled: Boolean = true,
    showStrengthIndicator: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions(
        keyboardType = KeyboardType.Password,
        imeAction = ImeAction.Done
    ),
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    maxLines: Int = 1,
    singleLine: Boolean = true
) {
    var passwordVisible by remember { mutableStateOf(false) }
    
    Column(
        modifier = modifier
    ) {
        CustomTextField(
            value = value,
            onValueChange = onValueChange,
            label = label,
            isError = isError,
            errorMessage = errorMessage,
            enabled = enabled,
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            maxLines = maxLines,
            singleLine = singleLine,
            visualTransformation = if (passwordVisible) 
                VisualTransformation.None 
            else 
                PasswordVisualTransformation(),
            trailingIcon = {
                IconButton(
                    onClick = { passwordVisible = !passwordVisible }
                ) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                    )
                }
            }
        )
        
        if (showStrengthIndicator && value.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            PasswordStrengthIndicator(
                password = value,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * A composable function that displays a visual indicator of password strength.
 *
 * @param password The password to evaluate
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
fun PasswordStrengthIndicator(
    password: String,
    modifier: Modifier = Modifier
) {
    val strengthScore = calculatePasswordStrength(password)
    val strengthLevel = getPasswordStrengthLevel(strengthScore)
    
    Column(
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth()
        ) {
            // Segment 1 (always filled if password exists)
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .height(4.dp),
                color = strengthLevel.color
            ) {}
            
            Spacer(modifier = Modifier.width(2.dp))
            
            // Segment 2 (filled for medium and strong)
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .height(4.dp),
                color = if (strengthLevel == PasswordStrength.WEAK) 
                    MaterialTheme.colors.surface 
                else 
                    strengthLevel.color
            ) {}
            
            Spacer(modifier = Modifier.width(2.dp))
            
            // Segment 3 (filled only for strong)
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .height(4.dp),
                color = if (strengthLevel == PasswordStrength.STRONG) 
                    strengthLevel.color 
                else 
                    MaterialTheme.colors.surface
            ) {}
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = strengthLevel.label,
            style = MaterialTheme.typography.caption,
            color = strengthLevel.color,
            modifier = Modifier.padding(start = 4.dp)
        )
    }
}

/**
 * Calculates the strength of a password based on various criteria.
 *
 * @param password The password to evaluate
 * @return Strength score from 0-100
 */
fun calculatePasswordStrength(password: String): Int {
    var score = 0
    
    // Check password length (up to 40 points)
    when {
        password.length > 12 -> score += 40
        password.length >= 8 -> score += 25
        password.length >= 6 -> score += 10
        else -> score += 5
    }
    
    // Check for character variety (up to 50 points)
    if (password.any { it.isUpperCase() }) score += 10
    if (password.any { it.isLowerCase() }) score += 10
    if (password.any { it.isDigit() }) score += 15
    if (password.any { !it.isLetterOrDigit() }) score += 15
    
    // Check for common patterns and weaknesses (penalty up to 30 points)
    // Repeating characters
    if (password.matches(Regex(".*(.)\\1{2,}.*"))) score -= 10
    
    // Sequential numbers
    if (password.matches(Regex(".*(?:012|123|234|345|456|567|678|789).*"))) score -= 5
    
    // Sequential letters
    if (password.matches(Regex("(?i).*(?:abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz).*"))) score -= 5
    
    // Common words (simplified check)
    val commonWords = listOf("password", "123456", "qwerty", "admin")
    if (commonWords.any { password.contains(it, ignoreCase = true) }) score -= 10
    
    // Ensure score is between 0 and 100
    return score.coerceIn(0, 100)
}

/**
 * Determines the strength level based on a password strength score.
 *
 * @param strengthScore The calculated strength score
 * @return PasswordStrength enum value
 */
fun getPasswordStrengthLevel(strengthScore: Int): PasswordStrength {
    return when {
        strengthScore < 40 -> PasswordStrength.WEAK
        strengthScore < 70 -> PasswordStrength.MEDIUM
        else -> PasswordStrength.STRONG
    }
}

/**
 * Enum class representing different levels of password strength.
 *
 * @property label Text description of the strength level
 * @property color Color representation for visual feedback
 */
enum class PasswordStrength(val label: String, val color: androidx.compose.ui.graphics.Color) {
    WEAK("Débil (Weak)", Error),
    MEDIUM("Media (Medium)", Warning),
    STRONG("Fuerte (Strong)", Success)
}