package com.amirawellness.ui.screens.tools

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.LaunchedEffect // version: 1.5.0
import androidx.compose.material.Scaffold // version: 1.5.0
import androidx.compose.material.TopAppBar // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Divider // version: 1.5.0
import androidx.compose.material.pullrefresh.pullRefresh // version: 1.5.0
import androidx.compose.material.pullrefresh.PullRefreshIndicator // version: 1.5.0
import androidx.compose.material.pullrefresh.rememberPullRefreshState // version: 1.5.0
import androidx.compose.foundation.lazy.LazyColumn // version: 1.5.0
import androidx.compose.foundation.lazy.items // version: 1.5.0
import androidx.compose.foundation.layout.Box // version: 1.5.0
import androidx.compose.foundation.layout.Column // version: 1.5.0
import androidx.compose.foundation.layout.Row // version: 1.5.0
import androidx.compose.foundation.layout.Spacer // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0

import com.amirawellness.ui.screens.tools.ToolCategoryViewModel
import com.amirawellness.ui.components.cards.ToolCard
import com.amirawellness.ui.components.inputs.SearchBar
import com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.components.feedback.NetworkErrorView
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Surface

/**
 * Main composable function for the Tool Category screen that displays tools within a specific category
 *
 * @param navActions Navigation actions for screen transitions
 */
@Composable
fun ToolCategoryScreen(
    navActions: NavActions
) {
    // Get ToolCategoryViewModel instance using hiltViewModel()
    val viewModel: ToolCategoryViewModel = hiltViewModel()

    // Collect uiState from viewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // Create a remember state for search query
    val searchQuery = remember { viewModel.uiState.value.searchQuery }

    // Create a pull-to-refresh state for the refresh functionality
    val pullRefreshState = rememberPullRefreshState(
        refreshing = uiState.isRefreshing,
        onRefresh = { viewModel.refresh() }
    )

    // Set up LaunchedEffect to handle navigation when selectedToolId changes or navigateBack is true
    LaunchedEffect(uiState.selectedToolId, uiState.navigateBack) {
        uiState.selectedToolId?.let { toolId ->
            navActions.navigateToToolDetail(toolId)
            viewModel.clearError()
        }
        if (uiState.navigateBack) {
            navActions.navigateBack()
            viewModel.clearError()
        }
    }

    // Create a Scaffold with TopAppBar containing back button and category name
    Scaffold(
        topBar = {
            ToolCategoryTopBar(
                title = uiState.categoryName,
                onBackClick = { viewModel.onBackPressed() }
            )
        }
    ) { innerPadding ->
        // Implement the main content with Box and PullRefreshIndicator
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .pullRefresh(pullRefreshState)
        ) {
            // Add PullRefreshIndicator
            PullRefreshIndicator(
                refreshing = uiState.isRefreshing,
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter),
                contentColor = Primary,
                backgroundColor = Surface
            )

            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Add SearchBar for filtering tools
                SearchBar(
                    query = searchQuery,
                    onQueryChange = { query -> viewModel.filterTools(query) },
                    modifier = Modifier.padding(16.dp)
                )

                // Add LazyColumn for displaying the list of tools
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 8.dp)
                ) {
                    // Handle different states: loading, error, empty list, and content
                    when {
                        uiState.isLoading -> {
                            item {
                                LoadingIndicator(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(200.dp)
                                )
                            }
                        }
                        uiState.error != null -> {
                            item {
                                if (uiState.error.contains("network", ignoreCase = true)) {
                                    NetworkErrorView(
                                        onRetry = { viewModel.refresh() },
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp)
                                    )
                                } else {
                                    GenericErrorView(
                                        onRetry = { viewModel.refresh() },
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp)
                                    )
                                }
                            }
                        }
                        uiState.filteredTools.isEmpty() -> {
                            item {
                                if (searchQuery.isNotEmpty()) {
                                    FilteredEmptyView(
                                        query = searchQuery,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp)
                                    )
                                } else {
                                    EmptyToolsView(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp)
                                    )
                                }
                            }
                        }
                        else -> {
                            // For each tool, display a ToolCard with onClick and onFavoriteClick handlers
                            items(uiState.filteredTools) { tool ->
                                ToolCard(
                                    tool = tool,
                                    onClick = { viewModel.onToolSelected(tool.id) },
                                    onFavoriteClick = { viewModel.toggleFavorite(tool.id) },
                                    modifier = Modifier.padding(
                                        horizontal = 16.dp,
                                        vertical = 8.dp
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Composable function for the top app bar of the Tool Category screen
 *
 * @param title The title to display in the top app bar
 * @param onBackClick Callback invoked when the back button is clicked
 */
@Composable
private fun ToolCategoryTopBar(
    title: String,
    onBackClick: () -> Unit
) {
    // Create a TopAppBar with the specified title
    TopAppBar(
        title = {
            Text(
                text = title,
                style = MaterialTheme.typography.h6
            )
        },
        navigationIcon = {
            // Add a navigation icon (back button) that calls onBackClick when pressed
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back"
                )
            }
        },
        backgroundColor = Surface,
        contentColor = Primary,
        elevation = 0.dp
    )
}

/**
 * Composable function that displays a message when no tools are available in the category
 *
 * @param modifier Modifier for customizing the layout
 */
@Composable
private fun EmptyToolsView(
    modifier: Modifier = Modifier
) {
    // Create a Column with center alignment
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display an appropriate icon or illustration
        Text(
            text = "No hay herramientas disponibles en esta categoría",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        // Add a suggestion to try another category
        Text(
            text = "Intenta con otra categoría",
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Composable function that displays a message when no tools match the current filter
 *
 * @param query The search query that was used
 * @param modifier Modifier for customizing the layout
 */
@Composable
private fun FilteredEmptyView(
    query: String,
    modifier: Modifier = Modifier
) {
    // Create a Column with center alignment
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display an appropriate icon or illustration
        Text(
            text = "No hay herramientas que coincidan con \"$query\"",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        // Suggest trying a different search term
        Text(
            text = "Intenta con otro término de búsqueda",
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )
    }
}