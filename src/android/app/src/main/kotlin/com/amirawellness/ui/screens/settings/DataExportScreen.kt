package com.amirawellness.ui.screens.settings

import androidx.compose.foundation.layout.* // androidx.compose.foundation:foundation-layout:1.5.0
import androidx.compose.foundation.rememberScrollState // androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.verticalScroll // androidx.compose.foundation:foundation:1.5.0
import androidx.compose.material.* // androidx.compose.material:material:1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.getValue // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.mutableStateOf // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.setValue // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.platform.LocalContext // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui:ui-unit:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt:hilt-navigation-compose:1.0.0
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.inputs.CustomTextField
import com.amirawellness.ui.components.inputs.PasswordField
import com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.components.feedback.SuccessView
import com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import android.content.Intent // android.content:android:latest
import androidx.core.content.FileProvider // androidx.core:core-ktx:1.10.0
import android.net.Uri // android.net:android:latest

/**
 * Main composable function for the data export screen
 *
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier to customize the layout
 */
@Composable
fun DataExportScreen(
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // Get the DataExportViewModel using hiltViewModel()
    val viewModel: DataExportViewModel = hiltViewModel()

    // Get the current context using LocalContext.current
    val context = LocalContext.current

    // Collect the UI state from the ViewModel using collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    // Create state variables for password input and export type selection
    var password by remember { mutableStateOf("") }
    var selectedOption by remember { mutableStateOf(0) } // 0: All Data, 1: Journals Only, 2: Emotional Data Only

    // Create a ScrollState for scrollable content
    val scrollState = rememberScrollState()

    // Set up the Scaffold with a TopAppBar containing a title and back button
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text("Exportar Datos (Export Data)", color = TextPrimary) },
                backgroundColor = Surface,
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(
                            imageVector = androidx.compose.material.icons.filled.ArrowBack,
                            contentDescription = "Atrás (Back)",
                            tint = TextPrimary
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        // Implement the main content in the Scaffold body
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .verticalScroll(scrollState),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Handle different UI states (loading, success, error)
            when {
                uiState.isLoading -> {
                    // When in loading state, show a loading indicator
                    LoadingIndicator(text = "Exportando datos... (Exporting data...)")
                }

                uiState.isSuccess -> {
                    // When in success state, show success view with share option
                    SuccessView(
                        message = "Datos exportados con éxito (Data exported successfully)",
                        description = "Tus datos han sido exportados y encriptados de forma segura. (Your data has been securely exported and encrypted.)",
                        actionText = "Compartir (Share)",
                        onAction = {
                            // Implement the share functionality for exported files
                            uiState.exportedFileUri?.let { fileUri ->
                                ShareExportedFile(fileUri, context)
                            }
                        },
                        modifier = Modifier.padding(16.dp)
                    )
                }

                uiState.error != null -> {
                    // When in error state, show error view with retry option
                    ErrorView(
                        message = "Error al exportar datos (Error exporting data)",
                        description = uiState.error,
                        actionText = "Reintentar (Retry)",
                        onAction = {
                            // Retry the export operation based on the selected option
                            when (selectedOption) {
                                0 -> viewModel.exportUserData(password)
                                1 -> viewModel.exportJournalsOnly(password)
                                2 -> viewModel.exportEmotionalDataOnly(password)
                            }
                        },
                        modifier = Modifier.padding(16.dp)
                    )
                }

                else -> {
                    // When in normal state, show the export options and password input
                    ExportOptionsSection(
                        selectedOption = selectedOption,
                        onOptionSelected = { selectedOption = it },
                        modifier = Modifier.padding(16.dp)
                    )

                    PasswordSection(
                        password = password,
                        onPasswordChange = { password = it },
                        isError = uiState.error != null,
                        errorMessage = uiState.error ?: "",
                        modifier = Modifier.padding(16.dp)
                    )

                    ExportButton(
                        onExport = {
                            // Validate password and trigger export based on selected option
                            if (viewModel.validatePassword(password)) {
                                when (selectedOption) {
                                    0 -> viewModel.exportUserData(password)
                                    1 -> viewModel.exportJournalsOnly(password)
                                    2 -> viewModel.exportEmotionalDataOnly(password)
                                }
                            }
                        },
                        enabled = password.isNotEmpty(),
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }
        }
    }
}

