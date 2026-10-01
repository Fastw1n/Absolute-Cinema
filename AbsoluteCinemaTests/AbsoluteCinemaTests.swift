import Foundation
import SwiftData
import Testing
@testable import AbsoluteCinema

private func movie(_ id: Int = 62) -> Movie {
    Movie(id: id, title: "Фильм \(id)", originalTitle: "Movie \(id)", year: 1968,
          runtime: 149, overview: "Описание", genres: ["фантастика"],
          rating: 8.044, voteCount: 12960, posterName: nil)
}

private func memoryContainer() throws -> ModelContainer {
    try ModelContainer(for: RatedMovie.self,
                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

@MainActor
struct StorageTests {
    @Test func createReadUpdateDeleteIncludingComment() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        #expect(try repository.rating(for: 62) == nil)
        _ = try repository.save(movie: movie(), rating: 7, comment: "Мой отзыв 🎬\nВторая строка")
        #expect(try repository.rating(for: 62)?.comment == "Мой отзыв 🎬\nВторая строка")

        let updated = try repository.save(movie: movie(), rating: 9, comment: "Новое впечатление")
        #expect(updated.rating == 9)
        #expect(try repository.ratings(sortedBy: .newestFirst).count == 1)
        try repository.remove(movieID: 62)
        #expect(try repository.rating(for: 62) == nil)
        #expect(try repository.ratings(sortedBy: .newestFirst).isEmpty)
    }

    @Test func commentEditAndSameRatingKeepDate() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        let first = try repository.save(movie: movie(), rating: 8, comment: "")
        let updated = try repository.save(movie: movie(), rating: 8, comment: "Добавил комментарий")
        #expect(updated.ratedAt == first.ratedAt)
        #expect(updated.comment == "Добавил комментарий")
    }

    @Test(arguments: [0, 11, -1]) func invalidRatingDoesNotOverwriteRecord(value: Int) throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        _ = try repository.save(movie: movie(), rating: 8, comment: "Сохранённый комментарий")
        #expect(throws: AppError.self) {
            _ = try repository.save(movie: movie(), rating: value, comment: "Не должно сохраниться")
        }
        #expect(try repository.rating(for: 62)?.rating == 8)
        #expect(try repository.rating(for: 62)?.comment == "Сохранённый комментарий")
    }

    @Test func sortingUsesPersonalRating() throws {
        let container = try memoryContainer()
        let repository = RatingRepository(container: container)
        _ = try repository.save(movie: movie(1), rating: 10, comment: "")
        _ = try repository.save(movie: movie(3), rating: 5, comment: "")
        _ = try repository.save(movie: movie(2), rating: 5, comment: "")
        #expect(try repository.ratings(sortedBy: .highestFirst).map(\.rating) == [10, 5, 5])
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
            _ = try repository.save(movie: movie(), rating: 9, comment: "Осталось после перезапуска")
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

    @Test func settingsKeepSortOrder() throws {
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
    }
}
