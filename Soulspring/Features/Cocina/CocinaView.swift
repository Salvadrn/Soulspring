import SwiftUI

/// Top-level Cocina tab. Bundles everything food-related:
/// - Menú del día (chef's curated daily menu)
/// - Cocina (catalog + Soul Kitchen instagram)
/// - Room service (order to your room)
struct CocinaView: View {
    enum Tab: Hashable { case menu, recetas, room }

    @State private var tab: Tab = .menu

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                VStack(spacing: 0) {
                    header

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            segment(title: "Menú del día", tag: .menu)
                            segment(title: "Recetas",      tag: .recetas)
                            segment(title: "Room service", tag: .room)
                        }
                        .padding(.horizontal, SoulTheme.Spacing.lg)
                    }
                    .padding(.bottom, 12)

                    Group {
                        switch tab {
                        case .menu:    DailyMenuView()
                        case .recetas: FoodView()
                        case .room:    RoomServiceView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func segment(title: String, tag: Tab) -> some View {
        Button {
            withAnimation { tab = tag }
            SoulHaptics.tap()
        } label: {
            Text(title)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(tab == tag
                                 ? SoulTheme.Color.backgroundWarm
                                 : SoulTheme.Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(tab == tag
                                   ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                   : AnyShapeStyle(SoulTheme.Color.surface))
                )
                .overlay(
                    Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5)
                )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "La cocina")
            Text("Comida con intención.")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
