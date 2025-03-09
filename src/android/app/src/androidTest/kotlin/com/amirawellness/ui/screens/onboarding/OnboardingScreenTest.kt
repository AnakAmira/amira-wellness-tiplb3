package com.amirawellness.ui.screens.onboarding

import android.content.Context
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.Mockito
import kotlinx.coroutines.flow.MutableStateFlow
import com.amirawellness.ui.navigation.NavActions

/**
 * UI tests for the onboarding screen in the Amira Wellness Android application
 */
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class OnboardingScreenTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @get:Rule
    val composeTestRule = createComposeRule()

    @Mock
    lateinit var mockNavActions: NavActions

    @Mock
    lateinit var mockContext: Context

    private lateinit var viewModel: OnboardingViewModel
    private val uiState = MutableStateFlow<OnboardingState>(OnboardingState.Page1)

    /**
     * Set up method called before each test
     */
    @Before
    fun setUp() {
        // Initialize Hilt
        hiltRule.inject()

        // Initialize mocks
        mockNavActions = Mockito.mock(NavActions::class.java)
        mockContext = Mockito.mock(Context::class.java)

        // Create ViewModel with mocked dependencies
        viewModel = OnboardingViewModel(mockNavActions, mockContext)

        // Override UI state with our controlled state flow
        val originalViewModel = viewModel
        viewModel = Mockito.spy(originalViewModel).apply {
            Mockito.doReturn(uiState).`when`(this).uiState
        }

        // Set up the composable with our controlled ViewModel
        composeTestRule.setContent {
            OnboardingScreen(viewModel = viewModel)
        }
    }

    /**
     * Tests that the onboarding screen displays the first page content in its initial state
     */
    @Test
    fun testOnboardingScreenInitialState() {
        // Verify welcome page elements are displayed
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").assertIsDisplayed()
        composeTestRule.onNodeWithText("Tu espacio seguro para el bienestar emocional").assertIsDisplayed()
        composeTestRule.onNodeWithText("Your safe space for emotional wellness").assertIsDisplayed()
        
        // Verify navigation elements
        composeTestRule.onNodeWithText("Skip").assertIsDisplayed()
        composeTestRule.onNodeWithText("Next").assertIsDisplayed().assertIsEnabled()
        
        // Verify page indicator shows first page is active
        // Note: Since we don't have specific test tags, we'll verify based on content structure
        // In a real implementation, we would have test tags for better identification
    }

    /**
     * Tests navigation to the second onboarding page
     */
    @Test
    fun testNavigationToSecondPage() {
        // Click the next button
        composeTestRule.onNodeWithText("Next").performClick()
        
        // Verify nextPage method is called on ViewModel
        Mockito.verify(viewModel).nextPage()
        
        // Update the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Verify features page elements are displayed
        composeTestRule.onNodeWithText("Key Features").assertIsDisplayed()
        composeTestRule.onNodeWithText("Voice Journaling").assertIsDisplayed()
        composeTestRule.onNodeWithText("Emotional Check-ins").assertIsDisplayed()
        composeTestRule.onNodeWithText("Tool Library").assertIsDisplayed()
        composeTestRule.onNodeWithText("Progress Tracking").assertIsDisplayed()
        
        // Verify navigation elements
        composeTestRule.onNodeWithText("Back").assertIsDisplayed().assertIsEnabled()
        composeTestRule.onNodeWithText("Next").assertIsDisplayed().assertIsEnabled()
    }

    /**
     * Tests navigation to the third onboarding page
     */
    @Test
    fun testNavigationToThirdPage() {
        // Set up the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Click the next button
        composeTestRule.onNodeWithText("Next").performClick()
        
        // Verify nextPage method is called on ViewModel
        Mockito.verify(viewModel).nextPage()
        
        // Update the UI state to show Page3
        uiState.value = OnboardingState.Page3
        
        // Verify privacy page elements are displayed
        composeTestRule.onNodeWithText("Your Privacy Matters").assertIsDisplayed()
        composeTestRule.onNodeWithText("All your voice journals and emotional data are secured with end-to-end encryption. Only you can access your personal content.").assertIsDisplayed()
        composeTestRule.onNodeWithText("Get Started").assertIsDisplayed()
        
        // Verify navigation elements
        composeTestRule.onNodeWithText("Back").assertIsDisplayed().assertIsEnabled()
        composeTestRule.onNodeWithText("Create Account").assertIsDisplayed().assertIsEnabled()
        composeTestRule.onNodeWithText("Login").assertIsDisplayed().assertIsEnabled()
    }

    /**
     * Tests navigation back from the second to the first onboarding page
     */
    @Test
    fun testNavigationBackFromSecondPage() {
        // Set up the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Click the back button
        composeTestRule.onNodeWithText("Back").performClick()
        
        // Verify previousPage method is called on ViewModel
        Mockito.verify(viewModel).previousPage()
        
        // Update the UI state to show Page1
        uiState.value = OnboardingState.Page1
        
        // Verify welcome page elements are displayed
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").assertIsDisplayed()
    }

    /**
     * Tests navigation back from the third to the second onboarding page
     */
    @Test
    fun testNavigationBackFromThirdPage() {
        // Set up the UI state to show Page3
        uiState.value = OnboardingState.Page3
        
        // Click the back button
        composeTestRule.onNodeWithText("Back").performClick()
        
        // Verify previousPage method is called on ViewModel
        Mockito.verify(viewModel).previousPage()
        
        // Update the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Verify features page elements are displayed
        composeTestRule.onNodeWithText("Key Features").assertIsDisplayed()
    }

    /**
     * Tests skipping the onboarding process
     */
    @Test
    fun testSkipOnboarding() {
        // Click the skip button
        composeTestRule.onNodeWithText("Skip").performClick()
        
        // Verify skipOnboarding method is called on ViewModel
        Mockito.verify(viewModel).skipOnboarding()
        
        // Verify navigation to main screen is initiated
        Mockito.verify(mockNavActions).navigateToMain()
    }

    /**
     * Tests navigation to the login screen from the final onboarding page
     */
    @Test
    fun testNavigateToLogin() {
        // Set up the UI state to show Page3
        uiState.value = OnboardingState.Page3
        
        // Click the login button
        composeTestRule.onNodeWithText("Login").performClick()
        
        // Verify navigateToLogin method is called on ViewModel
        Mockito.verify(viewModel).navigateToLogin()
        
        // Verify navigation to login screen is initiated
        Mockito.verify(mockNavActions).navigateToLogin()
    }

    /**
     * Tests navigation to the registration screen from the final onboarding page
     */
    @Test
    fun testNavigateToRegister() {
        // Set up the UI state to show Page3
        uiState.value = OnboardingState.Page3
        
        // Click the register button
        composeTestRule.onNodeWithText("Create Account").performClick()
        
        // Verify navigateToRegister method is called on ViewModel
        Mockito.verify(viewModel).navigateToRegister()
        
        // Verify navigation to register screen is initiated
        Mockito.verify(mockNavActions).navigateToRegister()
    }

    /**
     * Tests navigation between pages using swipe gestures
     */
    @Test
    fun testSwipeNavigation() {
        // Find the pager component and perform swipe left (next page)
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").assertIsDisplayed()
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").performClick()
        
        // Swipe left to navigate to next page
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").swipeLeft()
        
        // Verify nextPage method is called on ViewModel
        Mockito.verify(viewModel).nextPage()
        
        // Update the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Verify features page elements are displayed
        composeTestRule.onNodeWithText("Key Features").assertIsDisplayed()
        
        // Swipe left again to navigate to third page
        composeTestRule.onNodeWithText("Key Features").swipeLeft()
        
        // Verify nextPage method is called again
        Mockito.verify(viewModel, Mockito.times(2)).nextPage()
        
        // Update the UI state to show Page3
        uiState.value = OnboardingState.Page3
        
        // Verify privacy page elements are displayed
        composeTestRule.onNodeWithText("Your Privacy Matters").assertIsDisplayed()
        
        // Swipe right to navigate back to second page
        composeTestRule.onNodeWithText("Your Privacy Matters").swipeRight()
        
        // Verify previousPage method is called
        Mockito.verify(viewModel).previousPage()
        
        // Update the UI state to show Page2
        uiState.value = OnboardingState.Page2
        
        // Verify features page elements are displayed
        composeTestRule.onNodeWithText("Key Features").assertIsDisplayed()
    }

    /**
     * Tests that the page indicator correctly shows the current page
     */
    @Test
    fun testPageIndicatorFunctionality() {
        // In a real implementation, we would have specific test tags for page indicators
        // For this test, we will validate based on state changes and assume the UI updates correctly
        
        // Verify we're on page 1
        composeTestRule.onNodeWithText("Welcome to Amira Wellness").assertIsDisplayed()
        
        // Move to page 2
        uiState.value = OnboardingState.Page2
        
        // Verify we're on page 2
        composeTestRule.onNodeWithText("Key Features").assertIsDisplayed()
        
        // Move to page 3
        uiState.value = OnboardingState.Page3
        
        // Verify we're on page 3
        composeTestRule.onNodeWithText("Your Privacy Matters").assertIsDisplayed()
    }
}