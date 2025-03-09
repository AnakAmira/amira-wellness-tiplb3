# src/android/app/src/main/kotlin/com/amirawellness/ui/screens/profile/ProfileScreen.kt
```kotlin
package com.amirawellness.ui.screens.profile

import androidx.compose.foundation.Image // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.background // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.shape.CircleShape // androidx.compose.foundation:1.5.0
import androidx.compose.material.* // androidx.compose.material:1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material:1.5.0
import androidx.compose.material.icons.filled.* // androidx.compose.material:1.5.0
import androidx.compose.material.icons.outlined.* // androidx.compose.material:1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.getValue // androidx.compose.runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.draw.clip // androidx.compose.ui:1.5.0
import androidx.compose.ui.res.painterResource // androidx.compose.ui:1.5.0
import androidx.compose.ui.text.font.FontWeight // androidx.compose.ui:1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui:1.5.0
import androidx.compose.ui.unit.sp // androidx.compose.ui:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose:1.0.0
import com.amirawellness.R
import com.amirawellness.data.models.UserProfile // com.amirawellness.data.models.User
import com.amirawellness.ui.components.buttons.PrimaryButton // com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton // com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.feedback.ErrorView // com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.components.loading.LoadingIndicator // com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.theme.ColorPalette // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.Primary // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.Surface // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.TextPrimary // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.TextSecondary // com.amirawellness.ui.theme.Color
import com.google.accompanist.swiperefresh.SwipeRefresh // com.google.accompanist:0.30.1
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState // com.google.accompanist:0.30.1
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Main composable function that displays the user profile screen
 *
 * @param modifier Modifier
 */
@Composable
fun ProfileScreen(modifier: Modifier = Modifier) {
    // LD1: Get the ProfileViewModel instance using hiltViewModel()
    val viewModel: ProfileViewModel = hiltViewModel()

    // LD1: Collect the UI state from the ViewModel
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Create a SwipeRefresh component for pull-to-refresh functionality
    val swipeRefreshState = rememberSwipeRefreshState(isRefreshing = uiState.isLoading)

    // LD1: Implement a Scaffold with a TopAppBar showing the title "Mi perfil"
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Mi perfil") },
                backgroundColor = Primary,
                contentColor = Surface
            )
        },
        modifier = modifier
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.refreshProfile() },
            modifier = Modifier.padding(paddingValues)
        ) {
            // LD1: Display loading indicator when isLoading is true
            if (uiState.isLoading) {
                LoadingIndicator(modifier = Modifier.fillMaxSize())
            }
            // LD1: Display error view when error is not null
            else if (uiState.error != null) {
                ErrorView(
                    message = uiState.error,
                    modifier = Modifier.fillMaxSize(),
                    onAction = { viewModel.refreshProfile() },
                    actionText = "Reintentar"
                )
            }
            // LD1: Display profile content when userProfile is not null
            else if (uiState.userProfile != null) {
                ProfileContent(
                    userProfile = uiState.userProfile,
                    onSettingsClick = { viewModel.navigateToSettings() },
                    onDataExportClick = { viewModel.navigateToDataExport() },
                    onLogoutClick = { viewModel.logout() },
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                )
            }
        }
    }
}

/**
 * Composable function that displays the user profile content
 *
 * @param userProfile UserProfile
 * @param onSettingsClick Function
 * @param onDataExportClick Function
 * @param onLogoutClick Function
 * @param modifier Modifier
 */
@Composable
fun ProfileContent(
    userProfile: UserProfile,
    onSettingsClick: () -> Unit,
    onDataExportClick: () -> Unit,
    onLogoutClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to arrange profile elements vertically
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // LD1: Display profile header with user avatar and email
        ProfileHeader(userProfile = userProfile, modifier = Modifier.padding(bottom = 16.dp))

        // LD1: Display membership information (since date and subscription tier)
        MembershipInfo(userProfile = userProfile, modifier = Modifier.padding(bottom = 16.dp))

        // LD1: Display statistics section with usage counts
        StatisticsSection(userProfile = userProfile, modifier = Modifier.padding(bottom = 16.dp))

        // LD1: Display action buttons for settings, data export, and logout
        ActionButtons(
            onSettingsClick = onSettingsClick,
            onDataExportClick = onDataExportClick,
            onLogoutClick = onLogoutClick,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * Composable function that displays the user profile header with avatar and basic info
 *
 * @param userProfile UserProfile
 * @param modifier Modifier
 */
@Composable
fun ProfileHeader(userProfile: UserProfile, modifier: Modifier = Modifier) {
    // LD1: Create a Column with center alignment
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // LD1: Display circular profile picture or default avatar
        Image(
            painter = painterResource(id = R.drawable.ic_launcher_foreground), // Replace with actual image loading
            contentDescription = "Profile picture",
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(Surface)
        )

        // LD1: Display user email with appropriate styling
        Text(
            text = userProfile.user.email,
            style = MaterialTheme.typography.h6,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp)
        )

    }
}

/**
 * Composable function that displays membership information
 *
 * @param userProfile UserProfile
 * @param modifier Modifier
 */
@Composable
fun MembershipInfo(userProfile: UserProfile, modifier: Modifier = Modifier) {
    // LD1: Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Display "Miembro desde" (Member since) with formatted date
            val formattedDate = remember(userProfile.user.createdAt) {
                SimpleDateFormat("dd MMMM yyyy", Locale("es")).format(userProfile.user.createdAt)
            }
            Text(
                text = "Miembro desde: $formattedDate",
                style = MaterialTheme.typography.body1,
                color = TextPrimary
            )

            // LD1: Display subscription tier with appropriate styling
            Text(
                text = "Suscripción: ${userProfile.user.subscriptionTier}",
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
    }
}

/**
 * Composable function that displays user activity statistics
 *
 * @param userProfile UserProfile
 * @param modifier Modifier
 */
@Composable
fun StatisticsSection(userProfile: UserProfile, modifier: Modifier = Modifier) {
    // LD1: Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Display "Estadísticas" (Statistics) section title
            Text(
                text = "Estadísticas",
                style = MaterialTheme.typography.h6,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            // LD1: Create a grid layout for statistics items
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                // LD1: Display journal count with icon and label
                StatItem(
                    count = userProfile.journalCount,
                    label = "Diarios",
                    icon = Icons.Outlined.Mic,
                    modifier = Modifier.weight(1f)
                )

                // LD1: Display check-in count with icon and label
                StatItem(
                    count = userProfile.checkinCount,
                    label = "Check-ins",
                    icon = Icons.Outlined.SentimentSatisfied,
                    modifier = Modifier.weight(1f)
                )
            }

            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
            ) {
                // LD1: Display tool usage count with icon and label
                StatItem(
                    count = userProfile.toolUsageCount,
                    label = "Herramientas",
                    icon = Icons.Outlined.Build,
                    modifier = Modifier.weight(1f)
                )

                // LD1: Display streak days with icon and label
                StatItem(
                    count = userProfile.streakDays,
                    label = "Racha",
                    icon = Icons.Outlined.LocalFireDepartment,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

/**
 * Composable function that displays a single statistic item
 *
 * @param count Int
 * @param label String
 * @param icon ImageVector
 * @param modifier Modifier
 */
@Composable
fun StatItem(count: Int, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, modifier: Modifier = Modifier) {
    // LD1: Create a Column with center alignment
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // LD1: Display the icon with appropriate styling
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = Primary,
            modifier = Modifier.size(32.dp)
        )

        // LD1: Display the count with large, bold text
        Text(
            text = count.toString(),
            style = MaterialTheme.typography.h5,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        // LD1: Display the label with smaller, secondary text
        Text(
            text = label,
            style = MaterialTheme.typography.body2,
            color = TextSecondary,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Composable function that displays action buttons for the profile screen
 *
 * @param onSettingsClick Function
 * @param onDataExportClick Function
 * @param onLogoutClick Function
 * @param modifier Modifier
 */
@Composable
fun ActionButtons(
    onSettingsClick: () -> Unit,
    onDataExportClick: () -> Unit,
    onLogoutClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to arrange buttons vertically
    Column(modifier = modifier) {
        // LD1: Add "Configuración" (Settings) button using PrimaryButton
        PrimaryButton(
            text = "Configuración",
            onClick = onSettingsClick,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        // LD1: Add "Exportar mis datos" (Export my data) button using SecondaryButton
        SecondaryButton(
            text = "Exportar mis datos",
            onClick = onDataExportClick,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        // LD1: Add "Cerrar sesión" (Logout) button using SecondaryButton with warning styling
        SecondaryButton(
            text = "Cerrar sesión",
            onClick = onLogoutClick,
            modifier = Modifier.padding(bottom = 8.dp)
        )
    }
}