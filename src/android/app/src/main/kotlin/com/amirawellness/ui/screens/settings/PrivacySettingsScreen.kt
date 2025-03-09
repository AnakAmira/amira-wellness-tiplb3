package com.amirawellness.ui.screens.settings

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.setValue // version: 1.5.0
import androidx.compose.foundation.layout.Column // version: 1.5.0
import androidx.compose.foundation.layout.Spacer // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.rememberScrollState // version: 1.5.0
import androidx.compose.foundation.verticalScroll // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Scaffold // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.TopAppBar // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0
import androidx.compose.ui.res.stringResource // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.NavController // version: 2.7.0
import com.amirawellness.R
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.dialogs.ConfirmationDialog
import com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import androidx.compose.material.OutlinedTextField // version: 1.5.0
import androidx.compose.ui.text.input.PasswordVisualTransformation // version: 1.5.0
import androidx.compose.ui.text.input.TextFieldValue // version: 1.5.0

/**
 * Main composable function that displays the privacy settings screen with various privacy configuration options
 *
 * @param navController NavController for handling screen navigation
 */
@Composable
fun PrivacySettingsScreen(navController: NavController) {
    // LD1: Create NavActions instance with the provided NavController
    val navActions = remember { NavActions(navController) }

    // LD1: Obtain PrivacySettingsViewModel instance using hiltViewModel()
    val viewModel: PrivacySettingsViewModel = hiltViewModel()

    // LD1: Collect uiState from ViewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Create state variables for delete confirmation dialog and export password dialog
    var showDeleteConfirmationDialog by remember { mutableStateOf(false) }
    var showExportPasswordDialog by remember { mutableStateOf(false) }

    // LD1: Create state variable for password text field
    var exportPassword by remember { mutableStateOf(TextFieldValue("")) }

    // LD1: Set up Scaffold with TopAppBar containing title and back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(id = R.string.privacy_settings),
                        color = TextPrimary
                    )
                },
                backgroundColor = Surface,
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(
                            imageVector = Icons.Filled.ArrowBack,
                            contentDescription = stringResource(id = R.string.back),
                            tint = TextPrimary
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        // LD1: Implement scrollable Column for privacy settings content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // LD1: Create Data Collection section with analytics and crash reporting toggles
            SettingsSectionHeader(title = stringResource(id = R.string.data_collection))

            SettingsSwitchItem(
                title = stringResource(id = R.string.analytics_enabled),
                subtitle = stringResource(id = R.string.analytics_description),
                checked = uiState.analyticsEnabled,
                onCheckedChange = { enabled ->
                    viewModel.toggleAnalyticsConsent(enabled)
                }
            )

            SettingsSwitchItem(
                title = stringResource(id = R.string.crash_reporting_enabled),
                subtitle = stringResource(id = R.string.crash_reporting_description),
                checked = uiState.crashReportingEnabled,
                onCheckedChange = { enabled ->
                    viewModel.toggleCrashReportingConsent(enabled)
                }
            )

            // LD1: Create Data Storage section with data retention period dropdown and encryption toggles
            SettingsSectionHeader(title = stringResource(id = R.string.data_storage))

            SettingsDropdownItem(
                title = stringResource(id = R.string.data_retention_period),
                selectedValue = uiState.dataRetentionPeriod,
                options = listOf("3 months", "6 months", "1 year"),
                onOptionSelected = { period ->
                    viewModel.setDataRetentionPeriod(period)
                }
            )

            SettingsSwitchItem(
                title = stringResource(id = R.string.encryption_enabled),
                subtitle = stringResource(id = R.string.encryption_description),
                checked = uiState.encryptionEnabled,
                onCheckedChange = { enabled ->
                    viewModel.toggleEncryption(enabled)
                }
            )

            // LD1: Create Data Control section with export and delete options
            SettingsSectionHeader(title = stringResource(id = R.string.data_control))

            PrimaryButton(
                text = stringResource(id = R.string.export_data),
                onClick = { showExportPasswordDialog = true },
                enabled = !uiState.isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            )

            Spacer(modifier = Modifier.height(8.dp))

            PrimaryButton(
                text = stringResource(id = R.string.delete_all_data),
                onClick = { showDeleteConfirmationDialog = true },
                enabled = !uiState.isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            )

            // LD1: Implement delete confirmation dialog
            ConfirmationDialog(
                title = stringResource(id = R.string.delete_confirmation_title),
                message = stringResource(id = R.string.delete_confirmation_message),
                confirmButtonText = stringResource(id = R.string.delete),
                cancelButtonText = stringResource(id = R.string.cancel),
                onConfirm = { viewModel.deleteAllData() },
                onDismiss = { showDeleteConfirmationDialog = false },
                showDialog = showDeleteConfirmationDialog
            )

            // LD1: Implement export password dialog for encrypted exports
            ExportPasswordDialog(
                showDialog = showExportPasswordDialog,
                password = exportPassword,
                onPasswordChange = { password -> exportPassword = password },
                onConfirm = { password ->
                    viewModel.exportData(password.text)
                    showExportPasswordDialog = false
                    exportPassword = TextFieldValue("")
                },
                onDismiss = {
                    showExportPasswordDialog = false
                    exportPassword = TextFieldValue("")
                }
            )

            // LD1: Handle loading state with LoadingIndicator
            if (uiState.isLoading) {
                LoadingIndicator(modifier = Modifier.fillMaxSize())
            }

            // LD1: Display success messages for export and deletion operations
            if (uiState.exportSuccess) {
                Text(
                    text = stringResource(id = R.string.data_exported_successfully),
                    color = MaterialTheme.colors.primary,
                    modifier = Modifier.padding(16.dp)
                )
                viewModel.resetState()
            }

            if (uiState.deleteSuccess) {
                Text(
                    text = stringResource(id = R.string.data_deleted_successfully),
                    color = MaterialTheme.colors.primary,
                    modifier = Modifier.padding(16.dp)
                )
                viewModel.resetState()
            }

            // LD1: Display error messages when operations fail
            if (uiState.errorMessage != null) {
                Text(
                    text = uiState.errorMessage,
                    color = MaterialTheme.colors.error,
                    modifier = Modifier.padding(16.dp)
                )
                viewModel.resetState()
            }

            // LD1: Handle file sharing intent for exported data
            // TODO: Implement file sharing intent
        }
    }
}

