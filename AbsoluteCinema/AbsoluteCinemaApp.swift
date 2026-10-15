import SwiftData
import SwiftUI

@main
@MainActor
struct AbsoluteCinemaApp: App {
    private let repository: RatingRepository?
    private let watchlist: WatchlistRepository?
    private let client = TMDBClient()

    init() {
        do {
            let configuration = ModelConfiguration("DevRatings")
            let container = try ModelContainer(for: RatedMovie.self, WatchlistMovie.self,
                                               configurations: configuration)

            repository = RatingRepository(container: container)
            watchlist = WatchlistRepository(container: container)
        } catch {
            repository = nil
            watchlist = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let repository, let watchlist {
                ContentView(repository: repository, watchlist: watchlist, client: client)
                    .preferredColorScheme(.dark)
                    .foregroundStyle(Color("PrimaryText"))
                    .tint(Color.accentColor)
            } else {
                Text("Не удалось открыть хранилище оценок. Перезапустите приложение.")
                    .padding()
            }
        }
    }
}
