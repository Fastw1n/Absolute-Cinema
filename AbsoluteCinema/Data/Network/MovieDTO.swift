import Foundation

struct MovieListDTO: Decodable, Sendable {
    let results: [MovieDTO]
}

struct MovieDTO: Decodable, Sendable {
    struct Genre: Decodable, Sendable {
        let name: String
    }

    let id: Int
    let title: String
    let originalTitle: String?
    let releaseDate: String?
    let runtime: Int?
    let overview: String?
    let genres: [Genre]?
    let voteAverage: Double?
    let voteCount: Int?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id, title, runtime, overview, genres
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case posterPath = "poster_path"
    }

    var movie: Movie {
        Movie(
            id: id, title: title, originalTitle: originalTitle ?? title,
            year: releaseDate.flatMap { Int($0.prefix(4)) },
            runtime: runtime.flatMap { $0 > 0 ? $0 : nil },
            overview: overview ?? "", genres: genres?.map(\.name) ?? [],
            rating: voteAverage ?? 0, voteCount: voteCount ?? 0, posterPath: posterPath
        )
    }
}
