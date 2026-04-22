import Foundation
import AuthenticationServices

/// Generic OAuth via Supabase using `ASWebAuthenticationSession` — no
/// external SDK needed. Works for any provider you've enabled in the
/// Supabase dashboard (Google, GitHub, Discord, etc.).
///
/// Flow:
/// 1. Open `{supabase}/auth/v1/authorize?provider=...&redirect_to=...`
/// 2. The user signs in inside an ephemeral SFSafariViewController
/// 3. Supabase redirects back to our custom URL scheme with an
///    `access_token` and `refresh_token` in the URL fragment
/// 4. We parse those and report success
@MainActor
final class OAuthSignInCoordinator: NSObject, ObservableObject {
    typealias Completion = (Result<OAuthSession, Error>) -> Void

    struct OAuthSession {
        let accessToken: String
        let refreshToken: String?
        let providerToken: String?
    }

    enum Provider: String {
        case google
        case github
        case discord
        case facebook
        case azure
    }

    /// Custom URL scheme registered in Info.plist. Supabase will redirect
    /// here at the end of the OAuth flow.
    static let redirectScheme = "mx.soulspring.app"
    static let redirectURI = "\(redirectScheme)://oauth-callback"

    private var session: ASWebAuthenticationSession?

    func start(provider: Provider, completion: @escaping Completion) {
        guard SupabaseConfig.isConfigured,
              var components = URLComponents(string: SupabaseConfig.url) else {
            completion(.failure(OAuthError.notConfigured))
            return
        }
        components.path = "/auth/v1/authorize"
        components.queryItems = [
            URLQueryItem(name: "provider", value: provider.rawValue),
            URLQueryItem(name: "redirect_to", value: Self.redirectURI),
        ]
        guard let url = components.url else {
            completion(.failure(OAuthError.notConfigured))
            return
        }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Self.redirectScheme
        ) { [weak self] callback, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    let nsErr = error as NSError
                    if nsErr.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return  // user cancelled — silent
                    }
                    completion(.failure(error))
                    return
                }
                guard let callback,
                      let parsed = self.parse(callback: callback) else {
                    completion(.failure(OAuthError.missingTokens))
                    return
                }
                completion(.success(parsed))
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.session = session
        session.start()
    }

    private func parse(callback: URL) -> OAuthSession? {
        // Supabase puts tokens in the URL FRAGMENT, not the query.
        guard let fragment = callback.fragment else { return nil }
        var values: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2,
                  let v = kv[1].removingPercentEncoding else { continue }
            values[kv[0]] = v
        }
        guard let access = values["access_token"] else { return nil }
        return OAuthSession(
            accessToken: access,
            refreshToken: values["refresh_token"],
            providerToken: values["provider_token"]
        )
    }
}

enum OAuthError: LocalizedError {
    case notConfigured
    case missingTokens
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase no está configurado."
        case .missingTokens: return "El proveedor no devolvió un token válido."
        }
    }
}

extension OAuthSignInCoordinator: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        for case let scene as UIWindowScene in scenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
                return window
            }
        }
        return ASPresentationAnchor()
    }
}
