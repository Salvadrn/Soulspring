import SwiftUI

/// Shows the user's biological age — the centerpiece of the Longevity
/// narrative. Hero gauge on top, factor breakdown below, and a button to
/// complete the lifestyle inputs that improve accuracy.
struct BiologicalAgeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager
    @State private var isEditingInputs = false

    private var result: BioAgeResult {
        BioAgeCalculator.compute(
            profile: store.profile,
            inputs: store.bioAgeInputs,
            restingHR: health.restingHeartRate,
            hrv: health.hrv,
            steps: health.steps,
            sleepHours: health.sleepHours
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                hero
                completenessBanner
                breakdown
                disclaimer
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditingInputs) { BioAgeInputSheet() }
        .task { await health.refreshAll() }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Longevidad")
            Text("¿A qué edad vive tu cuerpo?")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("Combinamos HealthKit y tu estilo de vida. Direccional, no clínico.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }

    // MARK: Hero gauge

    private var hero: some View {
        let r = result
        return SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(spacing: 18) {
                ZStack {
                    // Gauge arc
                    BioAgeGauge(chrono: r.chronologicalAge,
                                bio: r.biologicalAge)
                        .frame(height: 200)

                    VStack(spacing: 0) {
                        SoulEyebrow(text: "Edad biológica")
                        Text(String(format: "%.1f", r.biologicalAge))
                            .font(.system(size: 68, weight: .semibold, design: .serif))
                            .foregroundStyle(r.isYounger
                                             ? SoulTheme.Palette.moss
                                             : r.isOlder
                                                ? SoulTheme.Palette.heart
                                                : SoulTheme.Palette.earth)
                        Text("vs \(String(format: "%.0f", r.chronologicalAge)) cronológica")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    .padding(.top, 30)
                }

                HStack(spacing: 10) {
                    Image(systemName: r.isYounger ? "arrow.down.circle.fill"
                                       : r.isOlder ? "arrow.up.circle.fill"
                                                   : "equal.circle.fill")
                        .foregroundStyle(r.isYounger
                                         ? SoulTheme.Palette.moss
                                         : r.isOlder
                                            ? SoulTheme.Palette.heart
                                            : SoulTheme.Palette.earth)
                    Text(r.summary)
                        .font(SoulTheme.Font.bodyText)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                }
            }
        }
    }

    // MARK: Completeness

    private var completenessBanner: some View {
        let missing = result.completeness < 1
        return Button {
            isEditingInputs = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: missing ? "exclamationmark.circle.fill"
                                          : "checkmark.seal.fill")
                    .foregroundStyle(missing ? SoulTheme.Palette.gold : SoulTheme.Palette.moss)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(missing ? "Mejora tu cálculo"
                                 : "Perfil completo")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(missing
                         ? "Completa estilo de vida, VO₂ e IMC para mayor precisión."
                         : "Ya tienes todos los factores.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(SoulTheme.Palette.sand)
                        Capsule().fill(SoulTheme.Gradient.forest)
                            .frame(width: geo.size.width * result.completeness)
                    }
                }
                .frame(width: 70, height: 6)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface))
            .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }

    // MARK: Breakdown

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Desglose",
                              title: "Qué te suma y qué te resta",
                              subtitle: "Ordenado por impacto.")
            VStack(spacing: 8) {
                ForEach(result.factors) { factor in
                    FactorRow(factor: factor)
                }
            }
        }
    }

    // MARK: Disclaimer

    private var disclaimer: some View {
        Text("Este cálculo es orientativo y no sustituye una evaluación clínica. Para un panel avanzado, agenda una consulta de medicina funcional en el Sanctuary.")
            .font(.system(size: 11))
            .foregroundStyle(SoulTheme.Color.textSecondary)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }
}

// MARK: - Factor row

struct FactorRow: View {
    let factor: BioAgeFactor

    private var tint: Color {
        if factor.deltaYears < -0.5 { return SoulTheme.Palette.moss }
        if factor.deltaYears >  0.5 { return SoulTheme.Palette.heart }
        return SoulTheme.Palette.earth
    }

