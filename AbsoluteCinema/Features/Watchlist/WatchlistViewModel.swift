import Observation

@MainActor
@Observable
final class WatchlistViewModel {
    private(set) var movies: [Movie] = []
    var errorMessage: String?
    private(set) var isLoading = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    var repositoryRevision: Int { repository.revision }

    func reload() {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil
        loadTask = Task {
            do {
                let loaded = try await repository.moviesInBackground()
                // Предыдущая загрузка не должна заменять результат новой сортировки.
                try Task.checkCancellation()
                movies = loaded
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoading = false
                errorMessage = "Не удалось прочитать список желаемого."
            }
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    func remove(_ movie: Movie) {
        do {
            try repository.remove(movieID: movie.id)
        } catch {
            errorMessage = "Не удалось убрать фильм из списка."
        }
    }
}
