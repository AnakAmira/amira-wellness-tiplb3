package com.amirawellness.di

import androidx.navigation.NavController // androidx.navigation:navigation-runtime-ktx:2.5.3
import org.koin.androidx.viewmodel.dsl.viewModel // org.koin:koin-androidx-viewmodel:3.3.0
import org.koin.androidx.viewmodel.dsl.viewModelOf // org.koin:koin-androidx-viewmodel:3.3.0
import org.koin.core.module.Module // org.koin:koin-core:3.3.0
import org.koin.core.parameter.parametersOf // org.koin:koin-core:3.3.0
import org.koin.dsl.module // org.koin:koin-core:3.3.0
import com.amirawellness.ui.screens.home.HomeViewModel // internal
import com.amirawellness.ui.screens.auth.LoginViewModel // internal
import com.amirawellness.ui.screens.auth.RegisterViewModel // internal
import com.amirawellness.ui.screens.auth.ForgotPasswordViewModel // internal
import com.amirawellness.ui.screens.onboarding.OnboardingViewModel // internal
import com.amirawellness.ui.screens.journal.JournalListViewModel // internal
import com.amirawellness.ui.screens.journal.JournalDetailViewModel // internal
import com.amirawellness.ui.screens.journal.RecordJournalViewModel // internal
import com.amirawellness.ui.screens.emotions.EmotionalCheckinViewModel // internal
import com.amirawellness.ui.screens.emotions.EmotionalCheckinResultViewModel // internal
import com.amirawellness.ui.screens.tools.ToolLibraryViewModel // internal
import com.amirawellness.ui.screens.tools.ToolCategoryViewModel // internal
import com.amirawellness.ui.screens.tools.ToolDetailViewModel // internal
import com.amirawellness.ui.screens.tools.ToolInProgressViewModel // internal
import com.amirawellness.ui.screens.tools.ToolCompletionViewModel // internal
import com.amirawellness.ui.screens.tools.FavoritesViewModel // internal
import com.amirawellness.ui.screens.progress.ProgressDashboardViewModel // internal
import com.amirawellness.ui.screens.progress.AchievementsViewModel // internal
import com.amirawellness.ui.screens.progress.EmotionalTrendsViewModel // internal
import com.amirawellness.ui.screens.profile.ProfileViewModel // internal
import com.amirawellness.ui.screens.settings.SettingsViewModel // internal
import com.amirawellness.ui.screens.settings.NotificationSettingsViewModel // internal
import com.amirawellness.ui.screens.settings.PrivacySettingsViewModel // internal
import com.amirawellness.ui.screens.settings.DataExportViewModel // internal
import com.amirawellness.ui.navigation.NavActions // internal
import com.amirawellness.core.utils.LogUtils // internal

/**
 * Koin module that provides ViewModel dependencies
 */
val viewModelModule: Module = module {

    // Provides a NavActions instance for navigation between screens
    fun provideNavActions(navController: NavController): NavActions {
        LogUtils.logDebug("ViewModelModule", "Creating NavActions instance")
        return NavActions(navController)
    }

    // ViewModel for the Home screen
    viewModel { HomeViewModel(get(), get(), get(), get(), get()) }

    // ViewModel for the Login screen
    viewModel { LoginViewModel(get(), get()) }

    // ViewModel for the Register screen
    viewModel { RegisterViewModel(get(), get()) }

    // ViewModel for the Forgot Password screen
    viewModel { ForgotPasswordViewModel(get(), get()) }

    // ViewModel for the Onboarding screen
    viewModel { OnboardingViewModel(get(), androidContext()) }

    // ViewModel for the Journal List screen
    viewModel { JournalListViewModel(get(), get(), get()) }

    // ViewModel for the Journal Detail screen
    viewModel { JournalDetailViewModel(get(), get()) }

    // ViewModel for the Record Journal screen
    viewModel { RecordJournalViewModel(androidContext(), get(), get(), get()) }

    // ViewModel for the Emotional Check-in screen
    viewModel { EmotionalCheckinViewModel(get(), get()) }

    // ViewModel for the Emotional Check-in Result screen
    viewModel { EmotionalCheckinResultViewModel(get(), get()) }

    // ViewModel for the Tool Library screen
    viewModel { ToolLibraryViewModel(get(), get(), get(), get(), get()) }

    // ViewModel for the Tool Category screen
    viewModel { ToolCategoryViewModel(get(), get(), get(), get()) }

    // ViewModel for the Tool Detail screen
    viewModel { ToolDetailViewModel(get(), get(), get()) }

    // ViewModel for the Tool In Progress screen
    viewModel { ToolInProgressViewModel(get(), get(), get()) }

    // ViewModel for the Tool Completion screen
    viewModel { ToolCompletionViewModel(get(), get(), get(), get(), get()) }

    // ViewModel for the Favorites screen
    viewModel { FavoritesViewModel(get(), get(), get(), get()) }

    // ViewModel for the Progress Dashboard screen
    viewModel { ProgressDashboardViewModel(get(), get(), get(), get(), get()) }

    // ViewModel for the Achievements screen
    viewModel { AchievementsViewModel(get()) }

    // ViewModel for the Emotional Trends screen
    viewModel { EmotionalTrendsViewModel(get()) }

    // ViewModel for the Profile screen
    viewModel { ProfileViewModel(get(), get(), get()) }

    // ViewModel for the Settings screen
    viewModel { SettingsViewModel(androidContext(), get()) }

    // ViewModel for the Notification Settings screen
    viewModel { NotificationSettingsViewModel(androidContext(), get()) }

    // ViewModel for the Privacy Settings screen
    viewModel { PrivacySettingsViewModel(androidContext(), get(), get()) }

    // ViewModel for the Data Export screen
    viewModel { DataExportViewModel(androidContext(), get(), get(), get(), get()) }

    // Provide NavActions instance
    factory { (navController: NavController) ->
        provideNavActions(navController = navController)
    }
}