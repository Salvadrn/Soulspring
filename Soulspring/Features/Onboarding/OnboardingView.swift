import SwiftUI

/// Multi-step "Formulario que te lleva a tus intereses de salud".
/// Captures everything Soulspring needs to personalize the experience and
/// compute biological age from day one: identity, contact, emergency contact,
/// body, lifestyle, interests and intention.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step: Int = 0
    @State private var isShowingTerms: Bool = false

    private let totalSteps = 7

    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.top, SoulTheme.Spacing.md)

                TabView(selection: $step) {
                    WelcomeStep().tag(0)
                    IdentityStep().tag(1)
                    EmergencyStep().tag(2)
                    BodyStep().tag(3)
                    LifestyleStep().tag(4)
                    InterestsStep().tag(5)
                    GoalStep().tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                footerButtons
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, SoulTheme.Spacing.lg)
            }
        }
        .sheet(isPresented: $isShowingTerms) {
            TermsView {
                completeOnboarding()
                isShowingTerms = false
            }
            .interactiveDismissDisabled(true)
        }
    }

    private func completeOnboarding() {
        var p = store.profile
        p.hasCompletedOnboarding = true
        if p.memberSince.timeIntervalSinceNow > -60 { p.memberSince = Date() }
        store.profile = p
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
                } else {
                    Button("Cerrar sesión") { store.signOut() }
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
                    isShowingTerms = true
                } else {
                    withAnimation { step += 1 }
                }
            }
            .buttonStyle(SoulPrimaryButtonStyle())
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)

        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1: return !store.profile.name.trimmingCharacters(in: .whitespaces).isEmpty
        case 5: return !store.profile.interests.isEmpty
        default: return true
        }
    }
}

// MARK: - Step 0 · Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("BrandLogo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .offset(x: -18)   // nudge slightly left for a balanced look

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

// MARK: - Step 1 · Identity (name, age, email, phone)

