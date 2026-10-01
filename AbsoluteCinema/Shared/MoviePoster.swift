import SwiftUI

// Общее оформление постера для поиска, карточки и списка оценок.
struct MoviePoster: View {
    let name: String?

    var body: some View {
        Group {
            if let name {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                // Если у мока нет постера, показываем нейтральную заглушку.
                ZStack {
                    Color("Surface")
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

struct MovieRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 14) {
            MoviePoster(name: movie.posterName)
                .frame(width: 54, height: 81)
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title).font(.headline)
                Text(movie.year.map(String.init) ?? "Год не указан")
                    .font(.caption)
                Text("TMDB: \(movie.rating.formatted(.number.precision(.fractionLength(1)))) / 10")
                    .font(.caption)
            }
            .foregroundStyle(Color("PrimaryText"))
        }
        .padding(.vertical, 4)
    }
}
