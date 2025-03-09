package com.amirawellness.ui.screens.settings

import android.app.TimePickerDialog // android version: latest
import androidx.compose.foundation.clickable // version: 1.5.0
import androidx.compose.foundation.layout.Column // version: 1.5.0
import androidx.compose.foundation.layout.Row // version: 1.5.0
import androidx.compose.foundation.layout.Spacer // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.rememberScrollState // version: 1.5.0
import androidx.compose.foundation.verticalScroll // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.Divider // version: 1.5.0
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
import androidx.compose.material.icons.filled.Warning // version: 1.5.0
import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.setValue // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0
import androidx.compose.ui.res.stringResource // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.NavController // version: 2.7.0
import com.amirawellness.R // version: latest
import com.amirawellness.core.constants.NotificationConstants // version: latest
import com.amirawellness.ui.components.buttons.PrimaryButton // version: latest
import com.amirawellness.ui.components.loading.LoadingIndicator // version: latest
import com.amirawellness.ui.navigation.NavActions // version: latest
import java.util.Calendar // version: latest

/**
 * Main composable function that displays the notification settings screen
 * @param navController NavController
 */
@Composable
fun NotificationSettingsScreen(navController: NavController) {
    // Create NavActions instance with the provided NavController
    val navActions = remember { NavActions(navController) }

    // Obtain NotificationSettingsViewModel instance using hiltViewModel()
    val viewModel: NotificationSettingsViewModel = hiltViewModel()

    // Collect uiState from ViewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // Set up Scaffold with TopAppBar containing title and back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.notification_settings)) },
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(Icons.Filled.ArrowBack, stringResource(id = R.string.back))
                    }
                }
            )
        }
    ) { paddingValues ->
        // Implement scrollable Column for settings content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Display system notification warning if system notifications are disabled
            if (!uiState.systemNotificationsEnabled) {
                SystemNotificationWarning(onOpenSettings = { viewModel.openNotificationSettings() })
            }

            // Create Notification Types section with toggle switches for different notification types
            NotificationSectionHeader(title = stringResource(id = R.string.notification_types))
            NotificationSwitchItem(
                title = stringResource(id = R.string.daily_reminders),
                checked = uiState.dailyRemindersEnabled,
                onCheckedChange = { viewModel.toggleDailyReminders(it) },
                enabled = uiState.systemNotificationsEnabled
            )
            NotificationSwitchItem(
                title = stringResource(id = R.string.streak_reminders),
                checked = uiState.streakRemindersEnabled,
                onCheckedChange = { viewModel.toggleStreakReminders(it) },
                enabled = uiState.systemNotificationsEnabled
            )
            NotificationSwitchItem(
                title = stringResource(id = R.string.achievement_notifications),
                checked = uiState.achievementNotificationsEnabled,
                onCheckedChange = { viewModel.toggleAchievementNotifications(it) },
                enabled = uiState.systemNotificationsEnabled
            )
            NotificationSwitchItem(
                title = stringResource(id = R.string.affirmation_notifications),
                checked = uiState.affirmationNotificationsEnabled,
                onCheckedChange = { viewModel.toggleAffirmationNotifications(it) },
                enabled = uiState.systemNotificationsEnabled
            )
            NotificationSwitchItem(
                title = stringResource(id = R.string.wellness_tips),
                checked = uiState.wellnessTipsEnabled,
                onCheckedChange = { viewModel.toggleWellnessTips(it) },
                enabled = uiState.systemNotificationsEnabled
            )
            NotificationSwitchItem(
                title = stringResource(id = R.string.app_updates),
                checked = uiState.appUpdatesEnabled,
                onCheckedChange = { viewModel.toggleAppUpdates(it) },
                enabled = uiState.systemNotificationsEnabled
            )

            // Create Daily Reminder Settings section with time picker and day selection
            NotificationSectionHeader(title = stringResource(id = R.string.daily_reminder_settings))
            TimePickerItem(
                title = stringResource(id = R.string.reminder_time),
                hour = uiState.reminderHour,
                minute = uiState.reminderMinute,
                onTimeSelected = { hour, minute -> viewModel.updateReminderTime(hour, minute) },
                enabled = uiState.systemNotificationsEnabled && uiState.dailyRemindersEnabled
            )
            DaySelectionItem(
                title = stringResource(id = R.string.reminder_days),
                selectedDays = uiState.reminderDays,
                onDaysSelected = { viewModel.updateReminderDays(it) },
                enabled = uiState.systemNotificationsEnabled && uiState.dailyRemindersEnabled
            )

            // Add Reset to Defaults button at the bottom
            PrimaryButton(
                text = stringResource(id = R.string.reset_to_defaults),
                onClick = { viewModel.resetToDefaults() },
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
                enabled = uiState.systemNotificationsEnabled && !uiState.isLoading,
                isLoading = uiState.isLoading
            )

            // Implement loading indicator when settings are being saved
            if (uiState.isLoading) {
                LoadingIndicator(modifier = Modifier.padding(16.dp))
            }
        }
    }
}