    private var deltaLabel: String {
        let abs = Swift.abs(factor.deltaYears)
        let str = abs < 1 ? String(format: "%.1f", abs) : String(format: "%.0f", abs)
        if factor.deltaYears < -0.05 { return "−\(str) años" }
        if factor.deltaYears >  0.05 { return "+\(str) años" }
        return "neutro"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: factor.icon).foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(factor.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(factor.subtitle)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(deltaLabel)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(tint)
                Text(factor.valueLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }
}

// MARK: - Gauge

struct BioAgeGauge: View {
    let chrono: Double
    let bio: Double

    private let minAge: Double = 14
    private let maxAge: Double = 90

    private var position: Double {
        max(0, min(1, (bio - minAge) / (maxAge - minAge)))
    }
    private var chronoPosition: Double {
        max(0, min(1, (chrono - minAge) / (maxAge - minAge)))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let radius = min(w / 2, h)
            let center = CGPoint(x: w / 2, y: h)

            ZStack {
                // Background arc
                Arc(startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    .stroke(SoulTheme.Palette.sand, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Gradient arc up to bio age
                Arc(startAngle: .degrees(180),
                    endAngle: .degrees(180 + 180 * position),
                    clockwise: false)
                    .stroke(SoulTheme.Gradient.forest, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Chrono tick
                let chronoAngle = Double.pi + Double.pi * chronoPosition
                Circle()
                    .fill(SoulTheme.Palette.earth)
                    .frame(width: 10, height: 10)
                    .position(
                        x: center.x + CGFloat(cos(chronoAngle)) * radius,
                        y: center.y + CGFloat(sin(chronoAngle)) * radius
                    )
            }
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise)
        return p
    }
}

// MARK: - Input sheet

struct BioAgeInputSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        SoulSectionHeader(
                            eyebrow: "Afínalo",
                            title: "Dinos un poco más",
                            subtitle: "Preguntas rápidas para afinar tu edad biológica.")

                        stressCard
                        alcoholCard
                        tobaccoCard
                        optionalCard

                        Button { dismiss() } label: { Text("Guardar") }
                            .buttonStyle(SoulPrimaryButtonStyle())
                            .padding(.top, 6)
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Estilo de vida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
            }
        }
    }

    // Cards

    private var stressCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                SoulEyebrow(text: "Estrés en las últimas 2 semanas")
                Picker("Estrés", selection: Binding(
                    get: { store.bioAgeInputs.stress },
                    set: { store.bioAgeInputs.stress = $0 }
                )) {
                    ForEach(BioAgeInputs.StressLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var alcoholCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                SoulEyebrow(text: "Alcohol semanal")
                Picker("Alcohol", selection: Binding(
                    get: { store.bioAgeInputs.alcohol },
                    set: { store.bioAgeInputs.alcohol = $0 }
                )) {
                    ForEach(BioAgeInputs.AlcoholLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var tobaccoCard: some View {
        SoulCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tabaco")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("¿Fumas actualmente?")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.bioAgeInputs.smokes },
                    set: { store.bioAgeInputs.smokes = $0 }
                ))
                .labelsHidden()
                .tint(SoulTheme.Color.primary)
            }
        }
    }

    private var optionalCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 14) {
                SoulEyebrow(text: "Opcional · marcadores avanzados")
                Text("VO₂ máx (ml/kg·min)")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                TextField("Ej. 42", text: Binding(
                    get: { store.bioAgeInputs.vo2Max.map { String(format: "%.0f", $0) } ?? "" },
                    set: { store.bioAgeInputs.vo2Max = Double($0) }
                ))
                .keyboardType(.decimalPad)
                .font(SoulTheme.Font.bodyText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(SoulTheme.Palette.cream.opacity(0.6)))

                Text("IMC")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                TextField("Ej. 23.5", text: Binding(
                    get: { store.bioAgeInputs.bmi.map { String(format: "%.1f", $0) } ?? "" },
                    set: { store.bioAgeInputs.bmi = Double($0) }
                ))
                .keyboardType(.decimalPad)
                .font(SoulTheme.Font.bodyText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(SoulTheme.Palette.cream.opacity(0.6)))

                Text("Puedes encontrar tu VO₂ máx en la app Salud → Cardio fitness.")
                    .font(.system(size: 11))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }
}
