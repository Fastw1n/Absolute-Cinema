import Foundation

// Actor выполняет обработку ответов отдельно от состояния интерфейса на MainActor.
actor TMDBClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchMovies(query: String) async throws -> [Movie] {
        let response: TMDBMovieListResponse = try await get(
            path: "search/movie",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        return response.results.map { $0.movie(hasDetails: false) }
    }

    func movie(id: Int) async throws -> Movie {
        let response: TMDBMovieResponse = try await get(path: "movie/\(id)")
        guard response.id == id else { throw TMDBError.invalidResponse }
        return response.movie(hasDetails: true)
    }

    private func get<Response: Decodable & Sendable>(
        path: String, queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try Task.checkCancellation()
        let configuration = try TMDBConfiguration.load()
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.path = "/3/\(path)"
        components.queryItems = [URLQueryItem(name: "language", value: "ru-RU")] + queryItems

        let token = configuration.readAccessToken.flatMap { $0.isEmpty ? nil : $0 }
        if token == nil, let key = configuration.apiKey, !key.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: key))
        }
        guard let url = components.url else { throw TMDBError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else {
                throw TMDBError.invalidResponse
            }
            switch response.statusCode {
            case 200..<300: break
            case 401, 403: throw TMDBError.unauthorized
            case 404: throw TMDBError.notFound
            case 429: throw TMDBError.tooManyRequests
            default: throw TMDBError.unavailable
            }
            return try JSONDecoder().decode(Response.self, from: data)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            if error.code == .timedOut { throw TMDBError.timeout }
            throw TMDBError.connection
        } catch is DecodingError {
            throw TMDBError.invalidResponse
        }
    }
}
