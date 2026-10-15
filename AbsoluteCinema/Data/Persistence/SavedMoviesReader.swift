import Foundation
import SwiftData

@ModelActor
actor SavedMoviesReader {
    func ratings(sortedBy order: RatingSortOrder) throws -> [SavedRating] {
        var descriptors: [SortDescriptor<RatedMovie>] = []
        if order == .highestFirst {
            descriptors.append(SortDescriptor(\RatedMovie.userRating, order: .reverse))
        }
        descriptors += [SortDescriptor(\RatedMovie.ratedAt, order: .reverse),
                        SortDescriptor(\RatedMovie.movieID)]
        return try modelContext.fetch(FetchDescriptor(sortBy: descriptors)).map(\.snapshot)
    }

    func watchlist() throws -> [Movie] {
        let descriptor = FetchDescriptor<WatchlistMovie>(sortBy: [
            SortDescriptor(\WatchlistMovie.addedAt, order: .reverse),
            SortDescriptor(\WatchlistMovie.movieID)
        ])
        return try modelContext.fetch(descriptor).map(\.movie)
    }
}
