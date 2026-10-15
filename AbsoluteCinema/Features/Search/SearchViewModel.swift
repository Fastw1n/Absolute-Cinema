import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private let allMovies: [Movie]

    init(movies: [Movie] = MockMovies.movies) {
        allMovies = movies
    }

    var movies: [Movie] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return allMovies }
        return allMovies.filter {
            $0.title.localizedCaseInsensitiveContains(text)
                || $0.originalTitle.localizedCaseInsensitiveContains(text)
        }
    }
}
