import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color("SecondaryText"))
                TextField("Поиск фильмов", text: $viewModel.query)
                    .submitLabel(.search)
            }
            .padding(14)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 10))
            .padding()

            if viewModel.movies.isEmpty {
                ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass",
                                       description: Text("Попробуйте другое название."))
            } else {
                List(viewModel.movies) { movie in
                    NavigationLink(value: movie) {
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
    }
}
