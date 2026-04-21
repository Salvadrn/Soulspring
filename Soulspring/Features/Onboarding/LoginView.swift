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
            // Small mark
            ZStack {
                Circle()
                    .fill(SoulTheme.Color.primary.opacity(0.18))
                    .frame(width: 74, height: 74)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.primary)
            }

            VStack(spacing: 8) {
                Text("Soulspring")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(SoulTheme.Color.primary)

                Text(isCreatingAccount
                     ? "Crea tu perfil y empieza\ntu camino hacia adentro."
                     : "Bienvenido de vuelta.\nRespira, ya llegaste.")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
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

            Button {
                let trimmed = email.trimmingCharacters(in: .whitespaces)
                let finalEmail = trimmed.isEmpty ? "hola@soulspring.mx" : trimmed
                withAnimation { store.signIn(email: finalEmail) }
            } label: {
                Text(isCreatingAccount ? "Comenzar" : "Entrar")
            }
            .buttonStyle(SoulPrimaryButtonStyle())
            .padding(.top, 4)

            Button {
                withAnimation { isShowingEmailForm = false }
            } label: {
                Text("← Regresar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            .padding(.top, 4)
        }
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
