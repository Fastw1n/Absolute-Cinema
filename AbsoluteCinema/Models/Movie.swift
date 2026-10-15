import Foundation

struct Movie: Identifiable, Hashable, Sendable {
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
