import Foundation
import Observation

@MainActor
@Observable
final class RatingsViewModel {
    private(set) var entries: [SavedRating] = []
    var errorMessage: String?
    let settings: SettingsStore
    private let repository: any RatingRepositoryProtocol

    init(repository: any RatingRepositoryProtocol, settings: SettingsStore) {
        self.repository = repository
        self.settings = settings
    }

    var repositoryRevision: Int { repository.revision }

    func reload() {
        do {
            entries = try repository.ratings(sortedBy: settings.sortOrder)
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось прочитать сохранённые фильмы. Повторите загрузку."
        }
    }

    func setSortOrder(_ order: RatingSortOrder) {
        settings.setSortOrder(order)
        reload()
    }

    func resetSortOrder() {
        settings.resetSortOrder()
        reload()
    }

    func remove(_ entry: SavedRating) {
        do {
            try repository.remove(movieID: entry.id)
            reload()
        } catch {
            errorMessage = "Не удалось удалить оценку. Попробуйте ещё раз."
        }
    }
}