/**
 * Composable function that displays a section header in the notification settings screen
 * @param title String
 */
@Composable
fun NotificationSectionHeader(title: String) {
    // Create a Text component with the section title
    Text(
        text = title,
        style = MaterialTheme.typography.subtitle1,
        modifier = Modifier.padding(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 8.dp)
    )
    // Apply appropriate padding and color
    Divider()
}

/**
 * Composable function that displays a notification setting item with a toggle switch
 * @param title String
 * @param subtitle String?
 * @param checked Boolean
 * @param onCheckedChange Function
 * @param enabled Boolean
 */
@Composable
fun NotificationSwitchItem(
    title: String,
    subtitle: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    enabled: Boolean = true
) {
    // Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .fillMaxWidth(),
        enabled = enabled
    ) {
        // Create a Row with proper padding for the item content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Add a Column for the title and optional subtitle
            Column(modifier = Modifier.weight(1f)) {
                // Add the title text with MaterialTheme.typography.body1 style
                Text(
                    text = title,
                    style = MaterialTheme.typography.body1,
                )
                // Add the subtitle text with MaterialTheme.typography.caption style if provided
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.caption,
                    )
                }
            }
            // Add a Spacer to push the switch to the end
            Spacer(modifier = Modifier.weight(0.05f))
            // Add a Switch component with the provided checked state and onCheckedChange handler
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled
            )
        }
    }
}

/**
 * Composable function that displays a time picker item for selecting notification time
 * @param title String
 * @param hour Int
 * @param minute Int
 * @param onTimeSelected Function
 * @param enabled Boolean
 */
@Composable
fun TimePickerItem(
    title: String,
    hour: Int,
    minute: Int,
    onTimeSelected: (Int, Int) -> Unit,
    enabled: Boolean = true
) {
    // Get the current Android context
    val context = LocalContext.current

    // Create a state to track whether the time picker dialog is shown
    var showTimePickerDialog by remember { mutableStateOf(false) }

    // Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .fillMaxWidth()
            // Make the card clickable to show time picker dialog if enabled
            .clickable(enabled = enabled) {
                showTimePickerDialog = true
            },
        enabled = enabled
    ) {
        // Create a Row with proper padding for the item content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Add the title text with MaterialTheme.typography.body1 style
            Text(
                text = title,
                style = MaterialTheme.typography.body1,
                modifier = Modifier.weight(1f)
            )
            // Add a Spacer to push the time display to the end
            Spacer(modifier = Modifier.weight(0.05f))
            // Format and display the current time (hour:minute AM/PM)
            val formattedTime = String.format("%02d:%02d %s",
                if (hour % 12 == 0) 12 else hour % 12,
                minute,
                if (hour < 12) "AM" else "PM"
            )
            Text(text = formattedTime)
        }
    }

    // Implement TimePickerDialog that shows when card is clicked
    if (showTimePickerDialog) {
        val timePickerDialog = TimePickerDialog(
            context,
            { _, selectedHour, selectedMinute ->
                // Handle time selection by calling onTimeSelected with new hour and minute
                onTimeSelected(selectedHour, selectedMinute)
                showTimePickerDialog = false
            },
            hour,
            minute,
            false // Use 12-hour format
        )
        timePickerDialog.setOnDismissListener { showTimePickerDialog = false }
        timePickerDialog.show()
    }
}