private struct IdentityStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Para conocerte",
                    title: "Cuéntanos de ti",
                    subtitle: "Personalizamos tu experiencia desde el primer día."
                )

                LabeledField(label: "Tu nombre", placeholder: "Ej. Ana",
                             text: bind(\.name))

                VStack(alignment: .leading, spacing: 8) {
                    SoulEyebrow(text: "Tu rango de edad")
                    VStack(spacing: 8) {
                        ForEach(AgeBracket.allCases) { bracket in
                            SelectRow(
                                title: bracket.rawValue,
                                isSelected: store.profile.age == bracket
                            ) { store.profile.age = bracket }
                        }
                    }
                }

                LabeledField(label: "Correo de contacto",
                             placeholder: "hola@soulspring.mx",
                             text: bind(\.email),
                             keyboard: .emailAddress)

                LabeledField(label: "Teléfono",
                             placeholder: "+52 ...",
                             text: bind(\.phone),
                             keyboard: .phonePad)
            }
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
    }

    private func bind(_ keyPath: WritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { store.profile[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Step 2 · Emergency contact

private struct EmergencyStep: View {
    @EnvironmentObject private var store: AppStore

    private static let commonAllergies = [
        "Polen", "Mariscos", "Lácteos", "Gluten", "Frutos secos",
        "Huevo", "Soya", "Picadura de abeja", "Penicilina", "Aspirina",
        "Látex", "Maní", "Pescado", "Cacahuate"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Por si acaso",
                    title: "Contacto de emergencia",
                    subtitle: "Solo se usa si te necesitamos cuidar. Puedes editarlo después."
                )

                LabeledField(label: "Nombre",
                             placeholder: "Ej. Mamá",
                             text: bind(\.emergencyContactName))

                LabeledField(label: "Teléfono",
                             placeholder: "+52 ...",
                             text: bind(\.emergencyContactPhone),
                             keyboard: .phonePad)

                VStack(alignment: .leading, spacing: 10) {
                    SoulEyebrow(text: "Alergias o consideraciones")
                    Text("Toca las que apliquen, o escribe abajo otras.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)

                    FlowChips(
                        items: Self.commonAllergies,
                        isSelected: { contains($0) },
                        toggle: { toggle($0) }
                    )

                    TextField("Otras alergias",
                              text: bind(\.allergies),
                              axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .fill(SoulTheme.Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
    }

    private func bind(_ keyPath: WritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { store.profile[keyPath: keyPath] = $0 }
        )
    }

    private func contains(_ allergy: String) -> Bool {
        let parts = store.profile.allergies
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        return parts.contains(allergy.lowercased())
    }

    private func toggle(_ allergy: String) {
        var parts = store.profile.allergies
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let idx = parts.firstIndex(where: { $0.lowercased() == allergy.lowercased() }) {
            parts.remove(at: idx)
        } else {
            parts.append(allergy)
        }
        store.profile.allergies = parts.joined(separator: ", ")
        SoulHaptics.select()
    }
}

/// Wrapping flow of toggle chips. SwiftUI doesn't ship a flow layout out of
/// the box at the deployment target so we build a simple one with
/// GeometryReader-free chunking.
private struct FlowChips: View {
    let items: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    var body: some View {
        FlexibleView(data: items, spacing: 8, alignment: .leading) { item in
            Button { toggle(item) } label: {
                Text(item)
                    .font(SoulTheme.Font.body(13, weight: .semibold))
                    .foregroundStyle(isSelected(item)
                                     ? SoulTheme.Color.onAccent
                                     : SoulTheme.Color.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(isSelected(item)
                                       ? AnyShapeStyle(SoulTheme.Color.primary)
                                       : AnyShapeStyle(SoulTheme.Color.surface))
                    )
                    .overlay(
                        Capsule().stroke(isSelected(item)
                                         ? SoulTheme.Color.primary
                                         : SoulTheme.Palette.earth.opacity(0.25),
                                         lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .hapticOnTap()
        }
    }
}

/// Wrapping flow layout — measures item widths via PreferenceKey so chips
/// reflow into rows like a tag cloud.
private struct FlexibleView<Data: Hashable, Content: View>: View {
    let data: [Data]
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data) -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { availableWidth = $0.width }

            FlowStack(width: availableWidth, spacing: spacing, items: data, content: content)
        }
    }
}

private struct FlowStack<Data: Hashable, Content: View>: View {
    let width: CGFloat
    let spacing: CGFloat
    let items: [Data]
    let content: (Data) -> Content

    var body: some View {
        var currentRowWidth: CGFloat = 0
        var rows: [[Data]] = [[]]
        for item in items {
            let estimated = estimatedWidth(item)
            if currentRowWidth + estimated + spacing > width && !rows[rows.count - 1].isEmpty {
                rows.append([item])
                currentRowWidth = estimated + spacing
            } else {
                rows[rows.count - 1].append(item)
                currentRowWidth += estimated + spacing
            }
        }
        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(rows[row], id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    /// Rough estimate good enough for chip widths (~7pt per char + padding).
    private func estimatedWidth(_ item: Data) -> CGFloat {
        let s = (item as? String) ?? "\(item)"
        return CGFloat(s.count) * 8 + 28
    }
}

private struct SizeReader: View {
    let onChange: (CGSize) -> Void
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: SizePreferenceKey.self, value: geo.size)
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private extension View {
    func readSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background(SizeReader(onChange: onChange))
    }
}

// MARK: - Step 3 · Body & Activity (height, weight, activity level)

private struct BodyStep: View {
    @EnvironmentObject private var store: AppStore
    @State private var heightText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Tu cuerpo",
                    title: "Para calcular tu edad biológica",
                    subtitle: "Estos datos alimentan el motor de BioAge. Opcionales pero recomendados."
                )

                HStack(spacing: 12) {
                    NumberField(label: "Estatura", suffix: "cm", text: $heightText)
                        .onChange(of: heightText) { _, new in
                            store.bioAgeInputs.heightCm = Double(new.replacingOccurrences(of: ",", with: "."))
                        }
                    NumberField(label: "Peso", suffix: "kg", text: $weightText)
                        .onChange(of: weightText) { _, new in
                            store.bioAgeInputs.weightKg = Double(new.replacingOccurrences(of: ",", with: "."))
                        }
                }

                if let bmi = store.bioAgeInputs.effectiveBMI {
                    SoulCard(padding: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                SoulEyebrow(text: "IMC calculado")
                                Text(String(format: "%.1f", bmi))
                                    .font(SoulTheme.Font.metric)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                            }
                            Spacer()
                            Text(bmi < 18.5 ? "Bajo"
                                 : bmi < 25 ? "Saludable"
                                 : bmi < 30 ? "Sobrepeso" : "Obesidad")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                    }
                }

                SoulSectionHeader(
                    eyebrow: "Tu ritmo",
                    title: "¿Qué tan activa es tu vida?",
                    subtitle: nil
                )

                VStack(spacing: 8) {
                    ForEach(ActivityLevel.allCases) { level in
                        SelectRow(
                            title: level.rawValue,
                            isSelected: store.profile.activity == level
                        ) { store.profile.activity = level }
                    }
                }
            }
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
        .onAppear {
            if let h = store.bioAgeInputs.heightCm, heightText.isEmpty {
                heightText = String(format: "%.0f", h)
            }
            if let w = store.bioAgeInputs.weightKg, weightText.isEmpty {
                weightText = String(format: "%.0f", w)
            }
        }
    }
}

// MARK: - Step 4 · Lifestyle (smokes, alcohol, stress)

private struct LifestyleStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Tu estilo",
                    title: "Hábitos de vida",
                    subtitle: "Honesto > perfecto. Esto solo lo ves tú."
                )

                VStack(alignment: .leading, spacing: 8) {
                    SoulEyebrow(text: "¿Fumas?")
                    HStack(spacing: 8) {
                        ToggleChip(label: "No fumo",
                                   isSelected: !store.bioAgeInputs.smokes) {
                            store.bioAgeInputs.smokes = false
                        }
                        ToggleChip(label: "Sí",
                                   isSelected: store.bioAgeInputs.smokes) {
                            store.bioAgeInputs.smokes = true
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SoulEyebrow(text: "Alcohol")
                    VStack(spacing: 8) {
                        ForEach(BioAgeInputs.AlcoholLevel.allCases) { level in
                            SelectRow(
                                title: level.rawValue,
                                isSelected: store.bioAgeInputs.alcohol == level
                            ) { store.bioAgeInputs.alcohol = level }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SoulEyebrow(text: "Nivel de estrés percibido")
                    VStack(spacing: 8) {
                        ForEach(BioAgeInputs.StressLevel.allCases) { level in
                            SelectRow(
                                title: level.rawValue,
                                isSelected: store.bioAgeInputs.stress == level
                            ) { store.bioAgeInputs.stress = level }
                        }
                    }
                }
            }
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Step 5 · Interests

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

// MARK: - Step 6 · Goal + racha

private struct GoalStep: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
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
            }
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
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
                                     ? SoulTheme.Color.onAccent
                                     : SoulTheme.Color.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SoulTheme.Color.onAccent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(SoulTheme.Color.primary)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(isSelected
                            ? SoulTheme.Color.primary
                            : SoulTheme.Palette.earth.opacity(0.25),
                            lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04),
                    radius: 6, y: 2)
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }
}

