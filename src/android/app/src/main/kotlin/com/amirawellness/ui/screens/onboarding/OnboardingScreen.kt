package com.amirawellness.ui.screens.onboarding

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.Text
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.accompanist.pager.HorizontalPager
import com.google.accompanist.pager.rememberPagerState
import com.google.accompanist.pager.PagerState
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary

/**
 * Main composable function that displays the onboarding screen with pager and navigation controls.
 * 
 * @param viewModel The view model that manages the state and navigation for the onboarding flow
 */
@Composable
fun OnboardingScreen(
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val pagerState = rememberPagerState()
    
    // Effect to update the pager when the ViewModel state changes
    LaunchedEffect(uiState) {
        when (uiState) {
            is OnboardingState.Page1 -> pagerState.animateScrollToPage(0)
            is OnboardingState.Page2 -> pagerState.animateScrollToPage(1)
            is OnboardingState.Page3 -> pagerState.animateScrollToPage(2)
        }
    }
    
    // Effect to update the ViewModel when the pager changes
    LaunchedEffect(pagerState.currentPage) {
        when (pagerState.currentPage) {
            0 -> if (uiState !is OnboardingState.Page1) viewModel.previousPage()
            1 -> when (uiState) {
                is OnboardingState.Page1 -> viewModel.nextPage()
                is OnboardingState.Page3 -> viewModel.previousPage()
                else -> {}
            }
            2 -> if (uiState !is OnboardingState.Page3) viewModel.nextPage()
        }
    }
    
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colors.background
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Skip button at the top (only visible on first two pages)
            if (pagerState.currentPage < 2) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = Alignment.TopEnd
                ) {
                    Text(
                        text = "Skip",
                        modifier = Modifier
                            .clickable { viewModel.skipOnboarding() }
                            .padding(8.dp),
                        color = TextSecondary,
                        style = MaterialTheme.typography.button
                    )
                }
            } else {
                Spacer(modifier = Modifier.height(56.dp))
            }
            
            // Pager for onboarding content
            HorizontalPager(
                count = 3,
                state = pagerState,
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
            ) { page ->
                when (page) {
                    0 -> OnboardingPage1()
                    1 -> OnboardingPage2()
                    2 -> OnboardingPage3()
                }
            }
            
            // Page indicator
            PageIndicator(
                currentPage = pagerState.currentPage,
                pageCount = 3,
                modifier = Modifier.padding(16.dp)
            )
            
            // Navigation buttons
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Back button (not visible on first page)
                if (pagerState.currentPage > 0) {
                    SecondaryButton(
                        text = "Back",
                        onClick = { viewModel.previousPage() },
                        modifier = Modifier
                            .fillMaxWidth(0.45f)
                            .align(Alignment.CenterStart)
                    )
                }
                
                // Next button or Login/Register buttons on last page
                if (pagerState.currentPage < 2) {
                    PrimaryButton(
                        text = "Next",
                        onClick = { viewModel.nextPage() },
                        modifier = Modifier
                            .fillMaxWidth(if (pagerState.currentPage == 0) 1f else 0.45f)
                            .align(if (pagerState.currentPage == 0) Alignment.Center else Alignment.CenterEnd)
                    )
                } else {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        PrimaryButton(
                            text = "Create Account",
                            onClick = { viewModel.navigateToRegister() }
                        )
                        SecondaryButton(
                            text = "Login",
                            onClick = { viewModel.navigateToLogin() }
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays the first onboarding page content.
 */
@Composable
fun OnboardingPage1() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Illustration
        Image(
            painter = painterResource(id = android.R.drawable.ic_menu_gallery), // Placeholder - replace with actual onboarding image
            contentDescription = "Welcome Illustration",
            modifier = Modifier
                .size(240.dp)
                .padding(16.dp)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Title
        Text(
            text = "Welcome to Amira Wellness",
            style = MaterialTheme.typography.h5.copy(fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Description
        Text(
            text = "Tu espacio seguro para el bienestar emocional",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center,
            color = TextSecondary
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Your safe space for emotional wellness",
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center,
            color = TextSecondary.copy(alpha = 0.7f)
        )
    }
}

/**
 * Composable function that displays the second onboarding page content.
 */
@Composable
fun OnboardingPage2() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Illustration
        Image(
            painter = painterResource(id = android.R.drawable.ic_menu_gallery), // Placeholder - replace with actual features image
            contentDescription = "Features Illustration",
            modifier = Modifier
                .size(200.dp)
                .padding(16.dp)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Title
        Text(
            text = "Key Features",
            style = MaterialTheme.typography.h5.copy(fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Features list
        Column(
            modifier = Modifier.fillMaxWidth(0.8f),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Voice Journaling feature
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Voice Journaling",
                    style = MaterialTheme.typography.subtitle1.copy(fontWeight = FontWeight.SemiBold),
                    color = TextPrimary
                )
                Text(
                    text = "Record your thoughts with emotional check-ins",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
            
            // Emotional Check-ins feature
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Emotional Check-ins",
                    style = MaterialTheme.typography.subtitle1.copy(fontWeight = FontWeight.SemiBold),
                    color = TextPrimary
                )
                Text(
                    text = "Track and understand your emotional patterns",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
            
            // Tool Library feature
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Tool Library",
                    style = MaterialTheme.typography.subtitle1.copy(fontWeight = FontWeight.SemiBold),
                    color = TextPrimary
                )
                Text(
                    text = "Access a variety of emotional wellness tools",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
            
            // Progress Tracking feature
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Progress Tracking",
                    style = MaterialTheme.typography.subtitle1.copy(fontWeight = FontWeight.SemiBold),
                    color = TextPrimary
                )
                Text(
                    text = "Visualize your emotional wellness journey",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * Composable function that displays the third onboarding page content.
 */
@Composable
fun OnboardingPage3() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Illustration
        Image(
            painter = painterResource(id = android.R.drawable.ic_menu_gallery), // Placeholder - replace with actual privacy image
            contentDescription = "Privacy Illustration",
            modifier = Modifier
                .size(200.dp)
                .padding(16.dp)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Title
        Text(
            text = "Your Privacy Matters",
            style = MaterialTheme.typography.h5.copy(fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Description
        Text(
            text = "All your voice journals and emotional data are secured with end-to-end encryption. Only you can access your personal content.",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center,
            color = TextSecondary,
            modifier = Modifier.fillMaxWidth(0.8f)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Call to action
        Text(
            text = "Get Started",
            style = MaterialTheme.typography.h6.copy(fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center,
            color = Primary
        )
    }
}

/**
 * Composable function that displays the page indicator dots.
 * 
 * @param currentPage The current page index
 * @param pageCount The total number of pages
 * @param modifier Additional modifiers to apply to the indicator
 */
@Composable
fun PageIndicator(
    currentPage: Int,
    pageCount: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center
    ) {
        repeat(pageCount) { page ->
            val isSelected = page == currentPage
            
            Box(
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .size(if (isSelected) 10.dp else 8.dp)
                    .clip(CircleShape)
                    .background(
                        if (isSelected) Primary else Primary.copy(alpha = 0.3f)
                    )
            )
        }
    }
}

/**
 * Preview function for the OnboardingScreen composable.
 */
@Preview(showBackground = true)
@Composable
fun OnboardingPreview() {
    // In a real implementation, we would provide a mock ViewModel here
    OnboardingScreen()
}