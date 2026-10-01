import Foundation
import Observation
import SwiftData

/// Единственная точка CRUD. View и ViewModel не работают с ModelContext напрямую.
@MainActor
@Observable
final class RatingRepository {
    // После сохранения или удаления это число меняется: экраны перечитывают оценки.
    private(set) var revision = 0
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    private func entry(for movieID: Int) throws -> RatedMovie? {
        let id = movieID
        var descriptor = FetchDescriptor<RatedMovie>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // Read: найти одну сохранённую оценку по ID фильма.
    func rating(for movieID: Int) throws -> SavedRating? {
        try entry(for: movieID)?.snapshot
    }

    // Read: прочитать все оценки в выбранном порядке.
    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating] {
        var descriptors: [SortDescriptor<RatedMovie>] = []
        if order == .highestFirst {
            descriptors.append(SortDescriptor(\RatedMovie.userRating, order: .reverse))
        }
        descriptors += [SortDescriptor(\RatedMovie.ratedAt, order: .reverse),
                        SortDescriptor(\RatedMovie.movieID)]
        return try context.fetch(FetchDescriptor(sortBy: descriptors)).map(\.snapshot)
    }

    // Create или Update: для одного фильма хранится только одна запись.
    func save(movie: Movie, rating: Int, comment: String) throws -> SavedRating {
        guard (1...10).contains(rating) else { throw AppError.invalidRating }
        let entry: RatedMovie
        if let existing = try self.entry(for: movie.id) {
            entry = existing
            // Изменение только комментария не меняет дату выставления оценки.
            if existing.userRating != rating {
                existing.ratedAt = Date()
            }
            existing.userRating = rating
            existing.comment = comment
            existing.updateMovie(movie)
        } else {
            entry = RatedMovie(movie: movie, rating: rating, comment: comment, ratedAt: Date())
            context.insert(entry)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
        return entry.snapshot
    }

    // Delete: удалить запись с оценкой и комментарием.
    func remove(movieID: Int) throws {
        guard let entry = try entry(for: movieID) else { return }
        context.delete(entry)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }
}
