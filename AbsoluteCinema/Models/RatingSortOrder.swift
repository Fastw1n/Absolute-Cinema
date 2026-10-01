import Foundation

enum RatingSortOrder: String, CaseIterable, Identifiable {
    case newestFirst
    case highestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newestFirst: "Сначала недавние"
        case .highestFirst: "Сначала высокая оценка"
        }
    }
}

struct SavedRating: Identifiable, Equatable, Sendable {
    let movie: Movie
    let rating: Int
    let comment: String
    let ratedAt: Date

    var id: Int { movie.id }
}
