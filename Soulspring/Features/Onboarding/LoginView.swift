import SwiftUI
import AuthenticationServices

/// Login / sign-up. Mimo-style layout:
/// - Brand mark (logo + "Soulspring") at the top
/// - Hero headline in the middle inviting the user to create their profile
/// - Apple / Google as outlined pill chips
/// - "Continuar con correo" as the big primary pill — opens the email form
///   (email + password) which on submit kicks off Supabase signup/signin and
///   then drops the user into the cuestionario.
/// - "Ver sin cuenta" tucked just under the email button as a quiet escape.
/// - Footer toggles between create-account and sign-in modes.
struct LoginView: View {
    @EnvironmentObject private var store: AppStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreatingAccount: Bool = true
    @State private var isShowingEmailForm: Bool = false
    @State private var isWorking: Bool = false
    @State private var authError: String? = nil
    @State private var infoMessage: String? = nil
    @State private var isShowingOAuthSoon: Bool = false
    @StateObject private var appleSignIn = AppleSignInCoordinator()
    @StateObject private var oauthSignIn = OAuthSignInCoordinator()

    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                brandHero
                    .padding(.horizontal, SoulTheme.Spacing.lg)

                VStack(spacing: 14) {
                    if isShowingEmailForm {
                        emailForm
                    } else {
                        socialButtons
                        orDivider
                        emailPrimaryButton
                        guestButton
                    }
                }
                .padding(.horizontal, SoulTheme.Spacing.lg)
                .padding(.top, 24)

                Spacer(minLength: 18)

