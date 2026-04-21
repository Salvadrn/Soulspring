import SwiftUI

/// Multi-step "Formulario que te lleva a tus intereses de salud".
/// Captures identity, activity level, selected interests, intention and
/// daily racha target. When finished it marks the profile as onboarded.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step: Int = 0

    private let totalSteps = 5

    var body: some View {
        ZStack {
            SoulTheme.Gradient.dawn.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.top, SoulTheme.Spacing.md)

                TabView(selection: $step) {
                    WelcomeStep().tag(0)
                    NameStep().tag(1)
                    ActivityStep().tag(2)
                    InterestsStep().tag(3)
                    GoalStep().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                footerButtons
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, SoulTheme.Spacing.lg)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                SoulEyebrow(text: "Soulspring · Paso \(step + 1) de \(totalSteps)")
                Spacer()
                if step > 0 {
                    Button("Atrás") { withAnimation { step -= 1 } }
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SoulTheme.Palette.sand)
                    Capsule()
                        .fill(SoulTheme.Gradient.forest)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
                        .animation(.easeOut, value: step)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: Footer

    private var footerButtons: some View {
        VStack(spacing: 10) {
            Button(step == totalSteps - 1 ? "Comenzar mi camino" : "Continuar") {
                if step == totalSteps - 1 {
                    var p = store.profile
                    p.hasCompletedOnboarding = true
                    if p.memberSince.timeIntervalSinceNow > -60 { p.memberSince = Date() }
                    store.profile = p
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(SoulPrimaryButtonStyle())
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)

            if step == 0 {
                Text("Diseñamos tu plan con base en lo que te importa a ti.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1: return !store.profile.name.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return !store.profile.interests.isEmpty
        default: return true
        }
    }
}

// MARK: - Step 1 · Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(SoulTheme.Gradient.forest)
                    .frame(width: 140, height: 140)
                    .shadow(color: SoulTheme.Palette.moss.opacity(0.3), radius: 24, y: 14)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(SoulTheme.Color.backgroundWarm)
            }

            Text("Respira.\nYa llegaste.")
                .font(SoulTheme.Font.hero)
                .multilineTextAlignment(.center)
                .foregroundStyle(SoulTheme.Color.textPrimary)

            Text("Soulspring es tu compañero diario para cultivar hábitos saludables y conectar con tu cuerpo.")
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SoulTheme.Spacing.lg)

            Spacer()
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
    }
}

// MARK: - Step 2 · Name

private struct NameStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
            Spacer(minLength: 20)
            SoulSectionHeader(
                eyebrow: "Para conocerte",
                title: "¿Cómo te llamas?",
                subtitle: "Personalizamos tu experiencia desde el primer día."
            )

            VStack(alignment: .leading, spacing: 6) {
                SoulEyebrow(text: "Tu nombre")
                TextField("Ej. Ana", text: Binding(
                    get: { store.profile.name },
                    set: { store.profile.name = $0 }
                ))
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .fill(SoulTheme.Color.surface)
                )
            }

            SoulSectionHeader(
                eyebrow: "Tu etapa",
                title: "¿Cuál es tu rango de edad?",
                subtitle: nil
            )

            VStack(spacing: 10) {
                ForEach(AgeBracket.allCases) { bracket in
                    SelectRow(
                        title: bracket.rawValue,
                        isSelected: store.profile.age == bracket
                    ) { store.profile.age = bracket }
                }
            }

            Spacer()
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
    }
}

// MARK: - Step 3 · Activity

private struct ActivityStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
            Spacer(minLength: 20)
            SoulSectionHeader(
                eyebrow: "Tu ritmo",
                title: "¿Qué tan activa es tu vida?",
                subtitle: "Ajustamos recomendaciones e intensidades a tu día a día."
            )

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases) { level in
                    SelectRow(
                        title: level.rawValue,
                        isSelected: store.profile.activity == level
                    ) { store.profile.activity = level }
                }
            }
            Spacer()
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
    }
}

// MARK: - Step 4 · Interests

private struct InterestsStep: View {
    @EnvironmentObject private var store: AppStore

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
            Spacer(minLength: 10)
            SoulSectionHeader(
                eyebrow: "Intereses de salud",
                title: "¿Qué te importa cultivar?",
                subtitle: "Elige los que resuenen contigo. Podrás cambiar esto después."
            )

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HealthInterest.allCases) { interest in
                        InterestCard(
                            interest: interest,
                            isSelected: store.profile.interests.contains(interest)
                        ) {
                            if store.profile.interests.contains(interest) {
                                store.profile.interests.remove(interest)
                            } else {
                                store.profile.interests.insert(interest)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
    }
}

// MARK: - Step 5 · Goal + racha

private struct GoalStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
            Spacer(minLength: 10)
            SoulSectionHeader(
                eyebrow: "Tu intención",
                title: "¿Para qué estás aquí?",
                subtitle: "Una frase clara: a qué te comprometes estos próximos 30 días."
            )

            TextField("Ej. Dormir mejor y bajar mi ritmo cardíaco en reposo.",
                      text: Binding(
                        get: { store.profile.goal },
                        set: { store.profile.goal = $0 }
                      ),
                      axis: .vertical)
            .font(SoulTheme.Font.bodyText)
            .foregroundStyle(SoulTheme.Color.textPrimary)
            .lineLimit(3, reservesSpace: true)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Color.surface)
            )

            SoulSectionHeader(
                eyebrow: "Tu racha",
                title: "Meta diaria",
                subtitle: "Cuántos hábitos debes cumplir cada día para mantener tu racha viva."
            )

            SoulCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("\(store.dailyGoalTarget)")
                            .font(SoulTheme.Font.display(56, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                        VStack(alignment: .leading) {
                            Text("hábitos al día")
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text("Cumple este mínimo todos los días para no romper tu racha.")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        Spacer()
                    }

                    Stepper(value: Binding(
                        get: { store.dailyGoalTarget },
                        set: { store.dailyGoalTarget = $0 }
                    ), in: 1...8) {
                        Text("Ajustar meta")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
    }
}

// MARK: - Shared selection components

private struct SelectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.backgroundWarm
                                     : SoulTheme.Color.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(SoulTheme.Color.backgroundWarm)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(SoulTheme.Gradient.forest)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct InterestCard: View {
    let interest: HealthInterest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: interest.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.backgroundWarm
                                     : SoulTheme.Color.primary)
                Spacer(minLength: 6)
                Text(interest.rawValue)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.backgroundWarm
                                     : SoulTheme.Color.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(interest.tagline)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.backgroundWarm.opacity(0.8)
                                     : SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(SoulTheme.Gradient.forest)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
