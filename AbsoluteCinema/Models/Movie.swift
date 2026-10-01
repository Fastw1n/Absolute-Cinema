import Foundation

struct MovieSummary: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let year: Int?
    let rating: Double
    let posterPath: String?
}

struct Movie: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let originalTitle: String
    let year: Int?
    let runtime: Int?
    let overview: String
    let genres: [String]
    let rating: Double
    let voteCount: Int
    let posterPath: String?

    var summary: MovieSummary {
        MovieSummary(id: id, title: title, year: year, rating: rating, posterPath: posterPath)
    }
}
