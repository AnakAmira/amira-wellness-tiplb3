package com.amirawellness.ui.screens.auth

import androidx.compose.foundation.Image // androidx.compose.foundation 1.5.0
import androidx.compose.foundation.layout.* // androidx.compose.foundation 1.5.0
import androidx.compose.foundation.rememberScrollState // androidx.compose.foundation 1.5.0
import androidx.compose.foundation.verticalScroll // androidx.compose.foundation 1.5.0
import androidx.compose.material.MaterialTheme // androidx.compose.material 1.5.0
import androidx.compose.material.Surface // androidx.compose.material 1.5.0
import androidx.compose.material.Text // androidx.compose.material 1.5.0
import androidx.compose.material.TextButton // androidx.compose.material 1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime 1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui 1.5.0
import androidx.compose.ui.platform.LocalFocusManager // androidx.compose.ui 1.5.0
import androidx.compose.ui.res.painterResource // androidx.compose.ui 1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui 1.5.0
import androidx.compose.ui.text.input.ImeAction // androidx.compose.ui 1.5.0
import androidx.compose.ui.text.input.KeyboardType // androidx.compose.ui 1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose 1.0.0
import com.amirawellness.R // Reference to the R class for resources
import com.amirawellness.ui.components.buttons.PrimaryButton // com.amirawellness.ui.components.buttons
import com.amirawellness.ui.components.inputs.CustomTextField // com.amirawellness.ui.components.inputs
import com.amirawellness.ui.components.inputs.PasswordField // com.amirawellness.ui.components.inputs
import com.amirawellness.ui.components.loading.LoadingIndicator // com.amirawellness.ui.components.loading
import com.amirawellness.ui.components.feedback.ErrorView // com.amirawellness.ui.components.feedback
import com.amirawellness.ui.theme.AmiraWellnessTheme // com.amirawellness.ui.theme

/**
 * Composable function that renders the login screen UI
 */
@Composable
fun LoginScreen() {
    // LD1: Obtain the LoginViewModel instance using hiltViewModel()
    val loginViewModel: LoginViewModel = hiltViewModel()

    // LD1: Collect the UI state from the ViewModel using collectAsState()
    val uiState = loginViewModel.uiState.collectAsState()

    // LD1: Get the local focus manager for handling keyboard actions
    val focusManager = LocalFocusManager.current

    // LD1: Create a Surface container with the app's background color
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colors.background
    ) {
        // LD1: Create a Column with vertical scrolling for the login form
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            LoginContent(
                uiState = uiState.value,
                onEmailChange = { loginViewModel.updateEmail(it) },
                onPasswordChange = { loginViewModel.updatePassword(it) },
                onLoginClick = {
                    focusManager.clearFocus()
                    loginViewModel.login()
                },
                onForgotPasswordClick = {
                    focusManager.clearFocus()
                    loginViewModel.navigateToForgotPassword()
                },
                onRegisterClick = {
                    focusManager.clearFocus()
                    loginViewModel.navigateToRegister()
                },
                onClearError = { loginViewModel.clearError() }
            )
        }
    }
}

/**
 * Composable function that contains the main content of the login screen
 */
@Composable
fun LoginContent(
    uiState: LoginUiState,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onLoginClick: () -> Unit,
    onForgotPasswordClick: () -> Unit,
    onRegisterClick: () -> Unit,
    onClearError: () -> Unit
) {
    // LD1: Create a Column with padding and spacing for form elements
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // LD1: Display the app logo at the top
        Image(
            painter = painterResource(id = R.drawable.ic_launcher_foreground), // Replace with actual logo resource
            contentDescription = stringResource(id = R.string.app_name),
            modifier = Modifier.size(120.dp)
        )

        // LD1: Display the login title text
        Text(
            text = stringResource(id = R.string.login_title),
            style = MaterialTheme.typography.h5,
            textAlign = TextAlign.Center
        )

        // LD1: Create an email input field with current value from uiState
        CustomTextField(
            value = uiState.email,
            onValueChange = onEmailChange,
            label = stringResource(id = R.string.email),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            isError = uiState.errorMessage != null,
        )

        // LD1: Create a password input field with current value from uiState
        PasswordField(
            value = uiState.password,
            onValueChange = onPasswordChange,
            label = stringResource(id = R.string.password),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            isError = uiState.errorMessage != null,
        )

        // LD1: Display error message if present in uiState
        if (uiState.errorMessage != null) {
            ErrorView(
                message = uiState.errorMessage,
                modifier = Modifier.fillMaxWidth()
            )
        }

        // LD1: Add a "Forgot Password?" text button that calls onForgotPasswordClick
        TextButton(onClick = onForgotPasswordClick) {
            Text(text = stringResource(id = R.string.forgot_password))
        }

        // LD1: Add a login button that calls onLoginClick, showing loading state from uiState
        PrimaryButton(
            text = stringResource(id = R.string.login),
            onClick = onLoginClick,
            enabled = !uiState.isLoading,
            isLoading = uiState.isLoading
        )

        // LD1: Add a "Don't have an account? Register" section that calls onRegisterClick
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = stringResource(id = R.string.no_account))
            TextButton(onClick = onRegisterClick) {
                Text(text = stringResource(id = R.string.register))
            }
        }
    }
}

// Provide string resources for the UI elements
@Composable
private fun rememberStringResources(): Map<String, String> {
    return remember {
        mapOf(
            "app_name" to stringResource(id = R.string.app_name),
            "login_title" to stringResource(id = R.string.login_title),
            "email" to stringResource(id = R.string.email),
            "password" to stringResource(id = R.string.password),
            "forgot_password" to stringResource(id = R.string.forgot_password),
            "login" to stringResource(id = R.string.login),
            "no_account" to stringResource(id = R.string.no_account),
            "register" to stringResource(id = R.string.register)
        )
    }
}