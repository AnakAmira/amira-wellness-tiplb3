import SwiftUI // iOS SDK
import Combine // iOS SDK

/// A SwiftUI view that displays a list of voice journal entries with filtering, sorting, and search capabilities.
/// It provides a user-friendly interface for managing journal recordings, including viewing details, favoriting, and deleting entries.
struct JournalListView: View {
    // MARK: - Properties
    
    /// View model that manages the state and business logic for this screen
    @ObservedObject var viewModel: JournalListViewModel
    
    /// Indicates whether the search bar is currently focused
    @State private var isSearchFocused: Bool = false
    
    /// Controls visibility of the filter options sheet
    @State private var showFilterSheet: Bool = false
    
    /// Controls visibility of the sort options sheet
    @State private var showSortSheet: Bool = false
    
    /// Controls visibility of the emotion filter sheet
    @State private var showEmotionFilterSheet: Bool = false
    
    /// Controls visibility of the delete confirmation dialog
    @State private var showDeleteConfirmation: Bool = false
    
    /// Holds the ID of the journal currently being deleted
    @State private var journalToDelete: UUID? = nil
    
    // MARK: - Initialization
    
    /// Initializes the view with a view model for managing journal list data
    /// - Parameter viewModel: The view model that provides data and handles actions
    init(viewModel: JournalListViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                contentView
                
                floatingActionButton
            }
            .navigationTitle("Diarios de voz")
            .navigationBarItems(
                trailing: HStack(spacing: 16) {
                    filterButton
                    sortButton
                }
            )
            .confirmationDialog(
                "¿Deseas eliminar esta grabación?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let id = journalToDelete {
                        viewModel.deleteJournal(journalId: id)
                    }
                    journalToDelete = nil
                }
                Button("Cancelar", role: .cancel) {
                    journalToDelete = nil
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .sheet(isPresented: $showSortSheet) {
                sortSheet
            }
            .sheet(isPresented: $showEmotionFilterSheet) {
                emotionFilterSheet
            }
            .background(ColorConstants.background.edgesIgnoringSafeArea(.all))
            .task {
                viewModel.loadJournals()
            }
        }
    }
    
    // MARK: - Content Views
    
    /// Creates the appropriate content view based on the current state
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(
                    message: "Cargando tus grabaciones...",
                    isLoading: true
                )
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(
                    title: "Error al cargar grabaciones",
                    message: errorMessage,
                    retryAction: {
                        viewModel.loadJournals()
                    }
                )
            } else if viewModel.journals.isEmpty {
                EmptyStateView(
                    animationName: "lottie_empty",
                    title: "No hay grabaciones",
                    message: "Aún no has creado ninguna grabación de voz. Comienza a grabar tus pensamientos y emociones.",
                    buttonTitle: "Crear grabación",
                    buttonAction: {
                        viewModel.navigateToRecordJournal()
                    }
                )
            } else {
                journalListView
            }
        }
    }
    
    /// Creates the view that displays the list of journals
    private var journalListView: some View {
        VStack(spacing: 12) {
            // Search bar for filtering journals
            SearchBar(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.updateSearchText($0) }
                ),
                placeholder: "Buscar grabaciones",
                isFocused: $isSearchFocused
            )
            .padding(.horizontal)
            
            // Horizontal scrollable chips showing active filters
            filterChipsView
                .padding(.horizontal)
            
            // List of journal entries
            List {
                ForEach(viewModel.journals, id: \.id) { journal in
                    JournalCard(
                        journal: journal,
                        showEmotionalShift: true,
                        showActions: true,
                        onTap: {
                            viewModel.navigateToJournalDetail(journalId: journal.id)
                        },
                        onPlay: {
                            viewModel.navigateToJournalDetail(journalId: journal.id)
                        },
                        onFavoriteToggle: { _ in
                            viewModel.toggleFavorite(journalId: journal.id)
                        },
                        onExport: {
                            // Export functionality would be implemented here
                            // This could open a share sheet or custom export UI
                        },
                        onDelete: {
                            journalToDelete = journal.id
                            showDeleteConfirmation = true
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.refreshJournals()
            }
        }
        .background(ColorConstants.background)
    }
    
    /// Creates a view displaying the active filters as chips
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Filter type chip
                HStack {
                    switch viewModel.selectedFilter {
                    case .all:
                        Text("Todos")
                    case .favorites:
                        Text("Favoritos")
                    case .emotion:
                        Text("Emoción")
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorConstants.surface)
                .cornerRadius(16)
                .onTapGesture {
                    showFilterSheet = true
                }
                
                // Emotion filter chip (only shown when emotion filter is active)
                if case .emotion = viewModel.selectedFilter, let emotion = viewModel.selectedEmotionFilter {
                    HStack {
                        Text(emotion.displayName())
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        EmotionColors.forEmotionType(emotionType: emotion).opacity(0.2)
                    )
                    .cornerRadius(16)
                    .onTapGesture {
                        viewModel.setEmotionFilter(nil)
                    }
                }
                
                // Sort option chip
                HStack {
                    Text(sortOptionText(viewModel.selectedSortOption))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorConstants.surface)
                .cornerRadius(16)
                .onTapGesture {
                    showSortSheet = true
                }
            }
        }
    }
    
    /// Creates a sheet view for selecting filter options
    private var filterSheet: some View {
        NavigationView {
            List {
                Button {
                    viewModel.setFilter(.all)
                    showFilterSheet = false
                } label: {
                    HStack {
                        Text("Todos")
                        Spacer()
                        if case .all = viewModel.selectedFilter {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setFilter(.favorites)
                    showFilterSheet = false
                } label: {
                    HStack {
                        Text("Favoritos")
                        Spacer()
                        if case .favorites = viewModel.selectedFilter {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    showFilterSheet = false
                    showEmotionFilterSheet = true
                } label: {
                    HStack {
                        Text("Por emoción")
                        Spacer()
                        if case .emotion = viewModel.selectedFilter {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
            }
            .navigationTitle("Filtrar grabaciones")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Listo") {
                showFilterSheet = false
            })
        }
    }
    
    /// Creates a sheet view for selecting sort options
    private var sortSheet: some View {
        NavigationView {
            List {
                Button {
                    viewModel.setSortOption(.dateNewest)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Fecha: Más reciente")
                        Spacer()
                        if viewModel.selectedSortOption == .dateNewest {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setSortOption(.dateOldest)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Fecha: Más antiguo")
                        Spacer()
                        if viewModel.selectedSortOption == .dateOldest {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setSortOption(.durationLongest)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Duración: Más larga")
                        Spacer()
                        if viewModel.selectedSortOption == .durationLongest {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setSortOption(.durationShortest)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Duración: Más corta")
                        Spacer()
                        if viewModel.selectedSortOption == .durationShortest {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setSortOption(.titleAZ)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Título: A-Z")
                        Spacer()
                        if viewModel.selectedSortOption == .titleAZ {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
                
                Button {
                    viewModel.setSortOption(.titleZA)
                    showSortSheet = false
                } label: {
                    HStack {
                        Text("Título: Z-A")
                        Spacer()
                        if viewModel.selectedSortOption == .titleZA {
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorConstants.primary)
                        }
                    }
                }
            }
            .navigationTitle("Ordenar grabaciones")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Listo") {
                showSortSheet = false
            })
        }
    }
    
    /// Creates a sheet view for selecting emotion filters
    private var emotionFilterSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.getEmotionTypeOptions(), id: \.self) { emotion in
                    Button {
                        viewModel.setEmotionFilter(emotion)
                        showEmotionFilterSheet = false
                    } label: {
                        HStack {
                            Text(emotion.displayName())
                                .foregroundColor(EmotionColors.forEmotionType(emotionType: emotion))
                            Spacer()
                            if viewModel.selectedEmotionFilter == emotion {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ColorConstants.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtrar por emoción")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Listo") {
                showEmotionFilterSheet = false
            })
        }
    }
    
    /// Creates a floating action button for creating new journals
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    viewModel.navigateToRecordJournal()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ColorConstants.textOnPrimary)
                        .frame(width: 60, height: 60)
                        .background(ColorConstants.primary)
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Grabar nuevo diario")
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the display text for a sort option
    private func sortOptionText(_ option: JournalSortOption) -> String {
        switch option {
        case .dateNewest:
            return "Fecha: Más reciente"
        case .dateOldest:
            return "Fecha: Más antiguo"
        case .durationLongest:
            return "Duración: Más larga"
        case .durationShortest:
            return "Duración: Más corta"
        case .titleAZ:
            return "Título: A-Z"
        case .titleZA:
            return "Título: Z-A"
        }
    }
    
    /// The filter button shown in the navigation bar
    private var filterButton: some View {
        Button(action: {
            showFilterSheet = true
        }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 20))
                .foregroundColor(ColorConstants.primary)
        }
        .accessibilityLabel("Filtrar grabaciones")
    }
    
    /// The sort button shown in the navigation bar
    private var sortButton: some View {
        Button(action: {
            showSortSheet = true
        }) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 20))
                .foregroundColor(ColorConstants.primary)
        }
        .accessibilityLabel("Ordenar grabaciones")
    }
}