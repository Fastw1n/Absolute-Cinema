import Foundation

enum TMDBError: LocalizedError {
    case configuration
    case unauthorized
    case notFound
    case tooManyRequests
    case unavailable
    case invalidResponse
    case connection
    case timeout

    var errorDescription: String? {
        switch self {
        case .configuration:
            "Не удалось подключиться к каталогу фильмов."
        case .unauthorized:
            "Сервис фильмов отклонил доступ."
        case .notFound:
            "Фильм больше не доступен в каталоге."
        case .tooManyRequests:
            "Слишком много запросов. Попробуйте немного позже."
        case .unavailable:
            "Сервис фильмов временно недоступен. Попробуйте ещё раз."
        case .invalidResponse:
            "Не удалось прочитать ответ сервиса фильмов."
        case .connection:
            "Не удалось связаться с сервисом фильмов. Проверьте подключение к интернету."
        case .timeout:
            "Сервис фильмов не ответил вовремя. Попробуйте ещё раз."
        }
    }
}
