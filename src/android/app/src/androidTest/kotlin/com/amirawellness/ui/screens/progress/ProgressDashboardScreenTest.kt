package com.amirawellness.ui.screens.progress

import androidx.compose.ui.test.junit4.createComposeRule // androidx.compose.ui:ui-test-junit4:1.5.0
import androidx.compose.ui.test.junit4.ComposeTestRule // androidx.compose.ui:ui-test-junit4:1.5.0
import androidx.compose.ui.test.onNodeWithText // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.onNodeWithTag // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.onNodeWithContentDescription // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertIsDisplayed // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertIsEnabled // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.performClick // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.performTouchInput // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.swipeDown // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertTextEquals // androidx.compose.ui:ui-test:1.5.0
import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext:junit:1.1.5
import org.junit.Rule // org.junit:junit:4.13.2
import org.junit.Test // org.junit:junit:4.13.2
import org.junit.Before // org.junit:junit:4.13.2
import org.junit.runner.RunWith // org.junit:junit:4.13.2
import org.mockito.Mockito // org.mockito:mockito-core:4.0.0
import org.mockito.Mock // org.mockito:mockito-core:4.0.0
import dagger.hilt.android.testing.HiltAndroidRule // com.google.dagger:hilt-android-testing:2.44
import dagger.hilt.android.testing.HiltAndroidTest // com.google.dagger:hilt-android-testing:2.44
import kotlinx.coroutines.flow.MutableStateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.test.runTest // org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4
import com.amirawellness.data.models.EmotionalTrend // Defined in the project
import com.amirawellness.data.models.PeriodType // Defined in the project
import com.amirawellness.data.models.StreakInfo // Defined in the project
import com.amirawellness.data.models.Achievement // Defined in the project
import com.amirawellness.data.models.AchievementCategory // Defined in the project
import com.amirawellness.data.models.EmotionalInsight // Defined in the project
import com.amirawellness.data.models.EmotionType // Defined in the project
import com.amirawellness.data.models.TrendDataPoint // Defined in the project
import com.amirawellness.ui.navigation.NavActions // Defined in the project
import com.amirawellness.domain.usecases.progress.GetStreakInfoUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetAchievementsUseCase // Defined in the project
import com.amirawellness.domain.usecases.emotional.GetEmotionalTrendsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetProgressInsightsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetUsageStatisticsUseCase // Defined in the project
import java.util.Date // JDK
import java.util.UUID // JDK
import java.time.DayOfWeek // JDK

