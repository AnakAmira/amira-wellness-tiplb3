package com.amirawellness.ui.screens.tools

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.rememberCoroutineScope // version: 1.5.0
import androidx.compose.foundation.layout.* // version: 1.5.0
import androidx.compose.foundation.lazy.LazyRow // version: 1.5.0
import androidx.compose.foundation.lazy.LazyColumn // version: 1.5.0
import androidx.compose.foundation.lazy.items // version: 1.5.0
import androidx.compose.material.* // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.* // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.draw.clip // version: 1.5.0
import androidx.compose.ui.graphics.Color // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.text.style.TextOverflow // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.NavController // version: 2.7.0
import androidx.navigation.compose.rememberNavController // version: 2.7.0
import com.google.accompanist.swiperefresh.SwipeRefresh // version: 0.30.1
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState // version: 0.30.1

import com.amirawellness.data.models.Tool // Data model for emotional regulation tools
import com.amirawellness.data.models.ToolCategory // Data model for tool categories
import com.amirawellness.ui.components.cards.ToolCard // Reusable card component for displaying tools
import com.amirawellness.ui.components.buttons.PrimaryButton // Reusable primary button component
import com.amirawellness.ui.components.buttons.IconButton // Reusable icon button component
import com.amirawellness.ui.components.loading.LoadingIndicator // Loading indicator for loading states
import com.amirawellness.ui.components.loading.FullScreenLoading // Full-screen loading overlay
import com.amirawellness.ui.components.feedback.ErrorView // Error state display component
import com.amirawellness.ui.components.feedback.EmptyStateView // Empty state display component
import com.amirawellness.ui.navigation.NavActions // Navigation actions for screen transitions
import com.amirawellness.ui.theme.Primary // Color definitions for UI elements
import com.amirawellness.ui.theme.Secondary // Color definitions for UI elements
import com.amirawellness.ui.theme.Surface // Color definitions for UI elements
import com.amirawellness.ui.theme.TextPrimary // Color definitions for UI elements
import com.amirawellness.ui.theme.TextSecondary // Color definitions for UI elements
import kotlinx.coroutines.launch // Coroutine support

/**
 * Main composable function for the Tool Library screen that displays categories, tools, and handles user interactions
 *
 * @param navController Navigation controller for screen transitions
 * @param modifier Modifier to apply styling and layout
 */
