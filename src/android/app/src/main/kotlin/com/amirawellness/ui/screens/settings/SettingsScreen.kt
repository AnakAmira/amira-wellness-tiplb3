package com.amirawellness.ui.screens.settings

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.setValue // version: 1.5.0
import androidx.compose.foundation.layout.Column // version: 1.5.0
import androidx.compose.foundation.layout.Row // version: 1.5.0
import androidx.compose.foundation.layout.Spacer // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.rememberScrollState // version: 1.5.0
import androidx.compose.foundation.verticalScroll // version: 1.5.0
import androidx.compose.foundation.clickable // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.Divider // version: 1.5.0
import androidx.compose.material.DropdownMenu // version: 1.5.0
import androidx.compose.material.DropdownMenuItem // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Scaffold // version: 1.5.0
import androidx.compose.material.Surface // version: 1.5.0
import androidx.compose.material.Switch // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.TopAppBar // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // version: 1.5.0
import androidx.compose.material.icons.filled.KeyboardArrowDown // version: 1.5.0
import androidx.compose.material.icons.filled.KeyboardArrowRight // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0
import androidx.compose.ui.res.stringResource // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.NavController // version: 2.7.0
import com.amirawellness.R
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.dialogs.ConfirmationDialog
import com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary

/**
 * Composable screen that displays the main settings interface for the Amira Wellness Android application.
 * Provides access to various application settings including theme, language, biometric authentication,
 * and navigation to specialized settings screens like notifications and privacy.
 *
 * @param navController NavController for handling screen navigation
 */
@Composable
fun SettingsScreen(navController: NavController) {
    // LD1: Create NavActions instance with the provided NavController
    val navActions = remember { NavActions(navController) }

    // LD1: Obtain SettingsViewModel instance using hiltViewModel()
    val viewModel: SettingsViewModel = hiltViewModel()

    // LD1: Collect uiState from ViewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Create state variables for logout confirmation dialog
    var showLogoutConfirmationDialog by remember { mutableStateOf(false) }

    // LD1: Set up Scaffold with TopAppBar containing title and back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(id = R.string.settings_title),
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
        // LD1: Implement scrollable Column for settings content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // LD1: Create App Preferences section with theme and language selection
            SettingsSectionHeader(title = stringResource(id = R.string.app_preferences))

            SettingsDropdownItem(
                title = stringResource(id = R.string.theme),
                selectedValue = uiState.theme,
                options = listOf("light", "dark", "system"),
                onOptionSelected = { theme ->
                    viewModel.updateTheme(theme)
                }
            )

            SettingsDropdownItem(
                title = stringResource(id = R.string.language),
                selectedValue = uiState.language,
                options = listOf("es", "en"),
                onOptionSelected = { language ->
                    viewModel.updateLanguage(language)
                }
            )

            // LD1: Create Security section with biometric authentication toggle
            SettingsSectionHeader(title = stringResource(id = R.string.security))

            SettingsSwitchItem(
                title = stringResource(id = R.string.biometric_authentication),
                subtitle = stringResource(id = R.string.biometric_authentication_description),
                checked = uiState.biometricAuthEnabled,
                onCheckedChange = { enabled ->
                    viewModel.toggleBiometricAuth(enabled)
                },
                enabled = viewModel.isBiometricAvailable()
            )

            // LD1: Create Additional Settings section with navigation to specialized settings screens
            SettingsSectionHeader(title = stringResource(id = R.string.additional_settings))

            SettingsNavigationItem(
                title = stringResource(id = R.string.notification_settings),
                subtitle = stringResource(id = R.string.notification_settings_description),
                onClick = { navActions.navigateToNotificationSettings() }
            )

            SettingsNavigationItem(
                title = stringResource(id = R.string.privacy_settings),
                subtitle = stringResource(id = R.string.privacy_settings_description),
                onClick = { navActions.navigateToPrivacySettings() }
            )

            SettingsNavigationItem(
                title = stringResource(id = R.string.data_export),
                subtitle = stringResource(id = R.string.data_export_description),
                onClick = { navActions.navigateToDataExport() }
            )

            // LD1: Add Logout button at the bottom
            Spacer(modifier = Modifier.height(24.dp))
            PrimaryButton(
                text = stringResource(id = R.string.logout),
                onClick = { showLogoutConfirmationDialog = true },
                enabled = !uiState.isLoading,
                modifier = Modifier.padding(horizontal = 16.dp)
            )

            // LD1: Implement logout confirmation dialog
            ConfirmationDialog(
                title = stringResource(id = R.string.logout_confirmation_title),
                message = stringResource(id = R.string.logout_confirmation_message),
                confirmButtonText = stringResource(id = R.string.logout),
                cancelButtonText = stringResource(id = R.string.cancel),
                onConfirm = { viewModel.logout() },
                onDismiss = { showLogoutConfirmationDialog = false },
                showDialog = showLogoutConfirmationDialog
            )

            // LD1: Handle navigation based on user actions
            if (uiState.logoutSuccess) {
                navActions.navigateToLogin()
                viewModel.resetLogoutState()
            }

            // LD1: Implement loading indicator when settings are being saved or logout is in progress
            if (uiState.isLoading) {
                LoadingIndicator(modifier = Modifier.fillMaxSize())
            }
        }
    }
}

