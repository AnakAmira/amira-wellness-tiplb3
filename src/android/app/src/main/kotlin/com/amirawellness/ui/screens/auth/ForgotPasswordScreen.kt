package com.amirawellness.ui.screens.auth

import androidx.compose.foundation.layout.* // androidx.compose.foundation version: 1.5.0
import androidx.compose.material.* // androidx.compose.material version: 1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime version: 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.input.KeyboardType // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose version: 1.0.0
import com.amirawellness.ui.components.inputs.CustomTextField
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.feedback.SuccessView
import com.amirawellness.ui.components.feedback.ErrorView

private const val PADDING_HORIZONTAL = 24.dp
private const val PADDING_VERTICAL = 16.dp
private const val SPACING = 16.dp

/**
 * Main composable function for the forgot password screen
 *
 * @param modifier Modifier
 */
@Composable
fun ForgotPasswordScreen(modifier: Modifier = Modifier) {
    // Get the ForgotPasswordViewModel using hiltViewModel()
    val viewModel: ForgotPasswordViewModel = hiltViewModel()

    // Collect the UI state from the ViewModel
    val uiState = viewModel.uiState.collectAsState()

    // Create a Scaffold with a TopAppBar showing 'Forgot Password' title
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text("Forgot Password") },
                navigationIcon = {
                    // Implement back button in the navigation icon of TopAppBar
                    SecondaryButton(text = "Back", onClick = { viewModel.navigateBack() })
                }
            )
        }
    ) { paddingValues ->
        // Create the main content in a Column with padding
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .padding(horizontal = PADDING_HORIZONTAL, vertical = PADDING_VERTICAL),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(SPACING)
        ) {
            // Show loading indicator when isLoading is true
            if (uiState.value.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.CenterHorizontally))
            }
            // Show success view when successMessage is not null
            else if (uiState.value.successMessage != null) {
                SuccessContent(
                    message = uiState.value.successMessage!!,
                    onContinue = { viewModel.navigateToLogin() },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            // Show error view when errorMessage is not null
            else if (uiState.value.errorMessage != null) {
                ErrorContent(
                    message = uiState.value.errorMessage!!,
                    onRetry = { viewModel.resetPassword() },
                    onDismiss = { viewModel.clearError() },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            // Show the forgot password form when not in loading, success, or error state
            else {
                ForgotPasswordForm(
                    email = uiState.value.email,
                    isLoading = uiState.value.isLoading,
                    onEmailChange = { viewModel.updateEmail(it) },
                    onResetPassword = { viewModel.resetPassword() },
                    onBack = { viewModel.navigateBack() },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

/**
 * Composable function for the forgot password form
 *
 * @param email String
 * @param isLoading Boolean
 * @param onEmailChange (String) -> Unit
 * @param onResetPassword () -> Unit
 * @param onBack () -> Unit
 * @param modifier Modifier
 */
@Composable
fun ForgotPasswordForm(
    email: String,
    isLoading: Boolean,
    onEmailChange: (String) -> Unit,
    onResetPassword: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Create a Column with the provided modifier
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(SPACING)
    ) {
        // Add descriptive text explaining the password reset process
        Text(
            text = "Enter your email address and we'll send you instructions on how to reset your password.",
            style = MaterialTheme.typography.body1,
            modifier = Modifier.fillMaxWidth()
        )

        // Add CustomTextField for email input with email keyboard type
        CustomTextField(
            value = email,
            onValueChange = onEmailChange,
            label = "Email",
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
            enabled = !isLoading,
            modifier = Modifier.fillMaxWidth()
        )

        // Add PrimaryButton for 'Reset Password' action
        PrimaryButton(
            text = "Reset Password",
            onClick = onResetPassword,
            enabled = !isLoading,
            modifier = Modifier.fillMaxWidth()
        )

        // Add SecondaryButton for 'Back to Login' action
        SecondaryButton(
            text = "Back to Login",
            onClick = onBack,
            enabled = !isLoading,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * Composable function for displaying success state
 *
 * @param message String
 * @param onContinue () -> Unit
 * @param modifier Modifier
 */
@Composable
fun SuccessContent(
    message: String,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Create a SuccessView with the success message
    SuccessView(
        message = message,
        description = "Please check your email for instructions on how to reset your password.",
        actionText = "Back to Login",
        onAction = onContinue,
        modifier = modifier
    )
}

/**
 * Composable function for displaying error state
 *
 * @param message String
 * @param onRetry () -> Unit
 * @param onDismiss () -> Unit
 * @param modifier Modifier
 */
@Composable
fun ErrorContent(
    message: String,
    onRetry: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Create an ErrorView with the error message
    ErrorView(
        message = message,
        description = "We apologize, but something went wrong. Please try again.",
        actionText = "Try Again",
        onAction = onRetry,
        modifier = modifier
    )
}