@Composable
fun ToolLibraryScreen(
    navController: NavController = rememberNavController(),
    modifier: Modifier = Modifier
) {
    // LD1: Get ViewModel instance using hiltViewModel()
    val viewModel: ToolLibraryViewModel = hiltViewModel()

    // LD1: Create NavActions instance with navController
    val navActions = remember(navController) { NavActions(navController) }

    // LD1: Collect uiState from viewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Create coroutine scope for handling side effects
    val coroutineScope = rememberCoroutineScope()

    // LD1: Check if navigation to favorites is requested and handle it
    if (uiState.navigateToFavorites) {
        // Navigate to favorites and reset the flag
        navActions.navigateToFavorites()
        viewModel.onFavoritesClicked() // Reset the flag in ViewModel
    }

    // LD1: Create SwipeRefresh component for pull-to-refresh functionality
    SwipeRefresh(
        state = rememberSwipeRefreshState(isRefreshing = uiState.isRefreshing),
        onRefresh = { viewModel.refresh() },
    ) {
        // LD1: Create Scaffold with TopAppBar and content
        Scaffold(
            topBar = {
                ToolLibraryTopBar(
                    favoriteCount = uiState.favoriteCount,
                    onFavoritesClicked = {
                        viewModel.onFavoritesClicked()
                    }
                )
            },
            modifier = modifier.fillMaxSize()
        ) { paddingValues ->
            // LD1: Display loading indicator when isLoading is true
            if (uiState.isLoading) {
                FullScreenLoading(isLoading = true, modifier = Modifier.padding(paddingValues)) {
                    // This content is only visible when not loading
                }
            }
            // LD1: Display error view when error is not null
            else if (uiState.error != null) {
                ErrorView(
                    message = "Error: ${uiState.error}",
                    onAction = { viewModel.clearError() },
                    actionText = "Retry",
                    modifier = Modifier.padding(paddingValues)
                )
            }
            // LD1: Display main content when data is loaded
            else {
                ToolLibraryContent(
                    uiState = uiState,
                    onCategorySelected = { categoryId ->
                        viewModel.onCategorySelected(categoryId)
                    },
                    onToolSelected = { toolId ->
                        viewModel.onToolSelected(toolId)
                        // LD1: Handle navigation to tool detail when a tool is selected
                        navActions.navigateToToolDetail(toolId)
                    },
                    onFavoriteClick = { toolId ->
                        viewModel.toggleFavorite(toolId)
                    },
                    onFavoritesClicked = {
                        viewModel.onFavoritesClicked()
                    },
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}

/**
 * Composable function that displays the main content of the Tool Library screen
 *
 * @param uiState The UI state for the Tool Library screen
 * @param onCategorySelected Callback invoked when a category is selected
 * @param onToolSelected Callback invoked when a tool is selected
 * @param onFavoriteClick Callback invoked when the favorite button is clicked
 * @param onFavoritesClicked Callback invoked when the favorites button is clicked
 * @param modifier Modifier to apply styling and layout
 */
@Composable
private fun ToolLibraryContent(
    uiState: ToolLibraryUiState,
    onCategorySelected: (String) -> Unit,
    onToolSelected: (String) -> Unit,
    onFavoriteClick: (String) -> Unit,
    onFavoritesClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to contain all content
    Column(
        modifier = modifier.fillMaxSize()
    ) {
        // LD1: Display CategorySelector at the top
        CategorySelector(
            categories = uiState.categories,
            selectedCategoryId = uiState.selectedCategoryId,
            onCategorySelected = onCategorySelected,
            modifier = Modifier.padding(vertical = 8.dp)
        )

        // LD1: Display RecentToolsSection if there are recent tools
        if (uiState.recentTools.isNotEmpty()) {
            RecentToolsSection(
                recentTools = uiState.recentTools,
                onToolSelected = onToolSelected,
                onFavoriteClick = onFavoriteClick,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // LD1: Display ToolList for the selected category
        if (uiState.tools.isNotEmpty()) {
            ToolList(
                tools = uiState.tools,
                onToolSelected = onToolSelected,
                onFavoriteClick = onFavoriteClick,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }
        // LD1: Display EmptyStateView if there are no tools in the selected category
        else {
            EmptyStateView(
                message = "No tools available in this category",
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

/**
 * Composable function that displays a horizontal scrollable list of tool categories
 *
 * @param categories List of tool categories to display
 * @param selectedCategoryId ID of the currently selected category
 * @param onCategorySelected Callback invoked when a category is selected
 * @param modifier Modifier to apply styling and layout
 */
@Composable
private fun CategorySelector(
    categories: List<ToolCategory>,
    selectedCategoryId: String?,
    onCategorySelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card to contain the category selector
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        elevation = 2.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add a title "Categories" above the list
            Text(
                text = "Categories",
                style = MaterialTheme.typography.h6,
                color = TextPrimary,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            // LD1: Create a LazyRow for horizontal scrolling
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // LD1: For each category, create a selectable chip/button
                items(categories) { category ->
                    // LD1: Highlight the selected category with different styling
                    val isSelected = category.id == selectedCategoryId
                    Button(
                        onClick = {
                            // LD1: Handle click events to call onCategorySelected with category ID
                            onCategorySelected(category.id)
                        },
                        modifier = Modifier,
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = if (isSelected) Primary else Surface,
                            contentColor = if (isSelected) TextPrimary else TextSecondary
                        ),
                        shape = MaterialTheme.shapes.small
                    ) {
                        // LD1: Display category name and icon if available
                        Text(
                            text = category.name,
                            style = MaterialTheme.typography.body2,
                            color = if (isSelected) TextPrimary else TextSecondary
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays a section with recently used tools
 *
 * @param recentTools List of recently used tools to display
 * @param onToolSelected Callback invoked when a tool is selected
 * @param onFavoriteClick Callback invoked when the favorite button is clicked
 * @param modifier Modifier to apply styling and layout
 */
@Composable
private fun RecentToolsSection(
    recentTools: List<Tool>,
    onToolSelected: (String) -> Unit,
    onFavoriteClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to contain the section
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        // LD1: Add a title "Recently Used" with a subtitle
        Text(
            text = "Recently Used",
            style = MaterialTheme.typography.h6,
            color = TextPrimary,
            modifier = Modifier.padding(start = 16.dp, bottom = 4.dp)
        )
        Text(
            text = "Quickly access your favorite tools",
            style = MaterialTheme.typography.body2,
            color = TextSecondary,
            modifier = Modifier.padding(start = 16.dp, bottom = 8.dp)
        )

        // LD1: Create a LazyRow for horizontal scrolling of recent tools
        LazyRow(
            contentPadding = PaddingValues(horizontal = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // LD1: For each tool, display a ToolCard
            items(recentTools) { tool ->
                ToolCard(
                    tool = tool,
                    onClick = {
                        // LD1: Handle click events to call onToolSelected with tool ID
                        onToolSelected(tool.id)
                    },
                    onFavoriteClick = {
                        // LD1: Handle favorite toggle to call onFavoriteClick with tool ID
                        onFavoriteClick(tool.id)
                    },
                    modifier = Modifier.width(200.dp)
                )
            }
        }
    }
}

/**
 * Composable function that displays a vertical list of tools for the selected category
 *
 * @param tools List of tools to display
 * @param onToolSelected Callback invoked when a tool is selected
 * @param onFavoriteClick Callback invoked when the favorite button is clicked
 * @param modifier Modifier to apply styling and layout
 */
@Composable
private fun ToolList(
    tools: List<Tool>,
    onToolSelected: (String) -> Unit,
    onFavoriteClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to contain the list
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        // LD1: Add a title for the selected category
        Text(
            text = "All Tools",
            style = MaterialTheme.typography.h6,
            color = TextPrimary,
            modifier = Modifier.padding(start = 16.dp, bottom = 8.dp)
        )

        // LD1: Create a LazyColumn for vertical scrolling
        LazyColumn(
            contentPadding = PaddingValues(horizontal = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // LD1: For each tool, display a ToolCard
            items(tools) { tool ->
                ToolCard(
                    tool = tool,
                    onClick = {
                        // LD1: Handle click events to call onToolSelected with tool ID
                        onToolSelected(tool.id)
                    },
                    onFavoriteClick = {
                        // LD1: Handle favorite toggle to call onFavoriteClick with tool ID
                        onFavoriteClick(tool.id)
                    },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

/**
 * Composable function that displays a button to navigate to favorites
 *
 * @param favoriteCount Number of favorite tools
 * @param onClick Callback invoked when the button is clicked
 * @param modifier Modifier to apply styling and layout
 */
@Composable
private fun FavoritesButton(
    favoriteCount: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Button with appropriate styling
    Button(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.buttonColors(
            backgroundColor = Primary,
            contentColor = TextPrimary
        ),
        shape = MaterialTheme.shapes.small
    ) {
        // LD1: Display a heart icon and "Favorites" text
        Icon(
            imageVector = Icons.Filled.Favorite,
            contentDescription = "Favorites",
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(text = "Favorites")
        // LD1: Show the count of favorite tools if greater than 0
        if (favoriteCount > 0) {
            Text(text = " ($favoriteCount)")
        }
    }
}

/**
 * Composable function that displays the top app bar for the Tool Library screen
 *
 * @param favoriteCount Number of favorite tools
 * @param onFavoritesClicked Callback invoked when the favorites button is clicked
 */
@Composable
private fun ToolLibraryTopBar(
    favoriteCount: Int,
    onFavoritesClicked: () -> Unit
) {
    // LD1: Create a TopAppBar with appropriate styling
    TopAppBar(
        title = {
            // LD1: Display "Tool Library" title
            Text(
                text = "Tool Library",
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        },
        actions = {
            // LD1: Add a favorites button in the actions area
            FavoritesButton(
                favoriteCount = favoriteCount,
                onClick = {
                    // LD1: Handle click events to call onFavoritesClicked function
                    onFavoritesClicked()
                }
            )
        }
    )
}