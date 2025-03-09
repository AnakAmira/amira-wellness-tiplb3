package com.amirawellness.ui.screens.journal

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.lazy.LazyColumn // androidx.compose.foundation.lazy:1.5.0
import androidx.compose.foundation.lazy.items // androidx.compose.foundation.lazy:1.5.0
import androidx.compose.foundation.lazy.rememberLazyListState // androidx.compose.foundation.lazy:1.5.0
import androidx.compose.material.* // androidx.compose.material:1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons:1.5.0
import androidx.compose.material.icons.filled.* // androidx.compose.material.icons:1.5.0
import androidx.compose.runtime.* // androidx.compose.runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.graphics.Color // androidx.compose.ui:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt:hilt-navigation-compose:1.0.0
import androidx.navigation.NavController // androidx.navigation:navigation-compose:2.7.0
import com.amirawellness.data.models.Journal // Journal data model
import com.amirawellness.ui.components.buttons.PrimaryButton // Reusable primary button component
import com.amirawellness.ui.components.cards.JournalCard // Reusable card component for displaying journal entries
import com.amirawellness.ui.components.dialogs.ConfirmationDialog // Confirmation dialog component for delete confirmation
import com.amirawellness.ui.components.feedback.EmptyStateView // Empty state view component
import com.amirawellness.ui.components.feedback.ErrorView // Error state view component
import com.amirawellness.ui.components.inputs.SearchBar // Reusable search input component
import com.amirawellness.ui.components.loading.LoadingIndicator // Loading indicator component
import com.amirawellness.ui.navigation.NavActions // Navigation actions for screen transitions
import com.amirawellness.ui.theme.Primary // Primary brand color
import com.amirawellness.ui.theme.Surface // Surface color for backgrounds
import com.google.accompanist.swiperefresh.SwipeToRefresh // com.google.accompanist:accompanist-swiperefresh:0.27.0
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState // com.google.accompanist:accompanist-swiperefresh:0.27.0
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4

/**
 * Main composable function for the journal list screen
 *
 * @param navController Navigation controller
 */