/**
 * Composable function that displays day selection for notification scheduling
 * @param title String
 * @param selectedDays Set<String>
 * @param onDaysSelected Function
 * @param enabled Boolean
 */
@Composable
fun DaySelectionItem(
    title: String,
    selectedDays: Set<String>,
    onDaysSelected: (Set<String>) -> Unit,
    enabled: Boolean = true
) {
    // List of days of the week
    val daysOfWeek = listOf("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom")

    // Create a Card component with appropriate elevation and shape
    Card(
        modifier = Modifier
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .fillMaxWidth(),
        enabled = enabled
    ) {
        // Create a Column with proper padding for the item content
        Column(
            modifier = Modifier
                .padding(16.dp)
        ) {
            // Add the title text with MaterialTheme.typography.body1 style
            Text(
                text = title,
                style = MaterialTheme.typography.body1
            )
            // Add a Spacer for vertical spacing
            Spacer(modifier = Modifier.height(8.dp))
            // Create a Row with day selection chips for each day of the week
            Row {
                // For each day (Mon, Tue, Wed, etc.), create a selectable chip
                daysOfWeek.forEach { day ->
                    val isSelected = selectedDays.contains(daysOfWeek.indexOf(day).toString())
                    Surface(
                        modifier = Modifier
                            .padding(end = 8.dp)
                            .clickable(enabled = enabled) {
                                // Handle day selection/deselection by updating the set of selected days
                                val newSelectedDays = selectedDays.toMutableSet()
                                val dayIndex = daysOfWeek.indexOf(day).toString()
                                if (isSelected) {
                                    newSelectedDays.remove(dayIndex)
                                } else {
                                    newSelectedDays.add(dayIndex)
                                }
                                // Call onDaysSelected with the updated set when selection changes
                                onDaysSelected(newSelectedDays)
                            },
                        shape = MaterialTheme.shapes.small,
                        color = if (isSelected) MaterialTheme.colors.primary else MaterialTheme.colors.surface,
                        contentColor = if (isSelected) MaterialTheme.colors.onPrimary else MaterialTheme.colors.onSurface
                    ) {
                        Text(
                            text = day,
                            modifier = Modifier.padding(8.dp)
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays a warning when system notifications are disabled
 * @param onOpenSettings Function
 */
@Composable
fun SystemNotificationWarning(onOpenSettings: () -> Unit) {
    // Create a Card component with warning styling (yellow background, etc.)
    Card(
        modifier = Modifier
            .padding(16.dp)
            .fillMaxWidth(),
        backgroundColor = MaterialTheme.colors.secondaryVariant
    ) {
        // Create a Row with proper padding for the warning content
        Row(
            modifier = Modifier
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Add a warning icon
            Icon(
                imageVector = Icons.Filled.Warning,
                contentDescription = stringResource(id = R.string.warning),
                modifier = Modifier.padding(end = 8.dp)
            )
            // Add a Column for the warning text and action button
            Column {
                // Add the warning title text with bold style
                Text(
                    text = stringResource(id = R.string.system_notifications_disabled),
                    style = MaterialTheme.typography.body1,
                    textAlign = TextAlign.Start
                )
                // Add the warning description text explaining that system notifications are disabled
                Text(
                    text = stringResource(id = R.string.enable_system_notifications_message),
                    style = MaterialTheme.typography.caption,
                    textAlign = TextAlign.Start
                )
                // Add a button to open system notification settings
                PrimaryButton(
                    text = stringResource(id = R.string.open_settings),
                    onClick = onOpenSettings,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
    }
}