import Foundation

// Обычная структура с информацией о фильме. Она не сохраняется сама по себе.
struct Movie: Identifiable, Equatable {
    let id: Int
    let title: String
    let originalTitle: String
    let year: Int?
    let runtime: Int?
    let overview: String
    let genres: [String]
    let rating: Double
    let voteCount: Int
    let posterName: String?
}
