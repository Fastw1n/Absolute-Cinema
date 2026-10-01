import Foundation

/// Ожидание сети и декодирование изолированы от MainActor.
actor MovieAPIClient {
    private let session: URLSession
    private let token: String?

    init(token: String?, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    func search(query: String) async throws -> [MovieSummary] {
        let response: MovieListDTO = try await request(
            path: "search/movie", parameters: [URLQueryItem(name: "query", value: query)]
        )
        return response.results.map { $0.movie.summary }
    }

    func details(id: Int) async throws -> Movie {
        let response: MovieDTO = try await request(path: "movie/\(id)")
        return response.movie
    }

    private func request<T: Decodable & Sendable>(
        path: String, parameters: [URLQueryItem] = []
    ) async throws -> T {
        guard let token, !token.isEmpty else { throw AppError.missingToken }
        var components = URLComponents(string: "https://api.themoviedb.org/3/\(path)")!
        components.queryItems = [URLQueryItem(name: "language", value: "ru-RU")] + parameters
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 25
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw AppError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            throw AppError.httpStatus(response.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.invalidResponse
        }
    }
}
