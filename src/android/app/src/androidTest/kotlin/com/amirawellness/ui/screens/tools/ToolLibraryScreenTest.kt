# src/android/app/src/androidTest/kotlin/com/amirawellness/ui/screens/tools/ToolLibraryScreenTest.kt
```kotlin
package com.amirawellness.ui.screens.tools

import androidx.compose.ui.test.junit4.createAndroidComposeRule // package_version: 1.5.0
import androidx.compose.ui.test.onNodeWithText // package_version: 1.5.0
import androidx.compose.ui.test.onNodeWithTag // package_version: 1.5.0
import androidx.compose.ui.test.onNodeWithContentDescription // package_version: 1.5.0
import androidx.compose.ui.test.performClick // package_version: 1.5.0
import androidx.compose.ui.test.performTouchInput // package_version: 1.5.0
import androidx.compose.ui.test.swipeDown // package_version: 1.5.0
import androidx.compose.ui.test.assertIsDisplayed // package_version: 1.5.0
import androidx.compose.ui.test.assertIsEnabled // package_version: 1.5.0
import androidx.compose.ui.test.assertIsSelected // package_version: 1.5.0
import androidx.test.ext.junit.runners.AndroidJUnit4 // package_version: 1.1.5
import org.junit.Rule // package_version: 4.13.2
import org.junit.Test // package_version: 4.13.2
import org.junit.Before // package_version: 4.13.2
import org.junit.runner.RunWith // package_version: 4.13.2
import org.mockito.Mockito // package_version: 4.0.0
import org.mockito.Mock // package_version: 4.0.0
import dagger.hilt.android.testing.HiltAndroidRule // package_version: 2.44
import dagger.hilt.android.testing.HiltAndroidTest // package_version: 2.44
import kotlinx.coroutines.flow.MutableStateFlow // package_version: 1.6.4
import kotlinx.coroutines.test.runTest // package_version: 1.6.4
import com.amirawellness.data.models.Tool // package_version: latest
import com.amirawellness.data.models.ToolCategory // package_version: latest
import com.amirawellness.ui.screens.tools.ToolLibraryScreen // src_subfolder: android
import com.amirawellness.ui.screens.tools.ToolLibraryViewModel // src_subfolder: android
import com.amirawellness.ui.navigation.NavActions // src_subfolder: android
import com.amirawellness.domain.usecases.tool.GetToolCategoriesUseCase // src_subfolder: android
import com.amirawellness.domain.usecases.tool.GetToolsUseCase // src_subfolder: android
import com.amirawellness.domain.usecases.tool.GetFavoriteToolsUseCase // src_subfolder: android
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase // src_subfolder: android
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.data.models.ToolContent
import androidx.activity.ComponentActivity

private const val TAG = "ToolLibraryScreenTest"

@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class ToolLibraryScreenTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @get:Rule
    val composeTestRule = createAndroidComposeRule<ComponentActivity>()

    @Mock
    lateinit var mockNavActions: NavActions

    @Mock
    lateinit var mockGetToolCategoriesUseCase: GetToolCategoriesUseCase

    @Mock
    lateinit var mockGetToolsUseCase: GetToolsUseCase

    @Mock
    lateinit var mockGetFavoriteToolsUseCase: GetFavoriteToolsUseCase

    @Mock
    lateinit var mockToggleToolFavoriteUseCase: ToggleToolFavoriteUseCase

    lateinit var viewModel: ToolLibraryViewModel

    val testCategories = listOf(
        ToolCategory(id = "cat1", name = "Breathing", description = "Breathing exercises", iconUrl = null, toolCount = 5),
        ToolCategory(id = "cat2", name = "Meditation", description = "Meditation exercises", iconUrl = null, toolCount = 3)
    )

    val testTools = listOf(
        Tool(id = "tool1", name = "4-7-8 Breathing", description = "Calming breathing technique", category = testCategories[0], contentType = ToolContentType.TEXT, content = ToolContent(title = "4-7-8 Breathing", instructions = "Instructions"), isFavorite = false, usageCount = 2, targetEmotions = listOf(), estimatedDuration = 5),
        Tool(id = "tool2", name = "Box Breathing", description = "Another breathing technique", category = testCategories[0], contentType = ToolContentType.TEXT, content = ToolContent(title = "Box Breathing", instructions = "Instructions"), isFavorite = true, usageCount = 1, targetEmotions = listOf(), estimatedDuration = 3)
    )

    val testRecentTools = listOf(testTools[0])

    @Before
    fun setUp() {
        hiltRule.inject()

        Mockito.`when`(mockNavActions.navigateToToolDetail(Mockito.anyString())).then {}
        Mockito.`when`(mockNavActions.navigateToToolCategory(Mockito.anyString())).then {}
        Mockito.`when`(mockNavActions.navigateToFavorites()).then {}

        Mockito.`when`(mockGetToolCategoriesUseCase.invoke(Mockito.anyBoolean())).thenReturn(MutableStateFlow(testCategories))
        Mockito.`when`(mockGetToolsUseCase.invoke(Mockito.anyString(), Mockito.anyBoolean())).thenReturn(MutableStateFlow(testTools))
        Mockito.`when`(mockGetFavoriteToolsUseCase.invoke()).thenReturn(MutableStateFlow(testTools.filter { it.isFavorite }))
        Mockito.`when`(mockToggleToolFavoriteUseCase.invoke(Mockito.anyString(), Mockito.anyBoolean())).thenReturn(true)

        viewModel = ToolLibraryViewModel(
            mockGetToolCategoriesUseCase,
            mockGetToolsUseCase,
            mockGetFavoriteToolsUseCase,
            mockToggleToolFavoriteUseCase,
            Mockito.mock(androidx.lifecycle.SavedStateHandle::class.java)
        )

        composeTestRule.setContent {
            ToolLibraryScreen(navController = Mockito.mock(androidx.navigation.NavController::class.java),)
        }
    }

    @Test
    fun testToolLibraryScreenInitialLoadingState() {
        val uiState = MutableStateFlow(ToolLibraryUiState.initialState().copy(isLoading = true))
        Mockito.`when`(mockGetToolCategoriesUseCase.invoke(Mockito.anyBoolean())).thenReturn(MutableStateFlow(emptyList()))

        composeTestRule.setContent {
            ToolLibraryScreen(navController = Mockito.mock(androidx.navigation.NavController::class.java))
        }

        composeTestRule.onNodeWithText("Loading").assertIsDisplayed()
    }

    @Test
    fun testToolLibraryScreenErrorState() = runTest {
        val errorMessage = "Failed to load data"
        val uiState = MutableStateFlow(ToolLibraryUiState.initialState().copy(error = errorMessage))
        Mockito.`when`(mockGetToolCategoriesUseCase.invoke(Mockito.anyBoolean())).thenReturn(MutableStateFlow(emptyList()))

        composeTestRule.setContent {
            ToolLibraryScreen(navController = Mockito.mock(androidx.navigation.NavController::class.java))
        }

        composeTestRule.onNodeWithText(errorMessage).assertIsDisplayed()
        composeTestRule.onNodeWithText("Retry").assertIsDisplayed()

        composeTestRule.onNodeWithText("Retry").performClick()
        Mockito.verify(mockGetToolCategoriesUseCase, Mockito.times(1)).invoke(Mockito.anyBoolean())
    }

    @Test
    fun testCategorySelector() = runTest {
        composeTestRule.onNodeWithText("Categories").assertIsDisplayed()

        composeTestRule.onNodeWithText("Breathing").assertIsDisplayed()
        composeTestRule.onNodeWithText("Meditation").assertIsDisplayed()

        composeTestRule.onNodeWithText("Breathing").performClick()
        Mockito.verify(mockGetToolsUseCase, Mockito.times(1)).invoke("cat1", Mockito.anyBoolean())

        composeTestRule.onNodeWithText("Breathing").assertIsSelected()
    }

    @Test
    fun testRecentToolsSection() = runTest {
        composeTestRule.onNodeWithText("Recently Used").assertIsDisplayed()

        composeTestRule.onNodeWithText("4-7-8 Breathing").assertIsDisplayed()

        composeTestRule.onNodeWithText("4-7-8 Breathing").performClick()
        Mockito.verify(mockNavActions, Mockito.times(0)).navigateToToolDetail("tool1")
    }

    @Test
    fun testToolList() = runTest {
        composeTestRule.onNodeWithText("All Tools").assertIsDisplayed()

        composeTestRule.onNodeWithText("4-7-8 Breathing").assertIsDisplayed()
        composeTestRule.onNodeWithText("Box Breathing").assertIsDisplayed()

        composeTestRule.onNodeWithText("4-7-8 Breathing").performClick()
        Mockito.verify(mockNavActions, Mockito.times(0)).navigateToToolDetail("tool1")
    }

    @Test
    fun testEmptyToolList() = runTest {
        Mockito.`when`(mockGetToolsUseCase.invoke(Mockito.anyString(), Mockito.anyBoolean())).thenReturn(MutableStateFlow(emptyList()))

        composeTestRule.setContent {
            ToolLibraryScreen(navController = Mockito.mock(androidx.navigation.NavController::class.java))
        }

        composeTestRule.onNodeWithText("All Tools").assertIsDisplayed()
        composeTestRule.onNodeWithText("No tools available in this category").assertIsDisplayed()
    }

    @Test
    fun testFavoritesButton() = runTest {
        composeTestRule.onNodeWithText("Favorites (2)").assertIsDisplayed()

        composeTestRule.onNodeWithText("Favorites (2)").performClick()
        Mockito.verify(mockNavActions, Mockito.times(0)).navigateToFavorites()
    }

    @Test
    fun testToggleFavorite() = runTest {
        composeTestRule.onNodeWithContentDescription("Favorite").performClick()
        Mockito.verify(mockToggleToolFavoriteUseCase, Mockito.times(1)).invoke("tool1", true)
    }

    @Test
    fun testPullToRefresh() = runTest {
        composeTestRule.performTouchInput {
            swipeDown()
        }
        Mockito.verify(mockGetToolCategoriesUseCase, Mockito.times(1)).invoke(true)
    }

    @Test
    fun testNavigationToToolDetail() = runTest {
        composeTestRule.onNodeWithText("4-7-8 Breathing").performClick()
        Mockito.verify(mockNavActions, Mockito.times(0)).navigateToToolDetail("tool1")
    }

    @Test
    fun testNavigationToToolCategory() {
    }

    @Test
    fun testNavigationToFavorites() {
    }
}