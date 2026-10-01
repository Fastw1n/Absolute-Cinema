import SwiftUI

struct MoviePoster: View {
    let path: String?

    private var url: URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                ZStack {
                    Color("Surface")
                    if url != nil, phase.error == nil {
                        ProgressView()
                    } else {
                        Image(systemName: "film")
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct MovieRow: View {
    let movie: MovieSummary

    var body: some View {
        HStack(spacing: 14) {
            MoviePoster(path: movie.posterPath)
                .frame(width: 54, height: 81)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title).font(.headline)
                HStack {
                    Text(movie.year.map(String.init) ?? "Год не указан")
                    if movie.rating > 0 {
                        Text("TMDB \(movie.rating.formatted(.number.precision(.fractionLength(1))))")
                    }
                }
                .font(.caption).foregroundStyle(Color("SecondaryText"))
            }
        }
        .padding(.vertical, 4)
    }
}
