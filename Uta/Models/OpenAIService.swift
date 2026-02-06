import Foundation

enum OpenAIServiceError: Error {
    case missingApiKey
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
}

private struct GoogleAPIErrorResponse: Codable {
    struct ErrorBody: Codable {
        let code: Int?
        let message: String?
        let status: String?
    }

    let error: ErrorBody?
}

private struct GeminiCallsFile: Codable {
    let translations: GeminiCall
    let lyricsData: GeminiCall

    struct GeminiCall: Codable {
        let url: String
        let method: String?
        let timeoutSeconds: Double?
        let headers: [String: String]
        let bodyFile: String
    }
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiResponseContent
}

struct GeminiResponseContent: Codable {
    let parts: [GeminiResponsePart]
}

struct GeminiResponsePart: Codable {
    let text: String?
}

@Observable
final class OpenAIService {
    static let shared = OpenAIService()
    
    private var apiKey: String? {
        get {
            // First check UserDefaults
            if let stored = UserDefaults.standard.string(forKey: "google_gemini_api_key") {
                let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
            
            // Fallback: Check App.config via Secrets helper
            if let fileKey = Secrets.apiKey {
                let trimmed = fileKey.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, trimmed != "PASTE_YOUR_API_KEY_HERE" {
                    return trimmed
                }
            }
            
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "google_gemini_api_key")
        }
    }
    
    func setApiKey(_ key: String) {
        self.apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func hasApiKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - API Calls
    
    func generateTranslations(lyrics: String) async throws -> [Int: String] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenAIServiceError.missingApiKey
        }
        
        // 1. Prepare Input JSON
        let lines = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            
        var inputDict: [Int: String] = [:]
        for (index, line) in lines.enumerated() {
            inputDict[index] = line
        }
        
        guard let inputJsonData = try? JSONEncoder().encode(inputDict),
              let inputJsonString = String(data: inputJsonData, encoding: .utf8) else {
            throw OpenAIServiceError.decodingError(NSError(domain: "Encoding", code: -1))
        }

        let responseContent = try await sendRequest(
            callName: "translations",
            substitutions: [
                "{{INPUT_JSON}}": inputJsonString
            ]
        )
        
        // 4. Parse Response
        let cleanedJson = cleanJsonString(responseContent)
        guard let data = cleanedJson.data(using: .utf8) else {
             throw OpenAIServiceError.decodingError(NSError(domain: "StringData", code: -1))
        }
        
