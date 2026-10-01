import Foundation

protocol MovieRepositoryProtocol: Sendable {
    func search(query: String) async throws -> [MovieSummary]
    func details(id: Int) async throws -> Movie
}

struct MovieRepository: MovieRepositoryProtocol {
    let client: MovieAPIClient

    func search(query: String) async throws -> [MovieSummary] {
        try await client.search(query: query)
    }

    func details(id: Int) async throws -> Movie {
        try await client.details(id: id)
    }
}
