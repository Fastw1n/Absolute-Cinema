import Foundation

// В учебной версии источником фильмов служит массив в MockMovies.
final class MovieRepository {
    func search(query: String) -> [Movie] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return []
        }

        return MockMovies.movies.filter { movie in
            movie.title.localizedCaseInsensitiveContains(text)
                || movie.originalTitle.localizedCaseInsensitiveContains(text)
        }
    }

    func movie(id: Int) -> Movie? {
        return MockMovies.movies.first { $0.id == id }
    }
}
