import SwiftUI

/// Water intake widget. Compact version lives on the Home dashboard; full
/// version is pushed when the user taps the widget.
struct HydrationWidget: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        SoulCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(SoulTheme.Palette.sand, lineWidth: 7)
                        .frame(width: 54, height: 54)
                    Circle()
                        .trim(from: 0, to: max(0.001, store.hydration.percent))
                        .stroke(SoulTheme.Palette.sky,
                                style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 54, height: 54)
                        .animation(.easeOut(duration: 0.5), value: store.hydration.glasses)
                    Image(systemName: "drop.fill")
                        .foregroundStyle(SoulTheme.Palette.sky)
                }
                VStack(alignment: .leading, spacing: 3) {
                    SoulEyebrow(text: "Hidratación")
                    Text("\(store.hydration.glasses)/\(store.hydration.goal) vasos")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("~ \(store.hydration.glasses * 250) ml")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.3)) { store.addWater() }
                } label: {
                    ZStack {
                        Circle().fill(SoulTheme.Gradient.forest).frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

struct HydrationView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: SoulTheme.Spacing.md) {
                header
                ring
                actions
                tips
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Hidratación")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Hoy")
            Text(store.hydration.glasses >= store.hydration.goal
                 ? "¡Meta cumplida! 💧"
                 : "Te faltan \(store.hydration.goal - store.hydration.glasses) vasos.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(SoulTheme.Palette.sand, lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, store.hydration.percent))
                .stroke(SoulTheme.Palette.sky,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: store.hydration.glasses)

            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(SoulTheme.Palette.sky)
                Text("\(store.hydration.glasses)/\(store.hydration.goal)")
                    .font(SoulTheme.Font.display(40, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text("vasos")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.top, 10)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button { store.removeWater() } label: {
                HStack { Image(systemName: "minus"); Text("Quitar") }
            }
            .buttonStyle(SoulSecondaryButtonStyle())

            Button {
                withAnimation { store.addWater() }
            } label: {
                HStack { Image(systemName: "plus"); Text("Agregar vaso") }
            }
            .buttonStyle(SoulPrimaryButtonStyle())
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Rituales de agua",
                              title: "Para hidratarte mejor",
                              subtitle: nil)
            tip(icon: "sunrise.fill", title: "Al despertar",
                detail: "Un vaso grande con limón y sal de mar.")
            tip(icon: "leaf", title: "Antes de comer",
                detail: "Un vaso 15 min antes mejora digestión.")
            tip(icon: "moon.stars", title: "Dos horas antes de dormir",
                detail: "Deja de beber para no interrumpir tu sueño.")
        }
    }

    private func tip(icon: String, title: String, detail: String) -> some View {
        SoulCard {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(SoulTheme.Palette.sky).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(SoulTheme.Font.card).foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(detail).font(SoulTheme.Font.caption).foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }
}