private struct ToggleChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(SoulTheme.Font.body(15, weight: .semibold))
                .foregroundStyle(isSelected
                                 ? SoulTheme.Color.onAccent
                                 : SoulTheme.Color.textPrimary)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(isSelected
                                   ? AnyShapeStyle(SoulTheme.Color.primary)
                                   : AnyShapeStyle(SoulTheme.Color.surface))
                )
                .overlay(
                    Capsule().stroke(isSelected
                                     ? SoulTheme.Color.primary
                                     : SoulTheme.Palette.earth.opacity(0.25),
                                     lineWidth: isSelected ? 0 : 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
            .hapticOnTap()
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
                                     ? SoulTheme.Color.onAccent
                                     : SoulTheme.Color.primary)
                Spacer(minLength: 6)
                Text(interest.rawValue)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.onAccent
                                     : SoulTheme.Color.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(interest.tagline)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(isSelected
                                     ? SoulTheme.Color.onAccent.opacity(0.8)
                                     : SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(SoulTheme.Color.primary)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(isSelected
                            ? SoulTheme.Color.primary
                            : SoulTheme.Palette.earth.opacity(0.25),
                            lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }
}

// MARK: - Field components

private struct LabeledField: View {
    let label: String
    let placeholder: String
    let text: Binding<String>
    var keyboard: UIKeyboardType = .default
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: label)
            Group {
                if multiline {
                    TextField(placeholder, text: text, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
            .autocorrectionDisabled(keyboard == .emailAddress)
            .font(SoulTheme.Font.body(16, weight: .medium))
            .foregroundStyle(SoulTheme.Color.textPrimary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }
}

private struct NumberField: View {
    let label: String
    let suffix: String
    let text: Binding<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: label)
            HStack(spacing: 4) {
                TextField("—", text: text)
                    .keyboardType(.decimalPad)
                    .font(SoulTheme.Font.body(16, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(suffix)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Palette.earth.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }
}