/**
 * Composable function that displays the export options selection
 *
 * @param selectedOption The currently selected option (0, 1, or 2)
 * @param onOptionSelected Callback when an option is selected
 * @param modifier Modifier to customize the layout
 */
@Composable
fun ExportOptionsSection(
    selectedOption: Int,
    onOptionSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Selecciona los datos a exportar (Select data to export)",
                style = MaterialTheme.typography.h6,
                color = TextPrimary,
                textAlign = TextAlign.Start
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.compose.material.RadioButton(
                    selected = selectedOption == 0,
                    onClick = { onOptionSelected(0) }
                )
                Column {
                    Text(
                        text = "Todos los datos (All Data)",
                        style = MaterialTheme.typography.body1,
                        color = TextPrimary
                    )
                    Text(
                        text = "Incluye tu perfil, diarios y estados emocionales. (Includes your profile, journals, and emotional states.)",
                        style = MaterialTheme.typography.caption,
                        color = TextPrimary
                    )
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.compose.material.RadioButton(
                    selected = selectedOption == 1,
                    onClick = { onOptionSelected(1) }
                )
                Column {
                    Text(
                        text = "Solo diarios (Journals Only)",
                        style = MaterialTheme.typography.body1,
                        color = TextPrimary
                    )
                    Text(
                        text = "Incluye solo tus grabaciones de diario. (Includes only your journal recordings.)",
                        style = MaterialTheme.typography.caption,
                        color = TextPrimary
                    )
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.compose.material.RadioButton(
                    selected = selectedOption == 2,
                    onClick = { onOptionSelected(2) }
                )
                Column {
                    Text(
                        text = "Solo estados emocionales (Emotional Data Only)",
                        style = MaterialTheme.typography.body1,
                        color = TextPrimary
                    )
                    Text(
                        text = "Incluye solo tus registros de estado emocional. (Includes only your emotional state logs.)",
                        style = MaterialTheme.typography.caption,
                        color = TextPrimary
                    )
                }
            }
        }
    }
}

/**
 * Composable function that displays the password input section
 *
 * @param password The current password text
 * @param onPasswordChange Callback when the password text changes
 * @param isError Whether the input is in an error state
 * @param errorMessage Error message to display when isError is true
 * @param modifier Modifier to customize the layout
 */
@Composable
fun PasswordSection(
    password: String,
    onPasswordChange: (String) -> Unit,
    isError: Boolean,
    errorMessage: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Contraseña (Password)",
                style = MaterialTheme.typography.h6,
                color = TextPrimary,
                textAlign = TextAlign.Start
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Tus datos serán encriptados con una contraseña. (Your data will be encrypted with a password.)",
                style = MaterialTheme.typography.body2,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            PasswordField(
                value = password,
                onValueChange = onPasswordChange,
                label = "Ingresa tu contraseña (Enter your password)",
                isError = isError,
                errorMessage = errorMessage,
                showStrengthIndicator = true
            )
        }
    }
}

/**
 * Composable function that displays the export button
 *
 * @param onExport Callback when the export button is clicked
 * @param enabled Whether the button is enabled
 * @param modifier Modifier to customize the layout
 */
@Composable
fun ExportButton(
    onExport: () -> Unit,
    enabled: Boolean,
    modifier: Modifier = Modifier
) {
    PrimaryButton(
        text = "Exportar Datos (Export Data)",
        onClick = onExport,
        enabled = enabled,
        modifier = modifier.fillMaxWidth()
    )
}

/**
 * Function to share the exported file using Android's share functionality
 *
 * @param fileUri The URI of the exported file
 * @param context The Android context
 */
fun ShareExportedFile(fileUri: Uri, context: android.content.Context) {
    // Create a share Intent with ACTION_SEND
    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        // Set the MIME type to application/octet-stream
        type = "application/octet-stream"
        // Add the file URI as an extra using FileProvider for secure sharing
        putExtra(Intent.EXTRA_STREAM, fileUri)
        // Add flags to grant read permission to the receiving app
        flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
    }

    // Create a chooser Intent for the user to select an app
    val chooserIntent = Intent.createChooser(shareIntent, "Compartir datos (Share data)")

    // Start the activity with the chooser Intent
    context.startActivity(chooserIntent)
}