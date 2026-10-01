import Foundation

enum AppError: LocalizedError {
    case invalidRating

    var errorDescription: String? {
        return "Оценка должна быть от 1 до 10."
    }
}
