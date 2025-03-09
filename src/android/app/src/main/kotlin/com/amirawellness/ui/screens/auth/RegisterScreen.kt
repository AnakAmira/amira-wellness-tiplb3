package com.amirawellness.ui.screens.auth

import androidx.compose.foundation.Image // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.layout.* // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.rememberScrollState // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.verticalScroll // androidx.compose.foundation version: 1.5.0
import androidx.compose.material.MaterialTheme // androidx.compose.material version: 1.5.0
import androidx.compose.material.Surface // androidx.compose.material version: 1.5.0
import androidx.compose.material.Text // androidx.compose.material version: 1.5.0
import androidx.compose.material.Checkbox // androidx.compose.material version: 1.5.0
import androidx.compose.material.TextButton // androidx.compose.material version: 1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime version: 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.platform.LocalFocusManager // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.res.painterResource // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.input.ImeAction // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.input.KeyboardType // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose version: 1.0.0
import com.amirawellness.R
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.inputs.CustomTextField
import com.amirawellness.ui.components.inputs.PasswordField
import com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.theme.AmiraWellnessTheme

/**
 * Composable function that renders the registration screen UI
 */
@Composable
fun RegisterScreen() {
    // Obtain the RegisterViewModel instance using hiltViewModel()
    val registerViewModel: RegisterViewModel = hiltViewModel()

    // Collect the UI state from the ViewModel using collectAsState()
    val uiState = registerViewModel.uiState.collectAsState()

    // Get the local focus manager for handling keyboard actions
    val focusManager = LocalFocusManager.current

    // Create a Surface container with the app's background color
    AmiraWellnessTheme {
        Surface(color = MaterialTheme.colors.background) {
            // Create a Column with vertical scrolling for the registration form
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Display the app logo at the top of the screen
                Image(
                    painter = painterResource(id = R.drawable.ic_launcher_foreground), // Replace with actual logo resource
                    contentDescription = stringResource(id = R.string.app_name),
                    modifier = Modifier.size(120.dp)
                )

                // Display the registration title text
                Text(
                    text = stringResource(id = R.string.register_title),
                    style = MaterialTheme.typography.h5,
                    textAlign = TextAlign.Center
                )

                // Create an email input field using CustomTextField
                CustomTextField(
                    value = uiState.value.email,
                    onValueChange = { registerViewModel.updateEmail(it) },
                    label = stringResource(id = R.string.email),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(androidx.compose.ui.focus.FocusDirection.Down) }
                    )
                )

                // Create a password input field using PasswordField with strength indicator
                PasswordField(
                    value = uiState.value.password,
                    onValueChange = { registerViewModel.updatePassword(it) },
                    label = stringResource(id = R.string.password),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(androidx.compose.ui.focus.FocusDirection.Down) }
                    )
                )

                // Create a password confirmation field using PasswordField
                PasswordField(
                    value = uiState.value.passwordConfirm,
                    onValueChange = { registerViewModel.updatePasswordConfirm(it) },
                    label = stringResource(id = R.string.confirm_password),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    )
                )

                // Add a checkbox for terms and conditions acceptance
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Checkbox(
                        checked = uiState.value.termsAccepted,
                        onCheckedChange = { registerViewModel.updateTermsAccepted(it) }
                    )
                    Text(text = stringResource(id = R.string.accept_terms))
                }

                // Display any error messages from the UI state
                if (uiState.value.errorMessage != null) {
                    ErrorView(
                        message = uiState.value.errorMessage!!,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }

                // Add a register button using PrimaryButton
                PrimaryButton(
                    text = stringResource(id = R.string.register),
                    onClick = {
                        focusManager.clearFocus()
                        registerViewModel.register()
                    },
                    enabled = !uiState.value.isLoading,
                    isLoading = uiState.value.isLoading,
                    modifier = Modifier.padding(vertical = 16.dp)
                )

                // Add an "Already have an account? Login" section at the bottom
                Row(
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(text = stringResource(id = R.string.already_have_account))
                    TextButton(onClick = { registerViewModel.navigateToLogin() }) {
                        Text(text = stringResource(id = R.string.login))
                    }
                }
            }
        }
    }
}

/**
 * Composable function that contains the main content of the registration screen
 */
@Composable
fun RegisterContent(
    uiState: RegisterUiState,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onPasswordConfirmChange: (String) -> Unit,
    onTermsAcceptedChange: (Boolean) -> Unit,
    onRegisterClick: () -> Unit,
    onLoginClick: () -> Unit,
    onClearError: () -> Unit
) {
    // Create a Column with padding and spacing for form elements
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Display the app logo at the top
        Image(
            painter = painterResource(id = R.drawable.ic_launcher_foreground), // Replace with actual logo resource
            contentDescription = stringResource(id = R.string.app_name),
            modifier = Modifier.size(120.dp)
        )

        // Display the registration title text
        Text(
            text = stringResource(id = R.string.register_title),
            style = MaterialTheme.typography.h5,
            textAlign = TextAlign.Center
        )

        // Create an email input field with current value from uiState
        CustomTextField(
            value = uiState.email,
            onValueChange = onEmailChange,
            label = stringResource(id = R.string.email)
        )

        // Create a password input field with strength indicator and current value from uiState
        PasswordField(
            value = uiState.password,
            onValueChange = onPasswordChange,
            label = stringResource(id = R.string.password)
        )

        // Create a password confirmation field with current value from uiState
        PasswordField(
            value = uiState.passwordConfirm,
            onValueChange = onPasswordConfirmChange,
            label = stringResource(id = R.string.confirm_password)
        )

        // Add a Row with checkbox for terms and conditions acceptance
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Checkbox(
                checked = uiState.termsAccepted,
                onCheckedChange = onTermsAcceptedChange
            )
            Text(text = stringResource(id = R.string.accept_terms))
        }

        // Display error message if present in uiState
        if (uiState.errorMessage != null) {
            ErrorView(
                message = uiState.errorMessage,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // Add a register button that calls onRegisterClick, showing loading state from uiState
        PrimaryButton(
            text = stringResource(id = R.string.register),
            onClick = onRegisterClick,
            enabled = !uiState.isLoading,
            isLoading = uiState.isLoading,
            modifier = Modifier.padding(vertical = 16.dp)
        )

        // Add an "Already have an account? Login" section that calls onLoginClick
        Row(
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = stringResource(id = R.string.already_have_account))
            TextButton(onClick = onLoginClick) {
                Text(text = stringResource(id = R.string.login))
            }
        }
    }
}