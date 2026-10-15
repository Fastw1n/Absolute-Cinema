import Foundation
import Observation

@MainActor
@Observable
final class RatingsViewModel {
    private(set) var entries: [SavedRating] = []
    var errorMessage: String?
    private(set) var isLoading = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private let settings: SettingsStore
    private let repository: RatingRepository

    init(repository: RatingRepository, settings: SettingsStore) {
        self.repository = repository
        self.settings = settings
    }

    var repositoryRevision: Int { repository.revision }

    var sortOrder: RatingSortOrder { settings.sortOrder }

    func reload() {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil
        let order = settings.sortOrder
        loadTask = Task {
            do {
                let loaded = try await repository.ratingsInBackground(sortedBy: order)
                // Предыдущая загрузка не должна заменять результат новой сортировки
                try Task.checkCancellation()
                entries = loaded
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoading = false
                errorMessage = "Не удалось прочитать сохранённые фильмы. Повторите загрузку."
            }
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    func setSortOrder(_ order: RatingSortOrder) {
        settings.setSortOrder(order)
        reload()
    }

    func remove(_ entry: SavedRating) {
        do {
            try repository.remove(movieID: entry.id)
        } catch {
            errorMessage = "Не удалось удалить оценку. Попробуйте ещё раз."
        }
    }
}
