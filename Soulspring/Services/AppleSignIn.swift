import Foundation
import AuthenticationServices
import CryptoKit

/// Wraps `ASAuthorizationAppleIDProvider` to perform native Sign in with
/// Apple and surface the identity token for Supabase. We generate a nonce,
/// hash it for the Apple request, and pass the raw nonce to Supabase as
/// required by GoTrue's id_token grant.
@MainActor
final class AppleSignInCoordinator: NSObject, ObservableObject {
    typealias Completion = (Result<AppleResult, Error>) -> Void

    struct AppleResult {
        let identityToken: String
        let rawNonce: String
        let email: String?
        let fullName: String?
    }

    private var completion: Completion?
    private var currentRawNonce: String?

    func start(completion: @escaping Completion) {
        self.completion = completion

        let nonce = Self.randomNonce()
        currentRawNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: Nonce helpers

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess { fatalError("Unable to generate nonce.") }
            for r in randoms where remaining != 0 {
                if r < charset.count {
                    result.append(charset[Int(r)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard
                let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = cred.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = currentRawNonce
            else {
                completion?(.failure(NSError(domain: "AppleSignIn", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el token de Apple."])))
                return
            }
            let fullName: String? = {
                guard let name = cred.fullName else { return nil }
                let formatter = PersonNameComponentsFormatter()
                let assembled = formatter.string(from: name)
                return assembled.isEmpty ? nil : assembled
            }()
            completion?(.success(AppleResult(
                identityToken: token,
                rawNonce: nonce,
                email: cred.email,
                fullName: fullName
            )))
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            completion?(.failure(error))
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        // Best-effort window discovery from the connected scene.
        let scenes = UIApplication.shared.connectedScenes
        for case let scene as UIWindowScene in scenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
                return window
            }
        }
        return ASPresentationAnchor()
    }
}