@Composable
fun JournalListScreen(
    navController: NavController
) {
    // Get JournalListViewModel instance using hiltViewModel()
    val viewModel: JournalListViewModel = hiltViewModel()

    // Create NavActions instance with navController
    val navActions = remember(navController) { NavActions(navController) }

    // Collect uiState from viewModel as State
    val uiState = viewModel.uiState.collectAsState()

    // Create and remember snackbarHostState for showing messages
    val snackbarHostState = rememberSnackbarHostState()

    // Create and remember coroutineScope for launching coroutines
    val coroutineScope = rememberCoroutineScope()

    // Create and remember showDeleteDialog state for delete confirmation
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Create and remember journalToDelete state for tracking journal to delete
    var journalToDelete by remember { mutableStateOf<Journal?>(null) }

    // Create and remember searchQuery state for search functionality
    var searchQuery by remember { mutableStateOf("") }

    // Create and remember showFavoritesOnly state for favorites filtering
    var showFavoritesOnly by remember { mutableStateOf(false) }

    // Create a LaunchedEffect to load journals when the screen is first displayed
    LaunchedEffect(key1 = Unit) {
        viewModel.loadJournals()
    }

    // Create a LaunchedEffect to show snackbar messages when they appear in uiState
    LaunchedEffect(key1 = uiState.value.message) {
        uiState.value.message?.let { message ->
            coroutineScope.launch {
                snackbarHostState.showSnackbar(message)
                viewModel.clearMessage()
            }
        }
    }

    // Create a Scaffold with TopAppBar, FloatingActionButton, and SnackbarHost
    Scaffold(
        topBar = {
            JournalListTopBar(
                title = "Diario de Voz",
                showSearchBar = searchQuery.isNotEmpty(),
                onSearchClick = {
                    searchQuery = if (searchQuery.isEmpty()) " " else ""
                    viewModel.filterJournals(searchQuery)
                },
                showFavoritesOnly = showFavoritesOnly,
                onFavoritesToggle = {
                    showFavoritesOnly = !showFavoritesOnly
                    viewModel.showFavoritesOnly(showFavoritesOnly)
                },
                modifier = Modifier.fillMaxWidth()
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { navActions.navigateToRecordJournal() },
                backgroundColor = Primary
            ) {
                Icon(Icons.Filled.Add, "Add", tint = Surface)
            }
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        }
    ) { paddingValues ->
        // Implement SwipeToRefresh for pull-to-refresh functionality
        SwipeToRefresh(
            state = rememberSwipeRefreshState(isRefreshing = uiState.value.isRefreshing),
            onRefresh = { viewModel.refresh() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Create main content with LazyColumn for journal list
            if (uiState.value.isLoading) {
                // Show LoadingIndicator when isLoading is true
                LoadingIndicator(modifier = Modifier.fillMaxSize())
            } else if (uiState.value.error != null) {
                // Show ErrorView when error is not null
                ErrorView(
                    message = uiState.value.error,
                    onAction = { viewModel.loadJournals() },
                    modifier = Modifier.fillMaxSize()
                )
            } else if (uiState.value.journals.isEmpty()) {
                // Show EmptyStateView when journals list is empty
                EmptyStateView(
                    message = "No hay diarios disponibles",
                    onAction = { navActions.navigateToRecordJournal() },
                    actionText = "Crear un diario",
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                // Render JournalCard for each journal in the list
                JournalList(
                    journals = uiState.value.journals,
                    onJournalClick = { journal ->
                        navActions.navigateToJournalDetail(journal.id)
                    },
                    onDeleteClick = { journal ->
                        journalToDelete = journal
                        showDeleteDialog = true
                    },
                    onFavoriteClick = { journal ->
                        viewModel.deleteJournal(journal)
                    },
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }

    // Implement delete confirmation dialog
    if (showDeleteDialog && journalToDelete != null) {
        DeleteConfirmationDialog(
            journal = journalToDelete!!,
            onConfirm = {
                viewModel.deleteJournal(journalToDelete!!)
                journalToDelete = null
                showDeleteDialog = false
            },
            onDismiss = {
                journalToDelete = null
                showDeleteDialog = false
            }
        )
    }
}

/**
 * Composable function for the journal list top app bar
 *
 * @param title Title of the screen
 * @param showSearchBar Whether to show the search bar
 * @param onSearchClick Callback for when the search icon is clicked
 * @param showFavoritesOnly Whether to show only favorite journals
 * @param onFavoritesToggle Callback for when the favorites filter is toggled
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun JournalListTopBar(
    title: String,
    showSearchBar: Boolean,
    onSearchClick: () -> Unit,
    showFavoritesOnly: Boolean,
    onFavoritesToggle: () -> Unit,
    modifier: Modifier = Modifier
) {
    TopAppBar(
        title = {
            if (showSearchBar) {
                JournalSearchBar(
                    query = "",
                    onQueryChange = { /*TODO*/ },
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                Text(text = title)
            }
        },
        navigationIcon = {
            IconButton(onClick = { /*TODO*/ }) {
                Icon(Icons.Filled.ArrowBack, "Back")
            }
        },
        actions = {
            IconButton(onClick = onSearchClick) {
                Icon(Icons.Filled.Search, "Search")
            }
            IconButton(onClick = onFavoritesToggle) {
                Icon(
                    imageVector = if (showFavoritesOnly) Icons.Filled.Favorite else Icons.Filled.FilterList,
                    contentDescription = "Filter Favorites"
                )
            }
        },
        backgroundColor = Surface,
        contentColor = Primary,
        modifier = modifier
    )
}

/**
 * Composable function for the journal search bar
 *
 * @param query Current search query
 * @param onQueryChange Callback for when the query changes
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun JournalSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    SearchBar(
        query = query,
        onQueryChange = onQueryChange,
        placeholder = "Buscar en diarios",
        modifier = modifier
    )
}

/**
 * Composable function for rendering the list of journals
 *
 * @param journals List of journals to display
 * @param onJournalClick Callback for when a journal is clicked
 * @param onDeleteClick Callback for when the delete button is clicked
 * @param onFavoriteClick Callback for when the favorite button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun JournalList(
    journals: List<Journal>,
    onJournalClick: (Journal) -> Unit,
    onDeleteClick: (Journal) -> Unit,
    onFavoriteClick: (Journal) -> Unit,
    modifier: Modifier = Modifier
) {
    val listState = rememberLazyListState()

    LazyColumn(
        state = listState,
        modifier = modifier
    ) {
        items(journals) { journal ->
            JournalCard(
                journal = journal,
                onClick = { onJournalClick(journal) },
                onPlayClick = { /*TODO*/ },
                onFavoriteClick = { onFavoriteClick(journal) },
                modifier = Modifier.padding(8.dp)
            )
        }
    }
}

/**
 * Composable function for the delete confirmation dialog
 *
 * @param journal Journal to delete
 * @param onConfirm Callback for when the user confirms deletion
 * @param onDismiss Callback for when the dialog is dismissed
 */
@Composable
private fun DeleteConfirmationDialog(
    journal: Journal,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    ConfirmationDialog(
        title = "Eliminar diario",
        message = "¿Estás seguro de que quieres eliminar este diario?",
        confirmButtonText = "Eliminar",
        cancelButtonText = "Cancelar",
        onConfirm = onConfirm,
        onDismiss = onDismiss,
        showDialog = true
    )
}