import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private(set) var results: [MovieSummary] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false
    private(set) var errorMessage: String?

    private let repository: any MovieRepositoryProtocol
    private let debounceNanoseconds: UInt64
    @ObservationIgnored private(set) var task: Task<Void, Never>?
    private var generation = 0
    private var activeQuery: String?
    private var isDebouncing = false
    private var completedQuery: String?

    init(repository: any MovieRepositoryProtocol, debounceNanoseconds: UInt64 = 350_000_000) {
        self.repository = repository
        self.debounceNanoseconds = debounceNanoseconds
    }

    func queryChanged() {
        startSearch(immediately: false)
    }

    func submit() {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized == activeQuery, isSearching, !isDebouncing { return }
        if normalized == completedQuery, errorMessage == nil { return }
        startSearch(immediately: true)
    }

    func retry() {
        startSearch(immediately: true)
    }

    private func startSearch(immediately: Bool) {
        task?.cancel()
        generation += 1
        let currentGeneration = generation
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        results = []
        hasSearched = false
        activeQuery = query
        guard !query.isEmpty else {
            isSearching = false
            isDebouncing = false
            completedQuery = nil
            return
        }
        isSearching = true
        isDebouncing = !immediately
        task = Task {
            do {
                if !immediately {
                    try await Task.sleep(nanoseconds: debounceNanoseconds)
                }
                try Task.checkCancellation()
                guard generation == currentGeneration else { return }
                isDebouncing = false
                let movies = try await repository.search(query: query)
                try Task.checkCancellation()
                guard generation == currentGeneration else { return }
                results = movies
                hasSearched = true
                isSearching = false
                completedQuery = query
            } catch {
                guard !Task.isCancelled, generation == currentGeneration else { return }
                errorMessage = AppError.message(for: error)
                isSearching = false
                hasSearched = true
            }
        }
    }

    /// Позволяет тестам ждать именно текущую задачу без случайных задержек.
    func waitForCurrentSearch() async {
        await task?.value
    }
}
