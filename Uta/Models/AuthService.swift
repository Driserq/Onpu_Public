import Foundation
import AuthenticationServices
import CryptoKit
import Security

enum AuthServiceError: Error {
    case missingIdentityToken
    case missingNonce
}

@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()

    static func generateRandomNonce(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        var remaining = length
        while remaining > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            if status != errSecSuccess {
                // Fallback; should be extremely rare.
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }

            randomBytes.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }

        return result
    }

    static func sha256Hex(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func authenticateAppleCredential(_ credential: ASAuthorizationAppleIDCredential, rawNonce: String) async throws {
        guard !rawNonce.isEmpty else { throw AuthServiceError.missingNonce }
        guard let tokenData = credential.identityToken else { throw AuthServiceError.missingIdentityToken }
        guard let identityToken = String(data: tokenData, encoding: .utf8), !identityToken.isEmpty else {
            throw AuthServiceError.missingIdentityToken
        }

        let resp = try await BackendClient.shared.authenticateApple(identityToken: identityToken, nonce: rawNonce)
        BackendClient.shared.setAccessToken(resp.accessToken)
    }
}
