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

@MainActor
private final class AppDependencies {
    let movies: any MovieRepositoryProtocol
    let ratings: RatingRepository
    let settings = SettingsStore()
    let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: RatedMovie.self)
        ratings = RatingRepository(container: container)
        movies = MovieRepository(client: MovieAPIClient(token: TMDBConfiguration.token()))
    }
}

private struct AppRootView: View {
    @State private var dependencies: AppDependencies?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let dependencies {
                MainTabs(dependencies: dependencies)
            } else if let errorMessage {
                ErrorNotice(message: errorMessage, retry: initialize)
            } else {
                ProgressView("Открытие приложения…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .task { if dependencies == nil { initialize() } }
    }

    private func initialize() {
        do {
            dependencies = try AppDependencies()
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось открыть хранилище оценок. Повторите запуск хранилища."
        }
    }
}

private struct MainTabs: View {
    let dependencies: AppDependencies
    @State private var search: SearchViewModel
    @State private var ratings: RatingsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _search = State(initialValue: SearchViewModel(repository: dependencies.movies))
        _ratings = State(initialValue: RatingsViewModel(repository: dependencies.ratings,
                                                       settings: dependencies.settings))
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

    private func details(id: Int) -> some View {
        MovieDetailsView(viewModel: MovieDetailsViewModel(
            movieID: id, movies: dependencies.movies, ratings: dependencies.ratings
        ))
    }
}
