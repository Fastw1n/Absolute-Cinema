import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailsViewModel {
    let movie: Movie
    var draftRating = 0
    var comment = ""
    var storageError: String?
    private(set) var savedRating: SavedRating?
    private(set) var saveMessage: String?
    private(set) var isWatchlisted = false
    private let ratings: RatingRepository
    private let watchlist: WatchlistRepository
    private var didLoadRating = false

    init(movie: Movie, ratings: RatingRepository, watchlist: WatchlistRepository) {
        self.movie = movie
        self.ratings = ratings
        self.watchlist = watchlist
    }

    var repositoryRevision: Int { ratings.revision }
    var watchlistRevision: Int { watchlist.revision }

    var hasChanges: Bool {
        return draftRating != (savedRating?.rating ?? 0)
            || comment != (savedRating?.comment ?? "")
    }

    var canSave: Bool {
        return (1...10).contains(draftRating) && hasChanges
    }

    var metadata: String {
        let year = movie.year.map(String.init) ?? "Год не указан"
        if let runtime = movie.runtime {
            return "\(year) · \(runtime / 60) ч \(runtime % 60) мин"
        }
        return year
    }

    func loadRating() {
        // повторное обновление не должно стирать ещё не сохранённый комментарий
        if didLoadRating && hasChanges { return }
        do {
            savedRating = try ratings.rating(for: movie.id)
            draftRating = savedRating?.rating ?? 0
            comment = savedRating?.comment ?? ""
            didLoadRating = true
            storageError = nil
        } catch {
            storageError = "Не удалось прочитать вашу оценку."
        }
    }

    func loadWatchlist() {
        do {
            isWatchlisted = try watchlist.contains(movieID: movie.id)
        } catch {
            storageError = "Не удалось прочитать список желаемого."
        }
    }

    func toggleWatchlist() {
        do {
            if isWatchlisted {
                try watchlist.remove(movieID: movie.id)
            } else {
                try watchlist.add(movie)
            }
            isWatchlisted.toggle()
            storageError = nil
        } catch {
            storageError = "Не удалось изменить список желаемого."
        }
    }

    func save() -> Bool {
        guard canSave else { return false }
        do {
            savedRating = try ratings.save(movie: movie, rating: draftRating, comment: comment)
            saveMessage = "Оценка и комментарий сохранены"
            storageError = nil
            return true
        } catch {
            storageError = "Не удалось сохранить оценку. Изменения остались в форме."
            return false
        }
    }

    func discardRatingChanges() {
        draftRating = savedRating?.rating ?? 0
        comment = savedRating?.comment ?? ""
    }

    func removeRating() {
        do {
            try ratings.remove(movieID: movie.id)
            savedRating = nil
            draftRating = 0
            comment = ""
            saveMessage = nil
            storageError = nil
        } catch {
            storageError = "Не удалось удалить оценку."
        }
    }
}
