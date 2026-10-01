import Foundation
import Observation
import SwiftData

@MainActor
protocol RatingRepositoryProtocol: AnyObject {
    var revision: Int { get }
    func rating(for movieID: Int) throws -> SavedRating?
    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating]
    func save(movie: Movie, rating: Int, comment: String) throws -> SavedRating
    func remove(movieID: Int) throws
}

/// Единственная точка CRUD. View и ViewModel не работают с ModelContext напрямую.
@MainActor
@Observable
final class RatingRepository: RatingRepositoryProtocol {
    private(set) var revision = 0
    private let context: ModelContext
    private let now: () -> Date

    init(container: ModelContainer, now: @escaping () -> Date = Date.init) {
        context = ModelContext(container)
        context.autosaveEnabled = false
        self.now = now
    }

    private func entry(for movieID: Int) throws -> RatedMovie? {
        let id = movieID
        var descriptor = FetchDescriptor<RatedMovie>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func rating(for movieID: Int) throws -> SavedRating? {
        try entry(for: movieID)?.snapshot
    }

    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating] {
        var descriptors: [SortDescriptor<RatedMovie>] = []
        if order == .highestFirst {
            descriptors.append(SortDescriptor(\RatedMovie.userRating, order: .reverse))
        }
        descriptors += [SortDescriptor(\RatedMovie.ratedAt, order: .reverse),
                        SortDescriptor(\RatedMovie.movieID)]
        return try context.fetch(FetchDescriptor(sortBy: descriptors)).map(\.snapshot)
    }

    func save(movie: Movie, rating: Int, comment: String) throws -> SavedRating {
        guard (1...10).contains(rating) else { throw AppError.invalidRating }
        let entry: RatedMovie
        if let existing = try self.entry(for: movie.id) {
            entry = existing
            if existing.userRating != rating { existing.ratedAt = now() }
            existing.userRating = rating
            existing.comment = comment
            existing.updateMovie(movie)
        } else {
            entry = RatedMovie(movie: movie, rating: rating, comment: comment, ratedAt: now())
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
