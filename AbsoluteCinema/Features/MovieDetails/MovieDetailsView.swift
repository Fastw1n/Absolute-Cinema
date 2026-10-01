import SwiftUI

struct MovieDetailsView: View {
    @State private var viewModel: MovieDetailsViewModel
    @FocusState private var isCommentFocused: Bool

    init(viewModel: MovieDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                let movie = viewModel.movie
                MoviePoster(name: movie.posterName)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title).font(.title2.bold())
                    Text(movie.originalTitle).font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                    Text(viewModel.metadata).font(.subheadline)
                    Text(movie.genres.isEmpty ? "Жанры не указаны" : movie.genres.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                }
                HStack {
                    Label(movie.voteCount > 0
                          ? movie.rating.formatted(.number.precision(.fractionLength(1))) : "Нет оценок",
                          systemImage: "star.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("TMDB · \(movie.voteCount.formatted()) голосов")
                        .foregroundStyle(Color("SecondaryText"))
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Моя оценка и комментарий").font(.headline)
                    Picker("Моя оценка", selection: $viewModel.draftRating) {
                        Text("Не выбрана").tag(0)
                        ForEach(1...10, id: \.self) { rating in
                            Text("\(rating) из 10").tag(rating)
                        }
                    }
                    .pickerStyle(.menu)
                    Text("Комментарий (необязательно)")
                        .font(.subheadline).foregroundStyle(Color("SecondaryText"))
                    TextEditor(text: $viewModel.comment)
                        .focused($isCommentFocused)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("Мой комментарий о фильме")
                    Button("Сохранить оценку") {
                        viewModel.save()
                        if viewModel.storageError == nil { isCommentFocused = false }
                    }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color("Background"))
                        .disabled(!viewModel.canSave)
                    if !viewModel.hasChanges, let message = viewModel.saveMessage {
                        Text(message).font(.caption).foregroundStyle(Color("SecondaryText"))
                    }
                    if let saved = viewModel.savedRating {
                        Text("Дата оценки: \(saved.ratedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(Color("SecondaryText"))
                        Button("Убрать оценку и комментарий", role: .destructive,
                               action: viewModel.removeRating)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("Описание").font(.headline)
                    Text(movie.overview.isEmpty ? "Описание пока отсутствует." : movie.overview)
                        .lineSpacing(4)
                }

            }
            .padding(20)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color("Background"))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Карточка фильма")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadRating() }
        .onChange(of: viewModel.repositoryRevision) { _, _ in viewModel.loadRating() }
        .alert("Не удалось выполнить действие", isPresented: Binding(
            get: { viewModel.storageError != nil },
            set: { if !$0 { viewModel.storageError = nil } }
        )) {
            Button("Понятно", role: .cancel) { viewModel.storageError = nil }
        } message: {
            Text(viewModel.storageError ?? "")
        }
    }
}
