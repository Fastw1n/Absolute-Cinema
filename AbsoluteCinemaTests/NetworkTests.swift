import Foundation
import Testing
@testable import AbsoluteCinema

private final class TestBundleMarker: NSObject {}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (response, data) = try Self.handler!(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct NetworkTests {
    private func client() -> MovieAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return MovieAPIClient(token: "test-token", session: URLSession(configuration: config))
    }

    @Test func originalResponseDecodesIntoMovie() throws {
        let url = try #require(Bundle(for: TestBundleMarker.self)
            .url(forResource: "space-odyssey", withExtension: "json"))
        let dto = try JSONDecoder().decode(MovieDTO.self, from: Data(contentsOf: url))
        #expect(dto.movie.id == 62)
        #expect(dto.movie.year == 1968)
        #expect(dto.movie.runtime == 149)
        #expect(dto.movie.genres.count == 3)
        #expect(dto.movie.posterPath != nil)
    }

    @Test func missingOptionalFieldsDecodeWithoutInventingYear() throws {
        let dto = try JSONDecoder().decode(MovieDTO.self, from: Data(#"{"id":1,"title":"Фильм","release_date":"","poster_path":null}"#.utf8))
        #expect(dto.movie.year == nil)
        #expect(dto.movie.runtime == nil)
        #expect(dto.movie.posterPath == nil)
        #expect(dto.movie.overview.isEmpty)
    }

    @Test func searchEncodesQueryAndAuthorizesRequest() async throws {
        StubURLProtocol.handler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            let url = try #require(request.url)
            #expect(url.path == "/3/search/movie")
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            #expect(items?.first(where: { $0.name == "query" })?.value == "Космос & 2001")
            #expect(items?.first(where: { $0.name == "language" })?.value == "ru-RU")
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data(#"{"results":[{"id":62,"title":"Фильм"}]}"#.utf8))
        }
        let results = try await client().search(query: "Космос & 2001")
        #expect(results.map(\.id) == [62])
    }

    @Test func nonSuccessHTTPStatusThrows() async {
        StubURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, Data())
        }
        await #expect(throws: AppError.self) {
            try await client().details(id: 62)
        }
    }

    @Test func malformedJSONThrows() async {
        StubURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("invalid".utf8))
        }
        await #expect(throws: AppError.self) {
            try await client().details(id: 62)
        }
    }
}
