import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailsViewModel {
    let movieID: Int
    var draftRating = 0
    var comment = ""
    private(set) var movie: Movie?
    private(set) var savedRating: SavedRating?
    private(set) var isLoading = false
    private(set) var isSavedCopy = false
    private(set) var loadError: String?
    var storageError: String?
    private(set) var saveMessage: String?

    private let movies: any MovieRepositoryProtocol
    private let ratings: any RatingRepositoryProtocol
    private var didLoadPersonalData = false

    init(movieID: Int, movies: any MovieRepositoryProtocol, ratings: any RatingRepositoryProtocol) {
        self.movieID = movieID
        self.movies = movies
        self.ratings = ratings
    }

    var repositoryRevision: Int { ratings.revision }

    var hasChanges: Bool {
        draftRating != (savedRating?.rating ?? 0) || comment != (savedRating?.comment ?? "")
    }

    var canSave: Bool { (1...10).contains(draftRating) && hasChanges && movie != nil }

    var metadata: String {
        guard let movie else { return "" }
        let year = movie.year.map(String.init) ?? "Год не указан"
        guard let runtime = movie.runtime else { return year }
        return "\(year) · \(runtime / 60) ч \(runtime % 60) мин"
    }

    func refreshPersonalData() {
        guard !didLoadPersonalData || !hasChanges else { return }
        do {
            savedRating = try ratings.rating(for: movieID)
            draftRating = savedRating?.rating ?? 0
            comment = savedRating?.comment ?? ""
            didLoadPersonalData = true
            if movie == nil, let savedRating {
                movie = savedRating.movie
                isSavedCopy = true
            }
        } catch {
            storageError = "Не удалось прочитать вашу оценку. Попробуйте открыть карточку ещё раз."
        }
    }

    func load() async {
        refreshPersonalData()
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let result = try await movies.details(id: movieID)
            try Task.checkCancellation()
            movie = result
            isSavedCopy = false
        } catch {
            guard !Task.isCancelled else { return }
            loadError = AppError.message(for: error)
        }
    }

    func save() {
        guard let movie else { return }
        do {
            let saved = try ratings.save(movie: movie, rating: draftRating, comment: comment)
            savedRating = saved
            saveMessage = "Оценка и комментарий сохранены"
        } catch {
            storageError = error is AppError ? AppError.message(for: error)
                : "Не удалось сохранить оценку и комментарий. Изменения остались в форме — повторите сохранение."
        }
    }

    func removeRating() {
        do {
            try ratings.remove(movieID: movieID)
            savedRating = nil
            draftRating = 0
            comment = ""
            saveMessage = nil
        } catch {
            storageError = "Не удалось удалить оценку. Попробуйте ещё раз."
        }
    }
}
