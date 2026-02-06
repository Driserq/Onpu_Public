import Foundation

struct CreateJobResponse: Codable {
    let jobId: String
    let status: String
}

struct LyricsJobResultPayload: Codable {
    let translations: [String: String]
    let lyricsData: [String: LyricsDataValue]
    
    /// Union type for lyricsData - can be either compact format string or verbose LyricsLine
    enum LyricsDataValue: Codable {
        case compact(String)
        case verbose(LyricsLine)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            // Try to decode as string first (compact format)
            if let str = try? container.decode(String.self) {
                // Detect if it's compact format (contains pipes, no JSON braces)
                if str.contains("|") && !str.contains("{") && !str.contains("[") {
                    self = .compact(str)
                } else {
                    // Try parsing as JSON string containing LyricsLine
                    if let data = str.data(using: .utf8),
                       let line = try? JSONDecoder().decode(LyricsLine.self, from: data) {
                        self = .verbose(line)
                    } else {
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "String is neither compact format nor valid JSON LyricsLine"
                        )
                    }
                }
            } else {
                // Try to decode as LyricsLine object directly
                let line = try container.decode(LyricsLine.self)
                self = .verbose(line)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .compact(let str):
                try container.encode(str)
            case .verbose(let line):
                try container.encode(line)
            }
        }
    }
}

struct GetJobResponse: Codable {
    let jobId: String
    let status: String
    let stage: String?
    let updatedAt: Int?
    let result: LyricsJobResultPayload?
    let error: String?
}

struct AckJobResponse: Codable {
    let ok: Bool
}

struct JobChange: Codable {
    let jobId: String
    let status: String
    let stage: String?
    let updatedAt: Int
    let error: String?
}

struct LongpollPendingResponse: Codable {
    let changes: [JobChange]
    let hasPending: Bool
}

struct RecentJobsResponse: Codable {
    let changes: [JobChange]
}
