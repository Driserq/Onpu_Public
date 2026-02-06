import Foundation

struct Secrets {
    private static func loadConfig() -> [String: String]? {
        guard let url = Bundle.main.url(forResource: "App", withExtension: "config"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return json
    }

    static var apiKey: String? {
        guard let json = loadConfig() else { return nil }
        return json["google_gemini_api_key"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var tarukingu: String? {
        guard let json = loadConfig() else { return nil }
        return json["tarukingu"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
