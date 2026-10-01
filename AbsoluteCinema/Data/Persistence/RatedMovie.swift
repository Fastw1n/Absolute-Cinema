import Foundation
import SwiftData

// @Model сообщает SwiftData, что объекты этого класса нужно хранить в базе.
@Model
final class RatedMovie {
    @Attribute(.unique) var movieID: Int
    var title: String
    var originalTitle: String
    var year: Int?
    var runtime: Int?
    var overview: String
    var genres: [String]
    var tmdbRating: Double
    var voteCount: Int
    var posterName: String?
    var userRating: Int
    var comment: String
    var ratedAt: Date

    init(movie: Movie, rating: Int, comment: String, ratedAt: Date) {
        movieID = movie.id
        title = movie.title
        originalTitle = movie.originalTitle
        year = movie.year
        runtime = movie.runtime
        overview = movie.overview
        genres = movie.genres
        tmdbRating = movie.rating
        voteCount = movie.voteCount
        posterName = movie.posterName
        userRating = rating
        self.comment = comment
        self.ratedAt = ratedAt
    }

    // Для экрана возвращаем обычную структуру: он не меняет объект базы напрямую.
    var snapshot: SavedRating {
        SavedRating(
            movie: Movie(
                id: movieID,
                title: title,
                originalTitle: originalTitle,
                year: year,
                runtime: runtime,
                overview: overview,
                genres: genres,
                rating: tmdbRating,
                voteCount: voteCount,
                posterName: posterName
            ),
            rating: userRating,
            comment: comment,
            ratedAt: ratedAt
        )
    }

    func updateMovie(_ movie: Movie) {
        title = movie.title
        originalTitle = movie.originalTitle
        year = movie.year
        runtime = movie.runtime
        overview = movie.overview
        genres = movie.genres
        tmdbRating = movie.rating
        voteCount = movie.voteCount
        posterName = movie.posterName
    }
}
