import Foundation

struct TMDBConfiguration {
    static func token(bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "TMDBConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let config = try? PropertyListDecoder().decode(Config.self, from: data) else { return nil }
        let token = config.readAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }

    private struct Config: Decodable {
        let readAccessToken: String
    }
}
