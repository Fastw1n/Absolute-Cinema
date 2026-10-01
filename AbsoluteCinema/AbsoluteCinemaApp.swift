import SwiftUI
import SwiftData

@main
struct AbsoluteCinemaApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .foregroundStyle(Color("PrimaryText"))
                .tint(Color.accentColor)
        }
    }
}

// Эти объекты общие для всех экранов и создаются один раз при запуске.
@MainActor
private final class AppData {
    let movies: MovieRepository
    let ratings: RatingRepository
    let settings = SettingsStore()
    let container: ModelContainer

    init() throws {
        // Отдельный файл базы для dev сохраняет данные версии из main.
        let configuration = ModelConfiguration("DevRatings")
        container = try ModelContainer(for: RatedMovie.self, configurations: configuration)
        ratings = RatingRepository(container: container)
        movies = MovieRepository()
    }
}

private struct AppRootView: View {
    @State private var appData: AppData?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let appData {
                MainTabs(appData: appData)
            } else if let errorMessage {
                ErrorNotice(message: errorMessage, retry: initialize)
            } else {
                ProgressView("Открытие приложения…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .onAppear { if appData == nil { initialize() } }
    }

    private func initialize() {
        do {
            appData = try AppData()
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось открыть хранилище оценок. Повторите запуск хранилища."
        }
    }
}

private struct MainTabs: View {
    let appData: AppData
    // @State сохраняет ViewModel между перерисовками интерфейса.
    @State private var search: SearchViewModel
    @State private var ratings: RatingsViewModel

    init(appData: AppData) {
        self.appData = appData
        _search = State(initialValue: SearchViewModel(repository: appData.movies))
        _ratings = State(initialValue: RatingsViewModel(repository: appData.ratings,
                                                       settings: appData.settings))
    }

    var body: some View {
        TabView {
            NavigationStack {
                SearchView(viewModel: search)
                    .navigationDestination(for: Int.self, destination: details)
            }
            .tabItem { Label("Поиск", systemImage: "magnifyingglass") }

            NavigationStack {
                RatingsView(viewModel: ratings)
                    .navigationDestination(for: Int.self, destination: details)
            }
            .tabItem { Label("Мои оценки", systemImage: "star") }
        }
        .toolbarBackground(Color("Surface"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    @ViewBuilder
    private func details(id: Int) -> some View {
        if let movie = appData.movies.movie(id: id) {
            MovieDetailsView(viewModel: MovieDetailsViewModel(
                movie: movie, ratings: appData.ratings
            ))
        } else {
            ContentUnavailableView("Фильм не найден", systemImage: "film")
        }
    }
}
