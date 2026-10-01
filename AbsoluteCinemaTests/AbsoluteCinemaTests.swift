import Foundation
import SwiftData
import Testing
@testable import AbsoluteCinema

private func movie(_ id: Int = 62) -> Movie {
    Movie(id: id, title: "Фильм \(id)", originalTitle: "Movie \(id)", year: 1968,
          runtime: 149, overview: "Описание", genres: ["фантастика"],
          rating: 8.044, voteCount: 12960, posterPath: nil)
}

private func memoryContainer() throws -> ModelContainer {
    try ModelContainer(for: RatedMovie.self,
                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

@MainActor
struct StorageTests {
    @Test func createReadUpdateDeleteIncludingComment() throws {
        let container = try memoryContainer()
        var date = Date(timeIntervalSince1970: 100)
        let repository = RatingRepository(container: container, now: { date })
        #expect(try repository.rating(for: 62) == nil)
        let created = try repository.save(movie: movie(), rating: 7, comment: "Мой отзыв 🎬\nВторая строка")
        #expect(created.ratedAt == date)
        #expect(try repository.rating(for: 62)?.comment == "Мой отзыв 🎬\nВторая строка")

        date = Date(timeIntervalSince1970: 200)
        let updated = try repository.save(movie: movie(), rating: 9, comment: "Новое впечатление")
        #expect(updated.ratedAt == date)
        #expect(updated.rating == 9)
        #expect(try repository.ratings(sortedBy: .newestFirst).count == 1)
        try repository.remove(movieID: 62)
        #expect(try repository.rating(for: 62) == nil)
        #expect(try repository.ratings(sortedBy: .newestFirst).isEmpty)
    }

    @Test func commentEditAndSameRatingKeepDate() throws {
        let container = try memoryContainer()
        var date = Date(timeIntervalSince1970: 100)
        let repository = RatingRepository(container: container, now: { date })
        let first = try repository.save(movie: movie(), rating: 8, comment: "")
        date = Date(timeIntervalSince1970: 200)
        let updated = try repository.save(movie: movie(), rating: 8, comment: "Добавил комментарий")
        #expect(updated.ratedAt == first.ratedAt)
        #expect(updated.comment == "Добавил комментарий")
    }

    @Test(arguments: [0, 11, -1]) func invalidRatingDoesNotOverwriteRecord(value: Int) throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        try repository.save(movie: movie(), rating: 8, comment: "Сохранённый комментарий")
        #expect(throws: AppError.self) {
            try repository.save(movie: movie(), rating: value, comment: "Не должно сохраниться")
        }
        #expect(try repository.rating(for: 62)?.rating == 8)
        #expect(try repository.rating(for: 62)?.comment == "Сохранённый комментарий")
    }

    @Test func sortingHasStableTiesAndUsesPersonalRating() throws {
        let container = try memoryContainer()
        var date = Date(timeIntervalSince1970: 100)
        let repository = RatingRepository(container: container, now: { date })
        try repository.save(movie: movie(1), rating: 10, comment: "")
        date = Date(timeIntervalSince1970: 200)
        try repository.save(movie: movie(3), rating: 5, comment: "")
        try repository.save(movie: movie(2), rating: 5, comment: "")
        #expect(try repository.ratings(sortedBy: .newestFirst).map(\.id) == [2, 3, 1])
        #expect(try repository.ratings(sortedBy: .highestFirst).map(\.id) == [1, 2, 3])
    }

    @Test func diskStoreSurvivesReopeningAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("ratings.store")
        func open() throws -> ModelContainer {
            try ModelContainer(for: RatedMovie.self, configurations: ModelConfiguration(url: url))
        }
        do {
            let repository = RatingRepository(container: try open())
            try repository.save(movie: movie(), rating: 9, comment: "Осталось после перезапуска")
        }
        do {
            let repository = RatingRepository(container: try open())
            #expect(try repository.rating(for: 62)?.comment == "Осталось после перезапуска")
            #expect(try repository.rating(for: 62)?.movie.overview == "Описание")
            try repository.remove(movieID: 62)
        }
        let reopened = RatingRepository(container: try open())
        #expect(try reopened.ratings(sortedBy: .newestFirst).isEmpty)
    }

    @Test func settingsCRUDAndResetRemoveKey() throws {
        let suite = "FilmGraphTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        #expect(settings.sortOrder == .newestFirst)
        #expect(defaults.object(forKey: SettingsStore.sortKey) == nil)
        settings.setSortOrder(.newestFirst)
        #expect(defaults.string(forKey: SettingsStore.sortKey) == "newestFirst")
        settings.setSortOrder(.highestFirst)
        #expect(SettingsStore(defaults: defaults).sortOrder == .highestFirst)
        settings.resetSortOrder()
        #expect(defaults.object(forKey: SettingsStore.sortKey) == nil)
        #expect(SettingsStore(defaults: defaults).sortOrder == .newestFirst)
    }
}