                footerLink
                    .padding(.bottom, SoulTheme.Spacing.md)
            }
        }
        .alert("Próximamente", isPresented: $isShowingOAuthSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Inicio con Apple y Google se conectará en una siguiente versión. Por ahora usa tu correo.")
        }
    }

    // MARK: Brand hero — logo + Soulspring (big) + Beyond Wellness

    private var brandHero: some View {
        VStack(spacing: 12) {
            Image("BrandLogo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 170, height: 170)

            VStack(spacing: 6) {
                Text("Soulspring")
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Palette.ink)

                Text("\u{201C}Beyond Wellness\u{201D}")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Color.primary)

                Text(isCreatingAccount
                     ? "Crea tu perfil y empieza\ntu camino hacia adentro."
                     : "Bienvenido de vuelta.\nRespira, ya llegaste.")
                    .font(SoulTheme.Font.bodyText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineSpacing(2)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: Social buttons (Apple + Google as outlined chips, side by side)

    private var socialButtons: some View {
        HStack(spacing: 12) {
            applePill
            socialPill(emoji: "G", fg: SoulTheme.Color.textPrimary, action: {
                startGoogleSignIn()
            })
        }
    }

    private func startGoogleSignIn() {
        oauthSignIn.start(provider: .google) { result in
            Task { @MainActor in
                isWorking = true
                authError = nil
                defer { isWorking = false }
                switch result {
                case .success(let session):
                    store.signInWithOAuth(session: session, providerLabel: "google")
                case .failure(let err):
                    authError = err.localizedDescription
                }
            }
        }
    }

    private var applePill: some View {
        Button {
            startAppleSignIn()
        } label: {
            Image(systemName: "applelogo")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SoulTheme.Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Capsule().fill(SoulTheme.Color.surface))
                .overlay(Capsule().stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    private func startAppleSignIn() {
        appleSignIn.start { result in
            Task { @MainActor in
                isWorking = true
                authError = nil
                defer { isWorking = false }
                switch result {
                case .success(let r):
                    do {
                        try await store.signInWithApple(
                            idToken: r.identityToken,
                            nonce: r.rawNonce,
                            appleEmail: r.email,
                            appleFullName: r.fullName
                        )
                    } catch {
                        authError = error.localizedDescription
                    }
                case .failure(let err):
                    let nsErr = err as NSError
                    // Silently ignore user cancellation.
                    if nsErr.code != ASAuthorizationError.canceled.rawValue {
                        authError = err.localizedDescription
                    }
                }
            }
        }
    }

    private func socialPill(systemIcon: String? = nil,
                            emoji: String? = nil,
                            fg: Color,
                            action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Group {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 22, weight: .bold))
                } else if let emoji {
                    Text(emoji)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                }
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                Capsule().fill(SoulTheme.Color.surface)
            )
            .overlay(
                Capsule()
                    .stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    // MARK: OR divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(SoulTheme.Palette.earth.opacity(0.2))
                .frame(height: 1)
            Text("O")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(SoulTheme.Color.textSecondary)
            Rectangle()
                .fill(SoulTheme.Palette.earth.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: Email primary

    private var emailPrimaryButton: some View {
        Button {
            withAnimation { isShowingEmailForm = true }
        } label: {
            Text("Continuar con correo")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SoulTheme.Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Capsule().fill(SoulTheme.Palette.cream))
                .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    // MARK: Guest

    private var guestButton: some View {
        Button {
            withAnimation { store.continueAsGuest() }
        } label: {
            Text("Ver sin cuenta")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SoulTheme.Color.textSecondary)
                .underline()
        }
        .buttonStyle(.plain)
        .hapticOnTap()
        .padding(.top, 4)
    }

    // MARK: Email form

    private var emailForm: some View {
        VStack(spacing: 12) {
            field(placeholder: "hola@soulspring.mx", text: $email, kb: .emailAddress)
            field(placeholder: "contraseña", text: $password, secure: true)

            if let info = infoMessage {
                Text(info)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            if let err = authError {
                Text(err)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.heart)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }

            Button {
                Task { await submitEmailAuth() }
            } label: {
                HStack(spacing: 8) {
                    if isWorking { ProgressView().tint(SoulTheme.Color.onAccent) }
                    Text(isCreatingAccount ? "Comenzar" : "Entrar")
                }
            }
            .buttonStyle(SoulPrimaryButtonStyle())
            .disabled(isWorking || email.isEmpty || password.isEmpty)
            .padding(.top, 4)

            Button {
                withAnimation {
                    isShowingEmailForm = false
                    authError = nil
                    infoMessage = nil
                }
            } label: {
                Text("← Regresar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            .padding(.top, 4)
        }
    }

    private func submitEmailAuth() async {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !password.isEmpty else { return }
        await MainActor.run {
            isWorking = true
            authError = nil
            infoMessage = nil
        }
        do {
            if isCreatingAccount {
                try await store.signUpWithSupabase(email: trimmed, password: password)
                await MainActor.run {
                    if !store.auth.isAuthorized {
                        infoMessage = "Te enviamos un correo para confirmar tu cuenta. Cuando lo confirmes, regresa e inicia sesión."
                    }
                }
            } else {
                try await store.signInWithSupabase(email: trimmed, password: password)
            }
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
            }
        }
        await MainActor.run { isWorking = false }
    }

    private func field(placeholder: String,
                       text: Binding<String>,
                       secure: Bool = false,
                       kb: UIKeyboardType = .default) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .keyboardType(kb)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .font(SoulTheme.Font.body(16, weight: .medium))
        .foregroundStyle(SoulTheme.Color.textPrimary)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(Capsule().fill(SoulTheme.Color.surface))
        .overlay(Capsule().stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1))
    }

    // MARK: Footer

    private var footerLink: some View {
        HStack(spacing: 6) {
            Text(isCreatingAccount ? "¿Ya tienes cuenta?" : "¿Nuevo aquí?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SoulTheme.Color.textSecondary)
            Button {
                withAnimation {
                    isCreatingAccount.toggle()
                    isShowingEmailForm = false
                    authError = nil
                    infoMessage = nil
                }
            } label: {
                Text(isCreatingAccount ? "Inicia sesión" : "Crea una cuenta")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .underline()
            }
            .hapticOnTap()
        }
    }
}

#Preview {
    LoginView().environmentObject(AppStore())
}
