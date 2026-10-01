import SwiftUI

struct RatingsView: View {
    @State private var viewModel: RatingsViewModel

    init(viewModel: RatingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Сортировка", selection: Binding(
                    get: { viewModel.settings.sortOrder },
                    set: { viewModel.setSortOrder($0) }
                )) {
                    ForEach(RatingSortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
                .pickerStyle(.menu)
                Spacer(minLength: 0)
                Button("Сбросить", action: viewModel.resetSortOrder)
                    .font(.subheadline)
                    .accessibilityLabel("Сбросить сортировку")
            }
            .padding(.horizontal)

            if let message = viewModel.errorMessage {
                ErrorNotice(message: message, retry: viewModel.reload)
            }
            if viewModel.entries.isEmpty, viewModel.errorMessage == nil {
                ContentUnavailableView("Пока нет оценок", systemImage: "star",
                                       description: Text("Найдите фильм и сохраните свою оценку в его карточке."))
            } else {
                List(viewModel.entries) { entry in
                    NavigationLink(value: entry.id) {
                        VStack(alignment: .leading, spacing: 8) {
                            MovieRow(movie: entry.movie.summary)
                            HStack {
                                Label("Моя оценка: \(entry.rating) / 10", systemImage: "star.fill")
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                                Text(entry.ratedAt, format: .dateTime.day().month().year())
                                    .foregroundStyle(Color("SecondaryText"))
                            }
                            .font(.caption)
                            if !entry.comment.isEmpty {
                                Text(entry.comment)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("SecondaryText"))
                                    .lineLimit(2)
                            }
                        }
                    }
                    .listRowBackground(Color("Background"))
                    .swipeActions {
                        Button("Убрать оценку", role: .destructive) { viewModel.remove(entry) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Мои оценки")
        .onAppear { viewModel.reload() }
        .onChange(of: viewModel.repositoryRevision) { _, _ in viewModel.reload() }
    }
}
