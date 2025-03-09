package com.amirawellness.ui.screens.tools

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout 1.5.0
import androidx.compose.foundation.lazy.LazyColumn // androidx.compose.foundation.lazy 1.5.0
import androidx.compose.foundation.lazy.items // androidx.compose.foundation.lazy 1.5.0
import androidx.compose.material.* // androidx.compose.material 1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // androidx.compose.material.icons.filled 1.5.0
import androidx.compose.material.icons.filled.Favorite // androidx.compose.material.icons.filled 1.5.0
import androidx.compose.runtime.* // androidx.compose.runtime 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose 1.0.0
import androidx.navigation.NavController // androidx.navigation 2.7.0
import com.amirawellness.data.models.Tool // com.amirawellness.data.models.Tool
import com.amirawellness.ui.components.cards.ToolCard // com.amirawellness.ui.components.cards.ToolCard
import com.amirawellness.ui.components.feedback.EmptyStateView // com.amirawellness.ui.components.feedback.EmptyStateView
import com.amirawellness.ui.components.feedback.ErrorView // com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.components.loading.LoadingIndicator // com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.theme.Primary // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.Surface // com.amirawellness.ui.theme.Color
import com.amirawellness.ui.theme.TextPrimary // com.amirawellness.ui.theme.Color
import com.google.accompanist.swiperefresh.SwipeRefresh // com.google.accompanist.swiperefresh 0.30.1
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState // com.google.accompanist.swiperefresh 0.30.1

/**
 * Main composable function for the Favorites screen that displays favorite tools and handles user interactions
 *
 * @param navController NavController for screen transitions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun FavoritesScreen(
    navController: NavController,
    modifier: Modifier = Modifier
) {
    // Get ViewModel instance using hiltViewModel()
    val viewModel: FavoritesViewModel = hiltViewModel()

    // Collect uiState from viewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // Create coroutine scope for handling side effects
    val coroutineScope = rememberCoroutineScope()

    // Create SwipeRefresh component for pull-to-refresh functionality
    val swipeRefreshState = rememberSwipeRefreshState(isRefreshing = uiState is FavoritesUiState.Loading)

    // Create Scaffold with TopAppBar and content
    Scaffold(
        modifier = modifier,
        topBar = {
            FavoritesTopBar(onBackPressed = {
                viewModel.onBackPressed()
            })
        }
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = {
                viewModel.refresh()
            },
            modifier = Modifier.padding(paddingValues)
        ) {
            // Handle different UI states (Loading, Success, Error)
            when (uiState) {
                is FavoritesUiState.Loading -> {
                    // Display loading indicator when in Loading state
                    LoadingIndicator(modifier = Modifier.fillMaxSize())
                }

                is FavoritesUiState.Error -> {
                    // Display error view when in Error state with retry option
                    ErrorView(
                        message = (uiState as FavoritesUiState.Error).message,
                        onAction = { viewModel.refresh() },
                        modifier = Modifier.fillMaxSize()
                    )
                }

                is FavoritesUiState.Success -> {
                    val favoriteTools = (uiState as FavoritesUiState.Success).favoriteTools
                    if (favoriteTools.isNotEmpty()) {
                        // Display favorite tools list when in Success state
                        FavoritesContent(
                            favoriteTools = favoriteTools,
                            onToolSelected = { toolId ->
                                viewModel.onToolSelected(toolId)
                            },
                            onFavoriteClick = { toolId, isFavorite ->
                                viewModel.toggleFavorite(toolId, isFavorite)
                            },
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        // Display empty state when there are no favorite tools
                        EmptyStateView(
                            message = "No favorites yet",
                            description = "Add tools to your favorites for quick access to the ones you use most",
                            actionText = "Browse Tools",
                            onAction = { viewModel.onBrowseToolsClick() },
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays the list of favorite tools
 *
 * @param favoriteTools List of favorite tool objects
 * @param onToolSelected Function to handle tool selection
 * @param onFavoriteClick Function to handle favorite toggle
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun FavoritesContent(
    favoriteTools: List<Tool>,
    onToolSelected: (String) -> Unit,
    onFavoriteClick: (String, Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp)
    ) {
        Text(
            text = "Your Favorites",
            style = MaterialTheme.typography.h5,
            color = TextPrimary,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize()
        ) {
            items(favoriteTools) { tool ->
                ToolCard(
                    tool = tool,
                    onClick = {
                        onToolSelected(tool.id)
                    },
                    onFavoriteClick = {
                        onFavoriteClick(tool.id, tool.isFavorite)
                    },
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
        }
    }
}

/**
 * Composable function that displays the top app bar for the Favorites screen
 *
 * @param onBackPressed Function to handle back button press
 */
@Composable
private fun FavoritesTopBar(
    onBackPressed: () -> Unit
) {
    TopAppBar(
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Favorites",
                    style = MaterialTheme.typography.h6,
                    color = TextPrimary
                )
                Icon(
                    imageVector = Icons.Filled.Favorite,
                    contentDescription = "Favorite",
                    tint = Primary,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        },
        navigationIcon = {
            IconButton(onClick = { onBackPressed() }) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = TextPrimary
                )
            }
        },
        backgroundColor = Surface
    )
}