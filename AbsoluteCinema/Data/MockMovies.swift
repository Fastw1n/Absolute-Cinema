import Foundation

enum MockMovies {
    static let movies: [Movie] = [
        Movie(
            id: 62,
            title: "2001 год: Космическая одиссея",
            originalTitle: "2001: A Space Odyssey",
            year: 1968,
            runtime: 149,
            overview: "Экипаж корабля «Дискавери» отправляется в космос, чтобы исследовать загадочный монолит. На борту вместе с людьми работает компьютер HAL 9000.",
            genres: ["Фантастика", "Приключения"],
            rating: 8.0,
            voteCount: 12960,
            posterName: "SpaceOdyssey"
        ),
        Movie(
            id: 157336,
            title: "Интерстеллар",
            originalTitle: "Interstellar",
            year: 2014,
            runtime: 169,
            overview: "Группа исследователей отправляется за пределы Солнечной системы, чтобы найти новый дом для человечества.",
            genres: ["Фантастика", "Драма"],
            rating: 8.5,
            voteCount: 35000,
            posterName: nil
        ),
        Movie(
            id: 27205,
            title: "Начало",
            originalTitle: "Inception",
            year: 2010,
            runtime: 148,
            overview: "Команда специалистов проникает в чужие сны. На этот раз им нужно внедрить идею, а не украсть её.",
            genres: ["Фантастика", "Триллер"],
            rating: 8.4,
            voteCount: 38000,
            posterName: nil
        ),
        Movie(
            id: 603,
            title: "Матрица",
            originalTitle: "The Matrix",
            year: 1999,
            runtime: 136,
            overview: "Программист Нео узнаёт, что привычный мир является компьютерной симуляцией, и присоединяется к сопротивлению.",
            genres: ["Фантастика", "Боевик"],
            rating: 8.2,
            voteCount: 26000,
            posterName: nil
        )
    ]
}
