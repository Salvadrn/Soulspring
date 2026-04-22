import SwiftUI

/// Login / sign-up in the Mimo-inspired dark aesthetic.
/// - Hero title up top, big pill CTAs (Apple / Google / Email).
/// - "Ver sin cuenta" lives as a distinct third option that loads the
///   sample data guest mode.
/// - Bottom link for existing users.
struct LoginView: View {
    @EnvironmentObject private var store: AppStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreatingAccount: Bool = true
    @State private var isShowingEmailForm: Bool = false
    @State private var isWorking: Bool = false
    @State private var authError: String? = nil
    @State private var infoMessage: String? = nil

    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                heroBlock
                    .padding(.horizontal, SoulTheme.Spacing.lg)

                Spacer()

                VStack(spacing: 12) {
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

                Spacer(minLength: 20)

                footerLink
                    .padding(.bottom, SoulTheme.Spacing.md)
            }
        }
    }

    // MARK: Hero

    private var heroBlock: some View {
        VStack(spacing: 18) {
            Image("BrandLogo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 130, height: 130)
                .blendMode(.multiply)   // strips the white PNG background

            VStack(spacing: 8) {
                Text("Soulspring")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(SoulTheme.Color.primary)

                Text("Beyond Wellness")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Color.textPrimary)

                Text(isCreatingAccount
                     ? "Crea tu perfil y empieza\ntu camino hacia adentro."
                     : "Bienvenido de vuelta.\nRespira, ya llegaste.")
                    .font(SoulTheme.Font.bodyText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: Social buttons

    private var socialButtons: some View {
        HStack(spacing: 10) {
            socialButton(icon: "applelogo", bg: Color.white, fg: Color.black)
            socialButton(systemIcon: false, emoji: "G", bg: Color.white, fg: Color.black)
        }
    }

    private func socialButton(icon: String? = nil,
                              systemIcon: Bool = true,
                              emoji: String = "",
                              bg: Color,
                              fg: Color) -> some View {
        Button {
            // hook up real auth later — for now, same as email
            store.signIn(email: "hola@soulspring.mx")
        } label: {
            Group {
                if systemIcon, let icon {
                    Image(systemName: icon).font(.system(size: 20, weight: .bold))
                } else {
                    Text(emoji).font(.system(size: 20, weight: .heavy, design: .rounded))
                }
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                Capsule().fill(bg)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: OR divider

    private var orDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(SoulTheme.Color.divider)
                .frame(height: 1)
            Text("O")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(SoulTheme.Color.textSecondary)
            Rectangle()
                .fill(SoulTheme.Color.divider)
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: Email primary (shows form when tapped)

    private var emailPrimaryButton: some View {
        Button {
            withAnimation { isShowingEmailForm = true }
        } label: {
            Text("Continuar con correo")
        }
        .buttonStyle(SoulPrimaryButtonStyle())
    }

    // MARK: Guest

    private var guestButton: some View {
        Button {
            withAnimation { store.continueAsGuest() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "eye")
                Text("Ver sin cuenta")
            }
        }
        .buttonStyle(SoulSecondaryButtonStyle())
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Capsule().fill(SoulTheme.Color.surface))
        .overlay(Capsule().stroke(SoulTheme.Color.divider, lineWidth: 1))
    }

    // MARK: Footer

    private var footerLink: some View {
        HStack(spacing: 6) {
            Text(isCreatingAccount ? "¿Ya tienes cuenta?" : "¿Nuevo aquí?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SoulTheme.Color.textSecondary)
            Button {
                withAnimation { isCreatingAccount.toggle() }
            } label: {
                Text(isCreatingAccount ? "Inicia sesión" : "Crea una cuenta")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .underline()
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(AppStore())
}