/**
 * Composable function that displays a dialog for entering an export password
 *
 * @param showDialog Boolean state to control the visibility of the dialog
 * @param password TextFieldValue for the password input
 * @param onPasswordChange Callback for when the password changes
 * @param onConfirm Callback for when the confirm button is clicked
 * @param onDismiss Callback for when the dialog is dismissed
 */
@Composable
fun ExportPasswordDialog(
    showDialog: Boolean,
    password: TextFieldValue,
    onPasswordChange: (TextFieldValue) -> Unit,
    onConfirm: (TextFieldValue) -> Unit,
    onDismiss: () -> Unit
) {
    // LD1: Check if showDialog is true, if not, return early
    if (!showDialog) return

    // LD1: Create an AlertDialog with title 'Export Data'
    androidx.compose.material.AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = stringResource(id = R.string.export_data))
        },
        text = {
            Column {
                // LD1: Add description text explaining password protection
                Text(text = stringResource(id = R.string.export_password_description))
                Spacer(modifier = Modifier.height(8.dp))

                // LD1: Add OutlinedTextField for password input with PasswordVisualTransformation
                OutlinedTextField(
                    value = password,
                    onValueChange = onPasswordChange,
                    label = { Text(stringResource(id = R.string.password)) },
                    visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            // LD1: Add confirm button that calls onConfirm with the entered password
            PrimaryButton(
                text = stringResource(id = R.string.confirm),
                onClick = { onConfirm(password) }
            )
        },
        dismissButton = {
            // LD1: Add cancel button that calls onDismiss
            SecondaryButton(
                text = stringResource(id = R.string.cancel),
                onClick = onDismiss
            )
        }
    )
    // LD1: Set up the onDismiss callback for dialog dismissal when clicking outside
}