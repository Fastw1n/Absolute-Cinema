import Foundation

enum AppError: LocalizedError {
    case missingToken
    case invalidResponse
    case httpStatus(Int)
    case invalidRating

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Не настроен доступ к TMDB. Добавьте токен в TMDBConfig.plist по инструкции в README."
        case .invalidResponse:
            return "Не удалось прочитать данные фильма. Попробуйте ещё раз."
        case .httpStatus(401), .httpStatus(403):
            return "TMDB отклонил запрос. Проверьте токен и доступ к сервису."
        case .httpStatus(429):
            return "Слишком много запросов. Повторите поиск немного позже."
        case .httpStatus:
            return "Сервис фильмов недоступен. Попробуйте ещё раз."
        case .invalidRating:
            return "Оценка должна быть от 1 до 10."
        }
    }

    static func message(for error: Error) -> String {
        if error is URLError {
            return "Не удалось подключиться к TMDB. Проверьте интернет и повторите запрос."
        }
        if let error = error as? AppError {
            return error.localizedDescription
        }
        return "Не удалось выполнить операцию. Попробуйте ещё раз."
    }
}