        do {
            let translations = try JSONDecoder().decode([String: String].self, from: data)
            // Convert String keys back to Int
            var result: [Int: String] = [:]
            for (key, value) in translations {
                if let index = Int(key) {
                    result[index] = value
                }
            }
            return result
        } catch {
             // Fallback: Try line by line split if JSON fails (Legacy support)
             print("⚠️ JSON Parse failed, trying line split fallback")
             let fallbackLines = responseContent.components(separatedBy: .newlines)
             var result: [Int: String] = [:]
             for (index, line) in fallbackLines.enumerated() {
                 result[index] = line
             }
             return result
        }
    }
    
    func generateLyricsData(lyrics: String) async throws -> [LyricsLine] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
             throw OpenAIServiceError.missingApiKey
        }
        
        let lines = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            
        var inputDict: [Int: String] = [:]
        for (index, line) in lines.enumerated() {
            inputDict[index] = line
        }
        
        guard let inputJsonData = try? JSONEncoder().encode(inputDict),
              let inputJsonString = String(data: inputJsonData, encoding: .utf8) else {
             throw OpenAIServiceError.decodingError(NSError(domain: "Encoding", code: -1))
        }
        
        let responseContent = try await sendRequest(
            callName: "lyricsData",
            substitutions: [
                "{{INPUT_JSON}}": inputJsonString,
                "{{LINE_COUNT}}": String(lines.count)
            ]
        )
        
        // Sanitization Logic (Ported from RN)
        var cleanContent = cleanJsonString(responseContent)
        
        // Fix "isHigh": low/high (unquoted)
        cleanContent = cleanContent.replacingOccurrences(of: "\"isHigh\":\\s*low\\b", with: "\"isHigh\":false", options: .regularExpression)
        cleanContent = cleanContent.replacingOccurrences(of: "\"isHigh\":\\s*high\\b", with: "\"isHigh\":true", options: .regularExpression)
        
        // Fix "isHigh": "low"/"high" (quoted)
        cleanContent = cleanContent.replacingOccurrences(of: "\"isHigh\":\\s*\"low\"", with: "\"isHigh\":false", options: .regularExpression)
        cleanContent = cleanContent.replacingOccurrences(of: "\"isHigh\":\\s*\"high\"", with: "\"isHigh\":true", options: .regularExpression)
        
        guard let data = cleanContent.data(using: .utf8) else {
             throw OpenAIServiceError.decodingError(NSError(domain: "StringData", code: -1))
        }
        
        // Decode as [String: LyricsLine]
        let parsedDict: [String: LyricsLine]
        do {
            parsedDict = try JSONDecoder().decode([String: LyricsLine].self, from: data)
        } catch let decodingError as DecodingError {
            let path: String
            let details: String

            switch decodingError {
            case .typeMismatch(_, let ctx):
                path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
                details = ctx.debugDescription
            case .valueNotFound(_, let ctx):
                path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
                details = ctx.debugDescription
            case .keyNotFound(let key, let ctx):
                path = (ctx.codingPath + [key]).map { $0.stringValue }.joined(separator: ".")
                details = "Missing key \(key.stringValue). \(ctx.debugDescription)"
            case .dataCorrupted(let ctx):
                path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
                details = ctx.debugDescription
            @unknown default:
                path = ""
                details = "Unknown decoding error"
            }
            throw OpenAIServiceError.decodingError(
                NSError(domain: "GeminiLyricsDataDecode", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Lyrics JSON decode failed at \(path.isEmpty ? "<root>" : path): \(details)"
                ])
            )
        }
        
        // Map back to array in order
        var resultLines: [LyricsLine] = []
        for i in 0..<lines.count {
            if let lineData = parsedDict[String(i)] {
                // Apply strict Kanji null check (Client-side validation)
                var fixedWords = lineData.words
                for j in 0..<fixedWords.count {
                    if let k = fixedWords[j].kanji, !containsKanji(k) {
                        print("Fixing incorrect kanji field: \"\(k)\" -> null")
                        fixedWords[j].kanji = nil
                    }
                }
                resultLines.append(LyricsLine(words: fixedWords))
            } else {
                // Fallback for missing line
                resultLines.append(LyricsLine(words: []))
            }
        }
        
        return resultLines
    }
    
    // MARK: - Private Helpers
    
    private func sendRequest(callName: String, substitutions: [String: String]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenAIServiceError.missingApiKey
        }

        // Entire call definition (URL + headers + body) lives in AI/GeminiCalls.json.
        // Some Xcode setups may flatten resources (no subdirectory), so try both.
        let callsURL =
            Bundle.main.url(forResource: "GeminiCalls", withExtension: "json", subdirectory: "AI")
            ?? Bundle.main.url(forResource: "GeminiCalls", withExtension: "json")

        guard let callsURL, let callsData = try? Data(contentsOf: callsURL) else {
            throw OpenAIServiceError.apiError(
                "Missing GeminiCalls.json in app bundle. Ensure AI/GeminiCalls.json is added to the Xcode project, has target membership for 'Uta', and is included in Build Phases > Copy Bundle Resources."
            )
        }

        let calls = try JSONDecoder().decode(GeminiCallsFile.self, from: callsData)
        let call: GeminiCallsFile.GeminiCall
        switch callName {
        case "translations":
            call = calls.translations
        case "lyricsData":
            call = calls.lyricsData
        default:
            throw OpenAIServiceError.apiError("Unknown Gemini call: \(callName)")
        }

        guard let url = URL(string: call.url) else {
            throw OpenAIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = (call.method ?? "POST")
        request.timeoutInterval = call.timeoutSeconds ?? 120

        // Headers (includes x-goog-api-key) live in GeminiCalls.json
        for (header, valueTemplate) in call.headers {
            let value = valueTemplate
                .replacingOccurrences(of: "{{API_KEY}}", with: apiKey)
            request.setValue(value, forHTTPHeaderField: header)
        }

        let bodyURL =
            Bundle.main.url(forResource: call.bodyFile, withExtension: nil, subdirectory: "AI")
            ?? Bundle.main.url(forResource: call.bodyFile, withExtension: nil)

        guard let bodyURL, var body = try? String(contentsOf: bodyURL, encoding: .utf8) else {
            throw OpenAIServiceError.apiError(
                "Missing \(call.bodyFile) in app bundle. Ensure Uta/AI/\(call.bodyFile) is included in Copy Bundle Resources."
            )
        }
        for (needle, replacement) in substitutions {
            if needle == "{{INPUT_JSON}}" {
                body = body.replacingOccurrences(of: needle, with: jsonEscapeForJSONStringValue(replacement))
            } else {
                body = body.replacingOccurrences(of: needle, with: replacement)
            }
        }
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw OpenAIServiceError.networkError(NSError(domain: "Network", code: -1))
        }
        
        if httpResponse.statusCode != 200 {
            let decoded = try? JSONDecoder().decode(GoogleAPIErrorResponse.self, from: data)
            let message = decoded?.error?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown Error"
            throw OpenAIServiceError.apiError("Status \(httpResponse.statusCode): \(message)")
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = apiResponse.candidates?.first?.content.parts.first?.text ?? ""
        if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            throw OpenAIServiceError.apiError("Gemini returned an empty response (possibly blocked by safety filters or invalid response format).")
        }
        return text
    }
    
    private func cleanJsonString(_ input: String) -> String {
        return input.replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func jsonEscapeForJSONStringValue(_ input: String) -> String {
        // Produces a JSON-safe string value (without surrounding quotes), e.g. turns " into \".
        // This is required because we embed {{INPUT_JSON}} inside the request body's JSON string field.
        if let data = try? JSONEncoder().encode(input),
           let quoted = String(data: data, encoding: .utf8),
           quoted.count >= 2 {
            return String(quoted.dropFirst().dropLast())
        }
        return input
    }
    
    private func containsKanji(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            let code = char.value
            if (code >= 0x4E00 && code <= 0x9FFF) ||
               (code >= 0x3400 && code <= 0x4DBF) {
                return true
            }
        }
        return false
    }
}