/**
 * UI tests for the Progress Dashboard screen in the Amira Wellness Android application
 */
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class ProgressDashboardScreenTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @get:Rule
    val composeTestRule: ComposeTestRule = createComposeRule()

    @Mock
    lateinit var mockNavActions: NavActions

    @Mock
    lateinit var mockGetStreakInfoUseCase: GetStreakInfoUseCase

    @Mock
    lateinit var mockGetAchievementsUseCase: GetAchievementsUseCase

    @Mock
    lateinit var mockGetEmotionalTrendsUseCase: GetEmotionalTrendsUseCase

    @Mock
    lateinit var mockGetProgressInsightsUseCase: GetProgressInsightsUseCase

    @Mock
    lateinit var mockGetUsageStatisticsUseCase: GetUsageStatisticsUseCase

    lateinit var viewModel: ProgressDashboardViewModel

    val testStreakInfo = StreakInfo(currentStreak = 5, longestStreak = 7, totalDaysActive = 12, lastActiveDate = Date(), nextMilestone = 7, progressToNextMilestone = 5f/7f, streakHistory = emptyList())

    val testAchievements = listOf(
        Achievement(id = UUID.randomUUID().toString(), type = com.amirawellness.data.models.AchievementType.STREAK_3_DAYS, category = AchievementCategory.STREAK, title = "Racha de 3 días", description = "Usar la app durante 3 días consecutivos", iconUrl = "", points = 10, isHidden = false, earnedAt = Date(), progress = 1.0, metadata = null),
        Achievement(id = UUID.randomUUID().toString(), type = com.amirawellness.data.models.AchievementType.FIRST_JOURNAL, category = AchievementCategory.JOURNALING, title = "Primer diario", description = "Completar tu primer diario de voz", iconUrl = "", points = 5, isHidden = false, earnedAt = Date(), progress = 1.0, metadata = null),
        Achievement(id = UUID.randomUUID().toString(), type = com.amirawellness.data.models.AchievementType.STREAK_7_DAYS, category = AchievementCategory.STREAK, title = "Racha de 7 días", description = "Usar la app durante 7 días consecutivos", iconUrl = "", points = 15, isHidden = false, earnedAt = null, progress = 0.7, metadata = null)
    )

    val testEmotionalTrends = listOf(
        EmotionalTrend(emotionType = EmotionType.JOY, dataPoints = listOf(TrendDataPoint(Date(), 7, null), TrendDataPoint(Date(), 8, null)), overallTrend = com.amirawellness.data.models.TrendDirection.INCREASING, averageIntensity = 7.5, peakIntensity = 8.0, peakDate = Date(), occurrenceCount = 2),
        EmotionalTrend(emotionType = EmotionType.ANXIETY, dataPoints = listOf(TrendDataPoint(Date(), 6, null), TrendDataPoint(Date(), 4, null)), overallTrend = com.amirawellness.data.models.TrendDirection.DECREASING, averageIntensity = 5.0, peakIntensity = 6.0, peakDate = Date(), occurrenceCount = 2)
    )

    val testInsights = listOf(
        EmotionalInsight(type = "PATTERN", description = "Tu nivel de alegría tiende a ser más alto por las mañanas", relatedEmotions = listOf(EmotionType.JOY), confidence = 0.85, recommendedActions = emptyList()),
        EmotionalInsight(type = "IMPROVEMENT", description = "Tu ansiedad ha disminuido después de usar ejercicios de respiración", relatedEmotions = listOf(EmotionType.ANXIETY), confidence = 0.9, recommendedActions = emptyList())
    )

    val testUsageStatistics = mapOf(
        "totalJournalEntries" to 8,
        "totalJournalingMinutes" to 45,
        "totalCheckIns" to 15,
        "totalToolUsage" to 12,
        "activityByDay" to mapOf("MONDAY" to 3, "TUESDAY" to 2, "WEDNESDAY" to 4, "THURSDAY" to 1, "FRIDAY" to 2, "SATURDAY" to 0, "SUNDAY" to 0),
        "mostActiveTimeOfDay" to "MORNING"
    )

    @Before
    fun setUp() {
        hiltRule.inject()

        runTest {
            Mockito.`when`(mockGetStreakInfoUseCase()).thenReturn(MutableStateFlow(testStreakInfo))
            Mockito.`when`(mockGetAchievementsUseCase()).thenReturn(MutableStateFlow(testAchievements))
            Mockito.`when`(mockGetEmotionalTrendsUseCase("test_user", PeriodType.WEEK)).thenReturn(Result.success(com.amirawellness.data.models.EmotionalTrendResponse(testEmotionalTrends, testInsights)))
            Mockito.`when`(mockGetProgressInsightsUseCase()).thenReturn(MutableStateFlow(testInsights))
            Mockito.`when`(mockGetUsageStatisticsUseCase(PeriodType.WEEK)).thenReturn(MutableStateFlow(testUsageStatistics))

            viewModel = ProgressDashboardViewModel(
                mockGetStreakInfoUseCase,
                mockGetAchievementsUseCase,
                mockGetEmotionalTrendsUseCase,
                mockGetProgressInsightsUseCase,
                mockGetUsageStatisticsUseCase
            )

            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
        }
    }

    @Test
    fun testProgressDashboardInitialLoadingState() {
        runTest {
            val loadingViewModel = ProgressDashboardViewModel(
                mockGetStreakInfoUseCase,
                mockGetAchievementsUseCase,
                mockGetEmotionalTrendsUseCase,
                mockGetProgressInsightsUseCase,
                mockGetUsageStatisticsUseCase
            )
            composeTestRule.setContent {
                val uiState = MutableStateFlow<ProgressUiState>(ProgressUiState.Loading)
                ProgressDashboardScreen(viewModel = loadingViewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithTag("loadingIndicator").assertIsDisplayed()
            composeTestRule.onNodeWithText("Racha actual").assertDoesNotExist()
        }
    }

    @Test
    fun testProgressDashboardErrorState() {
        runTest {
            val errorViewModel = ProgressDashboardViewModel(
                mockGetStreakInfoUseCase,
                mockGetAchievementsUseCase,
                mockGetEmotionalTrendsUseCase,
                mockGetProgressInsightsUseCase,
                mockGetUsageStatisticsUseCase
            )
            composeTestRule.setContent {
                val uiState = MutableStateFlow<ProgressUiState>(ProgressUiState.Error("Error message"))
                ProgressDashboardScreen(viewModel = errorViewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("Error message").assertIsDisplayed()
            composeTestRule.onNodeWithText("Reintentar").assertIsDisplayed().assertIsEnabled().performClick()
            Mockito.verify(errorViewModel, Mockito.times(1)).refreshData()
        }
    }

    @Test
    fun testStreakSection() {
        composeTestRule.onNodeWithText("Racha actual").assertIsDisplayed()
        composeTestRule.onNodeWithText("5 días").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Progress Indicator").assertIsDisplayed()
        composeTestRule.onNodeWithText("Próximo logro: 7 días").assertIsDisplayed()
    }

    @Test
    fun testEmotionalTrendsSection() {
        composeTestRule.onNodeWithText("Tendencias emocionales").assertIsDisplayed()
        composeTestRule.onNodeWithText("Semana").assertIsDisplayed()
        composeTestRule.onNodeWithText("Mes").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Emotional Trend Chart").assertIsDisplayed()
        composeTestRule.onNodeWithText("Ver más").assertIsDisplayed().performClick()
        Mockito.verify(mockNavActions).navigateToEmotionalTrends()
    }

    @Test
    fun testPeriodSelection() {
        runTest {
            composeTestRule.onNodeWithText("Mes").performClick()
            Mockito.verify(viewModel).setPeriodType(PeriodType.MONTH)
        }
    }

    @Test
    fun testAchievementsSection() {
        composeTestRule.onNodeWithText("Logros").assertIsDisplayed()
        composeTestRule.onNodeWithText("Racha de 3 días").assertIsDisplayed()
        composeTestRule.onNodeWithText("Primer diario").assertIsDisplayed()
        composeTestRule.onNodeWithText("Ver todos").assertIsDisplayed().performClick()
        Mockito.verify(mockNavActions).navigateToAchievements()
    }

    @Test
    fun testActivitySection() {
        composeTestRule.onNodeWithText("Actividad semanal").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Activity Bar Chart").assertIsDisplayed()
        composeTestRule.onNodeWithText("Mañana").assertIsDisplayed()
        composeTestRule.onNodeWithText("Total de sesiones: 15").assertIsDisplayed()
    }

    @Test
    fun testInsightsSection() {
        composeTestRule.onNodeWithText("Descubrimientos").assertIsDisplayed()
        composeTestRule.onNodeWithText("Tu nivel de alegría tiende a ser más alto por las mañanas").assertIsDisplayed()
    }

    @Test
    fun testEmptyStreakSection() {
        runTest {
            Mockito.`when`(mockGetStreakInfoUseCase()).thenReturn(MutableStateFlow(null))
            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("Comienza a registrar tu progreso para ver tu racha aquí").assertIsDisplayed()
        }
    }

    @Test
    fun testEmptyEmotionalTrendsSection() {
        runTest {
            Mockito.`when`(mockGetEmotionalTrendsUseCase("test_user", PeriodType.WEEK)).thenReturn(Result.success(com.amirawellness.data.models.EmotionalTrendResponse(emptyList(), emptyList())))
            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("No hay datos emocionales disponibles.").assertIsDisplayed()
        }
    }

    @Test
    fun testEmptyAchievementsSection() {
        runTest {
            Mockito.`when`(mockGetAchievementsUseCase()).thenReturn(MutableStateFlow(emptyList()))
            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("No hay logros disponibles.").assertIsDisplayed()
        }
    }

    @Test
    fun testEmptyActivitySection() {
        runTest {
            Mockito.`when`(mockGetUsageStatisticsUseCase(PeriodType.WEEK)).thenReturn(MutableStateFlow(emptyMap()))
            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("No hay datos de actividad disponibles.").assertIsDisplayed()
        }
    }

    @Test
    fun testEmptyInsightsSection() {
        runTest {
            Mockito.`when`(mockGetEmotionalTrendsUseCase("test_user", PeriodType.WEEK)).thenReturn(Result.success(com.amirawellness.data.models.EmotionalTrendResponse(emptyList(), emptyList())))
            composeTestRule.setContent {
                ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
            }
            composeTestRule.onNodeWithText("No hay descubrimientos disponibles.").assertIsDisplayed()
        }
    }

    @Test
    fun testPullToRefresh() {
        runTest {
            composeTestRule.performTouchInput {
                swipeDown()
            }
            Mockito.verify(viewModel).refreshData()
        }
    }

    @Test
    fun testNavigationToEmotionalTrends() {
        composeTestRule.onNodeWithText("Ver más").performClick()
        Mockito.verify(mockNavActions).navigateToEmotionalTrends()
    }

    @Test
    fun testNavigationToAchievements() {
        composeTestRule.onNodeWithText("Ver todos").performClick()
        Mockito.verify(mockNavActions).navigateToAchievements()
    }

    private fun setupTestData(): ProgressData {
        return ProgressData(
            streakInfo = testStreakInfo,
            achievements = testAchievements,
            emotionalTrends = testEmotionalTrends,
            insights = testInsights,
            usageStatistics = testUsageStatistics
        )
    }

    private fun setupViewModel() {
        runTest {
            Mockito.`when`(mockGetStreakInfoUseCase()).thenReturn(MutableStateFlow(testStreakInfo))
            Mockito.`when`(mockGetAchievementsUseCase()).thenReturn(MutableStateFlow(testAchievements))
            Mockito.`when`(mockGetEmotionalTrendsUseCase("test_user", PeriodType.WEEK)).thenReturn(Result.success(com.amirawellness.data.models.EmotionalTrendResponse(testEmotionalTrends, testInsights)))
            Mockito.`when`(mockGetProgressInsightsUseCase()).thenReturn(MutableStateFlow(testInsights))
            Mockito.`when`(mockGetUsageStatisticsUseCase(PeriodType.WEEK)).thenReturn(MutableStateFlow(testUsageStatistics))
            viewModel = ProgressDashboardViewModel(
                mockGetStreakInfoUseCase,
                mockGetAchievementsUseCase,
                mockGetEmotionalTrendsUseCase,
                mockGetProgressInsightsUseCase,
                mockGetUsageStatisticsUseCase
            )
        }
    }

    private fun setupComposeTestRule() {
        composeTestRule.setContent {
            ProgressDashboardScreen(viewModel = viewModel, navActions = mockNavActions)
        }
    }
}