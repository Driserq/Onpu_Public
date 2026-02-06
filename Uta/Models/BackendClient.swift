import Foundation
import SwiftUI

enum BackendClientError: Error {
    case invalidURL
    case missingAuth
    case missingAppAuth
    case httpError(Int, String)
    case decodingError(Error)
}

final class BackendClient {
    static let shared = BackendClient()

    #if DEBUG
    @AppStorage("backend_base_url_override") private var baseURLOverride: String = ""
    #endif

    var baseURL: URL {
        #if DEBUG
        let trimmed = baseURLOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let url = URL(string: trimmed) {
            return url
        }
        return URL(string: "https://app.onpu.app")!
        #else
        return URL(string: "https://app.onpu.app")!
        #endif
    }

    @AppStorage("backend_access_token") private var accessToken: String = ""
    @AppStorage("backend_last_status_code") private var lastStatusCode: Int = 0

    // Dev bypass (backend must enable ALLOW_DEV_BYPASS)
    #if DEBUG
    @AppStorage("backend_dev_token") private var devToken: String = ""

    private var effectiveDevToken: String {
        if !devToken.isEmpty { return devToken }
        // Hardcoded DEBUG-only token for local testing.
        return "dev123"
    }
    #endif

    func setAccessToken(_ token: String) {
        accessToken = token
    }

    func clearAccessToken() {
        accessToken = ""
    }

    func getLastStatusCode() -> Int {
        lastStatusCode
    }

    func hasSession() -> Bool {
        #if DEBUG
        if !effectiveDevToken.isEmpty { return true }
        #endif
        return !accessToken.isEmpty
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw BackendClientError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let appAuth = Secrets.tarukingu, !appAuth.isEmpty else {
            throw BackendClientError.missingAppAuth
        }
        req.setValue(appAuth, forHTTPHeaderField: "tarukingu")

        #if DEBUG
        if !accessToken.isEmpty {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            let tok = effectiveDevToken
            if !tok.isEmpty {
                req.setValue(tok, forHTTPHeaderField: "X-Dev-Token")
            }
        }
        #else
        guard !accessToken.isEmpty else { throw BackendClientError.missingAuth }
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        #endif

        req.httpBody = body
        return req
    }

    private func makePublicRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw BackendClientError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let appAuth = Secrets.tarukingu, !appAuth.isEmpty else {
            throw BackendClientError.missingAppAuth
        }
        req.setValue(appAuth, forHTTPHeaderField: "tarukingu")
        req.httpBody = body
        return req
    }

    private func decodeOrThrow<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw BackendClientError.decodingError(error)
        }
    }

    private func recordStatusAndHandleAuthFailure(status: Int) {
        lastStatusCode = status
        if status == 401 {
            clearAccessToken()
        }
    }

    struct AppleAuthResponse: Codable {
        let accessToken: String
        let expiresIn: Int?
    }

    struct AuthMeResponse: Codable {
        let ok: Bool
        let sub: String
    }

    func authenticateApple(identityToken: String, nonce: String) async throws -> AppleAuthResponse {
        let payload = try JSONEncoder().encode([
            "identityToken": identityToken,
            "nonce": nonce
        ])
        let req = try makePublicRequest(path: "/v1/auth/apple", method: "POST", body: payload)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(AppleAuthResponse.self, from: data)
    }

    func authMe() async throws -> AuthMeResponse {
        let req = try makeRequest(path: "/v1/auth/me")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(AuthMeResponse.self, from: data)
    }

    func createJob(title: String, artist: String, lyrics: String) async throws -> CreateJobResponse {
        let payload = try JSONEncoder().encode([
            "title": title,
            "artist": artist,
            "lyrics": lyrics
        ])
        let req = try makeRequest(path: "/v1/jobs", method: "POST", body: payload)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(CreateJobResponse.self, from: data)
    }

    func getJob(jobId: String) async throws -> GetJobResponse {
        let req = try makeRequest(path: "/v1/jobs/\(jobId)")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(GetJobResponse.self, from: data)
    }

    func ackJob(jobId: String) async throws {
        let req = try makeRequest(path: "/v1/jobs/\(jobId)/ack", method: "POST", body: Data("{}".utf8))
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        _ = try decodeOrThrow(AckJobResponse.self, from: data)
    }

    func longpollPendingJobs(timeoutSeconds: Int, sinceMs: Int, limit: Int) async throws -> LongpollPendingResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/v1/jobs/pending/longpoll"), resolvingAgainstBaseURL: true)
        comps?.queryItems = [
            URLQueryItem(name: "timeout", value: String(timeoutSeconds)),
            URLQueryItem(name: "since", value: String(sinceMs)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = comps?.url else { throw BackendClientError.invalidURL }

        var req = try makeRequest(path: url.absoluteString.replacingOccurrences(of: baseURL.absoluteString, with: ""))
        req.timeoutInterval = TimeInterval(timeoutSeconds + 10)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(LongpollPendingResponse.self, from: data)
    }

    func getRecentJobs(sinceMs: Int, limit: Int) async throws -> RecentJobsResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/v1/jobs/recent"), resolvingAgainstBaseURL: true)
        comps?.queryItems = [
            URLQueryItem(name: "since", value: String(sinceMs)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = comps?.url else { throw BackendClientError.invalidURL }

        let req = try makeRequest(path: url.absoluteString.replacingOccurrences(of: baseURL.absoluteString, with: ""))
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
        recordStatusAndHandleAuthFailure(status: status)
        guard status >= 200 && status < 300 else {
            throw BackendClientError.httpError(status, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeOrThrow(RecentJobsResponse.self, from: data)
    }
}
