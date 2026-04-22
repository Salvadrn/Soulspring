import SwiftUI

/// Terms & Conditions sheet shown at the end of onboarding. The user must
/// scroll, check "He leído y acepto" and tap the CTA before they're allowed
/// into the app. Acceptance is persisted on the profile (version + date) so
/// we can re-prompt when the policy changes.
struct TermsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    /// Bump this when the legal text changes — older acceptances won't count.
    static let currentVersion = "1.0"

    let onAccept: () -> Void

    @State private var hasAccepted: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: true) {
                        VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                            SoulSectionHeader(
                                eyebrow: "Antes de empezar",
                                title: "Términos y condiciones",
                                subtitle: "Versión \(Self.currentVersion) · Soulspring"
                            )

                            ForEach(termsSections, id: \.title) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(section.title)
                                        .font(SoulTheme.Font.body(16, weight: .bold))
                                        .foregroundStyle(SoulTheme.Color.textPrimary)
                                    Text(section.body)
                                        .font(SoulTheme.Font.bodyText)
                                        .foregroundStyle(SoulTheme.Color.textSecondary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                        .fill(SoulTheme.Color.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                        .stroke(SoulTheme.Palette.earth.opacity(0.2),
                                                lineWidth: 1)
                                )
                            }

                            Text("Para la versión completa visita soulspring.world/legal")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                                .padding(.top, 8)
                        }
                        .padding(SoulTheme.Spacing.lg)
                        .padding(.bottom, 12)
                    }

                    acceptanceFooter
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { dismiss() }
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }

    private var acceptanceFooter: some View {
        VStack(spacing: 12) {
            Divider()

            Button {
                hasAccepted.toggle()
                SoulHaptics.select()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasAccepted
                          ? "checkmark.square.fill"
                          : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(hasAccepted
                                         ? SoulTheme.Color.primary
                                         : SoulTheme.Color.textSecondary)
                    Text("He leído y acepto los términos y condiciones, así como la política de privacidad.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .hapticOnTap()

            Button {
                store.profile.acceptedTermsVersion = Self.currentVersion
                store.profile.acceptedTermsAt = Date()
                SoulHaptics.success()
                onAccept()
            } label: {
                Text("Acepto y continuar")
            }
            .buttonStyle(SoulPrimaryButtonStyle())
            .disabled(!hasAccepted)
            .opacity(hasAccepted ? 1 : 0.5)
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(SoulTheme.Color.background)
    }

    // MARK: Legal text

    private struct Section {
        let title: String
        let body: String
    }

    private var termsSections: [Section] {
        [
            .init(title: "1. Aceptación",
                  body: "Al usar Soulspring aceptas estos términos y nuestra política de privacidad. Si no estás de acuerdo, te pedimos no usar la aplicación."),
            .init(title: "2. Datos personales que recopilamos",
                  body: "Para personalizar tu experiencia recopilamos: nombre, correo, teléfono, contacto de emergencia, alergias, edad, nivel de actividad, estatura, peso, hábitos de vida (alcohol, tabaco, estrés), intereses de salud y datos de Apple Health (ritmo cardíaco, sueño, pasos, HRV) cuando los autorizas. También guardamos tus check-ins de ánimo, hábitos completados, reservaciones y resúmenes de laboratorios que subas."),
            .init(title: "3. Cómo usamos tus datos",
                  body: "Usamos esta información únicamente para: (a) mostrarte tu progreso y rachas, (b) calcular tu edad biológica de forma directional, (c) generar recomendaciones de bienestar personalizadas, (d) que el coach Soul (IA) te dé respuestas contextualizadas, (e) que el equipo del Sanctuary te reciba con tus consideraciones clínicas durante tu estancia."),
            .init(title: "4. Almacenamiento y seguridad",
                  body: "Tus datos se guardan en infraestructura de Supabase (Postgres + Storage). Aplicamos Row Level Security para que solo tú puedas leer y escribir tus registros. Los archivos de laboratorio se cifran en reposo. Algunos datos se conservan localmente en tu dispositivo (UserDefaults) para funcionar offline."),
            .init(title: "5. IA y procesamiento",
                  body: "Cuando usas el Chat con Soul o el análisis de tus laboratorios, fragmentos relevantes de tu perfil se envían a Anthropic (Claude) a través de funciones seguras del servidor. No entrenamos modelos con tus datos. Anthropic puede retener entradas hasta 30 días para detección de abuso conforme a su política."),
            .init(title: "6. Compartir con terceros",
                  body: "No vendemos ni rentamos tus datos. Solo compartimos información personal con: Supabase (infraestructura), Anthropic (IA conversacional), Apple HealthKit (lectura local autorizada por ti). Cualquier nuevo proveedor se notificará con anticipación."),
            .init(title: "7. Tus derechos",
                  body: "Puedes solicitar acceso, rectificación o eliminación de tus datos enviando un correo a hola@soulspring.mx. La cuenta se puede borrar desde Perfil → Cerrar sesión → contactarnos para baja definitiva."),
            .init(title: "8. Salud y responsabilidad",
                  body: "Soulspring es una herramienta de bienestar y NO sustituye consulta médica profesional. Las recomendaciones, BioAge y respuestas del coach Soul son orientativas. Para cualquier condición clínica acude con un médico."),
            .init(title: "9. Cambios a estos términos",
                  body: "Si actualizamos esta política te pediremos tu consentimiento de nuevo dentro de la app. Versión actual: \(Self.currentVersion).")
        ]
    }
}