/**
 * Composable function that displays a section header in the settings screen.
 *
 * @param title The title of the section
 */
@Composable
fun SettingsSectionHeader(title: String) {
    // LD1: Create a Text component with the section title
    Text(
        text = title,
        style = MaterialTheme.typography.subtitle1,
        color = TextPrimary,
        modifier = Modifier.padding(start = 16.dp, top = 16.dp, end = 16.dp)
    )
    // LD1: Apply appropriate padding and color
}

/**
 * Composable function that displays a settings item with a toggle switch.
 *
 * @param title The title of the setting
 * @param subtitle The subtitle of the setting (optional)
 * @param checked The current state of the switch
 * @param onCheckedChange Callback when the switch is toggled
 */
@Composable
fun SettingsSwitchItem(
    title: String,
    subtitle: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    enabled: Boolean = true
) {
    // LD1: Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        elevation = 2.dp
    ) {
        // LD1: Create a Row with proper padding for the item content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LD1: Add a Column for the title and optional subtitle
            Column(modifier = Modifier.weight(1f)) {
                // LD1: Add the title text with MaterialTheme.typography.body1 style
                Text(
                    text = title,
                    style = MaterialTheme.typography.body1,
                    color = TextPrimary
                )
                // LD1: Add the subtitle text with MaterialTheme.typography.caption style if provided
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.caption,
                        color = TextPrimary
                    )
                }
            }
            // LD1: Add a Spacer to push the switch to the end
            Spacer(modifier = Modifier.weight(0.05f))
            // LD1: Add a Switch component with the provided checked state and onCheckedChange handler
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled
            )
        }
    }
}

/**
 * Composable function that displays a settings item with a dropdown selection.
 *
 * @param title The title of the setting
 * @param selectedValue The currently selected value
 * @param options The list of available options
 * @param onOptionSelected Callback when an option is selected
 */
@Composable
fun SettingsDropdownItem(
    title: String,
    selectedValue: String,
    options: List<String>,
    onOptionSelected: (String) -> Unit
) {
    // LD1: Create state for tracking dropdown expanded state
    var expanded by remember { mutableStateOf(false) }

    // LD1: Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp)
            // LD1: Make the card clickable to toggle dropdown
            .clickable { expanded = true },
        elevation = 2.dp
    ) {
        // LD1: Create a Row with proper padding for the item content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LD1: Add the title text with MaterialTheme.typography.body1 style
            Text(
                text = title,
                style = MaterialTheme.typography.body1,
                color = TextPrimary,
                modifier = Modifier.weight(1f)
            )
            // LD1: Add a Spacer to push the selected value to the end
            Spacer(modifier = Modifier.weight(0.05f))
            // LD1: Display the currently selected value
            Text(
                text = selectedValue,
                color = TextPrimary
            )
            // LD1: Add a dropdown arrow icon
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = "Dropdown",
                tint = TextPrimary
            )
        }
        // LD1: Create a DropdownMenu that shows when expanded is true
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            // LD1: For each option in options, create a DropdownMenuItem
            options.forEach { option ->
                DropdownMenuItem(
                    onClick = {
                        // LD1: Handle option selection by calling onOptionSelected and closing the dropdown
                        onOptionSelected(option)
                        expanded = false
                    }
                ) {
                    Text(text = option)
                }
            }
        }
    }
}

/**
 * Composable function that displays a settings item that navigates to another screen.
 *
 * @param title The title of the setting
 * @param subtitle The subtitle of the setting (optional)
 * @param onClick Callback when the item is clicked
 */
@Composable
fun SettingsNavigationItem(
    title: String,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    // LD1: Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp)
            // LD1: Make the card clickable with the provided onClick handler
            .clickable { onClick() },
        elevation = 2.dp
    ) {
        // LD1: Create a Row with proper padding for the item content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LD1: Add a Column for the title and optional subtitle
            Column(modifier = Modifier.weight(1f)) {
                // LD1: Add the title text with MaterialTheme.typography.body1 style
                Text(
                    text = title,
                    style = MaterialTheme.typography.body1,
                    color = TextPrimary
                )
                // LD1: Add the subtitle text with MaterialTheme.typography.caption style if provided
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.caption,
                        color = TextPrimary
                    )
                }
            }
            // LD1: Add a Spacer to push the navigation arrow to the end
            Spacer(modifier = Modifier.weight(0.05f))
            // LD1: Add a navigation arrow icon
            Icon(
                imageVector = Icons.Filled.KeyboardArrowRight,
                contentDescription = "Go to",
                tint = TextPrimary
            )
        }
    }
}