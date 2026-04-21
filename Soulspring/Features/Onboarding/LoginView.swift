import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var store: AppStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreatingAccount: Bool = false

    var body: some View {
        ZStack {
            SoulTheme.Gradient.dawn.ignoresSafeArea()

            // Soft decorative blob
            Circle()
                .fill(SoulTheme.Palette.sage.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 140, y: -220)

            ScrollView {
                VStack(spacing: SoulTheme.Spacing.lg) {
                    Spacer(minLength: 60)

                    header

                    form

                    orDivider

                    Button {
                        withAnimation { store.continueAsGuest() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                            Text("Ver sin cuenta")
                        }
                    }
                    .buttonStyle(SoulSecondaryButtonStyle())

                    Text("Explora con datos de ejemplo. Podrás crear tu cuenta más tarde para guardar tu progreso.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SoulTheme.Spacing.lg)

                    Spacer(minLength: 40)

                    footer
                }
                .padding(.horizontal, SoulTheme.Spacing.lg)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(SoulTheme.Gradient.forest)
                    .frame(width: 76, height: 76)
                    .shadow(color: SoulTheme.Palette.moss.opacity(0.25), radius: 16, y: 8)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(SoulTheme.Color.backgroundWarm)
            }

            SoulEyebrow(text: "Soulspring")

            Text("Tu santuario de\nvida consciente")
                .font(SoulTheme.Font.hero)
                .multilineTextAlignment(.center)
                .foregroundStyle(SoulTheme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(isCreatingAccount
                 ? "Crea tu cuenta para empezar tu camino."
                 : "Bienvenido de vuelta. Respira y continuemos.")
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Form

    private var form: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(spacing: 16) {
                Picker("Modo", selection: $isCreatingAccount.animation()) {
                    Text("Iniciar sesión").tag(false)
                    Text("Crear cuenta").tag(true)
                }
                .pickerStyle(.segmented)

                field(label: "Correo",
                      placeholder: "hola@soulspring.mx",
                      text: $email,
                      icon: "envelope")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                field(label: "Contraseña",
                      placeholder: "••••••••",
                      text: $password,
                      icon: "lock",
                      secure: true)

                Button {
                    let trimmed = email.trimmingCharacters(in: .whitespaces)
                    let finalEmail = trimmed.isEmpty ? "hola@soulspring.mx" : trimmed
                    withAnimation { store.signIn(email: finalEmail) }
                } label: {
                    Text(isCreatingAccount ? "Comenzar mi camino" : "Entrar")
                }
                .buttonStyle(SoulPrimaryButtonStyle())
                .padding(.top, 4)

                if !isCreatingAccount {
                    Button("¿Olvidaste tu contraseña?") {}
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }

    private func field(label: String,
                       placeholder: String,
                       text: Binding<String>,
                       icon: String,
                       secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: label)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(SoulTheme.Color.primarySoft)
                Group {
                    if secure {
                        SecureField(placeholder, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Palette.cream.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
            )
        }
    }

    // MARK: Or divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            SoulDivider()
            Text("o")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
            SoulDivider()
        }
        .padding(.horizontal, 30)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("Al continuar aceptas los términos de Soulspring y nuestra política de privacidad.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, SoulTheme.Spacing.md)
        .padding(.bottom, SoulTheme.Spacing.md)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStore())
}
