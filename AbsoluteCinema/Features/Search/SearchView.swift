import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var isSearchPresented = false

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isSearching {
                ProgressView("Поиск фильмов…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage {
                ErrorNotice(message: message, retry: viewModel.retry)
            } else if !viewModel.hasSearched {
                ContentUnavailableView("Найдите фильм", systemImage: "magnifyingglass",
                                       description: Text("Введите название, чтобы посмотреть сведения и оставить свою оценку."))
            } else if viewModel.results.isEmpty {
                ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass",
                                       description: Text("Попробуйте другое название."))
            } else {
                List(viewModel.results) { movie in
                    NavigationLink(value: movie.id) {
                        MovieRow(movie: movie)
                    }
                    .listRowBackground(Color("Background"))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Поиск")
        .searchable(text: $viewModel.query, isPresented: $isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Название фильма")
        .onChange(of: viewModel.query) { _, _ in viewModel.queryChanged() }
        .onSubmit(of: .search) { viewModel.submit() }
        .onDisappear { isSearchPresented = false }
    }
}
