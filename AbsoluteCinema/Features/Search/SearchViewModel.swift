import Foundation
import Observation

// @Observable позволяет SwiftUI замечать изменения свойств ViewModel.
// @MainActor оставляет работу с состоянием экрана на главном потоке.
@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    var hasQuery: Bool {
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // При изменении query SwiftUI заново читает результаты и обновляет список.
    var results: [Movie] {
        return repository.search(query: query)
    }
}