private struct OfflineMovieRepository: MovieRepositoryProtocol {
    func search(query: String) async throws -> [MovieSummary] { throw URLError(.notConnectedToInternet) }
    func details(id: Int) async throws -> Movie { throw URLError(.notConnectedToInternet) }
}

@MainActor
struct DetailsTests {
    @Test func savedMovieAndCommentAvailableOfflineAndEditable() async throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        try repository.save(movie: movie(), rating: 8, comment: "Мой комментарий")
        let model = MovieDetailsViewModel(movieID: 62, movies: OfflineMovieRepository(), ratings: repository)
        await model.load()
        #expect(!model.isLoading)
        #expect(model.isSavedCopy)
        #expect(model.movie == movie())
        #expect(model.draftRating == 8)
        #expect(model.comment == "Мой комментарий")
        #expect(model.loadError != nil)
        model.comment = "Изменил без сети"
        model.save()
        #expect(try repository.rating(for: 62)?.comment == "Изменил без сети")
        model.removeRating()
        #expect(model.comment.isEmpty)
        #expect(model.savedRating == nil)
        #expect(try repository.rating(for: 62) == nil)
    }

    @Test func unsavedMovieErrorEndsLoading() async throws {
        let container = try memoryContainer()
        let model = MovieDetailsViewModel(movieID: 62, movies: OfflineMovieRepository(),
                                         ratings: RatingRepository(container: container))
        await model.load()
        #expect(!model.isLoading)
        #expect(model.movie == nil)
        #expect(model.loadError != nil)
    }
}

/// Не учитывает отмену намеренно: проверяем защиту от ответов устаревшего запроса.
private actor ControlledRepository: MovieRepositoryProtocol {
    private var pending: [String: CheckedContinuation<[MovieSummary], Error>] = [:]
    private var arrivals: [String: [CheckedContinuation<Void, Never>]] = [:]
    private(set) var queries: [String] = []

    func search(query: String) async throws -> [MovieSummary] {
        queries.append(query)
        return try await withCheckedThrowingContinuation { continuation in
            pending[query] = continuation
            arrivals.removeValue(forKey: query)?.forEach { $0.resume() }
        }
    }

    func waitForQuery(_ query: String) async {
        if pending[query] != nil { return }
        await withCheckedContinuation { arrivals[query, default: []].append($0) }
    }

    func finish(_ query: String, result: Result<[MovieSummary], Error>) {
        pending.removeValue(forKey: query)?.resume(with: result)
    }

    func details(id: Int) async throws -> Movie { movie(id) }
}

@MainActor
struct SearchTests {
    @Test func oldResponseCannotReplaceNewResults() async {
        let repository = ControlledRepository()
        let model = SearchViewModel(repository: repository, debounceNanoseconds: 0)
        model.query = "старый"
        model.queryChanged()
        await repository.waitForQuery("старый")
        let oldTask = model.task
        model.query = "новый"
        model.queryChanged()
        await repository.waitForQuery("новый")
        await repository.finish("новый", result: .success([movie(2).summary]))
        await model.waitForCurrentSearch()
        await repository.finish("старый", result: .success([movie(1).summary]))
        await oldTask?.value
        #expect(model.results.map(\.id) == [2])
        #expect(model.errorMessage == nil)
    }

    @Test func clearingQueryIgnoresOldErrorAndMakesNoEmptyRequest() async {
        let repository = ControlledRepository()
        let model = SearchViewModel(repository: repository, debounceNanoseconds: 0)
        model.query = "фильм"
        model.queryChanged()
        await repository.waitForQuery("фильм")
        let oldTask = model.task
        model.query = "   "
        model.queryChanged()
        await repository.finish("фильм", result: .failure(AppError.invalidResponse))
        await oldTask?.value
        #expect(model.results.isEmpty)
        #expect(!model.hasSearched)
        #expect(!model.isSearching)
        #expect(model.errorMessage == nil)
        #expect(await repository.queries == ["фильм"])
    }

    @Test func emptyResponseAndRetryAfterError() async {
        let repository = ControlledRepository()
        let model = SearchViewModel(repository: repository, debounceNanoseconds: 0)
        model.query = "фильм"
        model.queryChanged()
        await repository.waitForQuery("фильм")
        await repository.finish("фильм", result: .failure(URLError(.notConnectedToInternet)))
        await model.waitForCurrentSearch()
        #expect(model.errorMessage != nil)
        #expect(!model.isSearching)
        model.retry()
        await repository.waitForQuery("фильм")
        await repository.finish("фильм", result: .success([]))
        await model.waitForCurrentSearch()
        #expect(model.errorMessage == nil)
        #expect(model.hasSearched)
        #expect(model.results.isEmpty)
    }
}
