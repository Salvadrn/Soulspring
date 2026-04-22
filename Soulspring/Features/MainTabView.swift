import SwiftUI

/// Five-tab shell with a **floating pill tab bar** — the signature
/// navigation element of the new dark Soulspring aesthetic.
struct MainTabView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var selection: Tab = .home

    enum Tab: Hashable, CaseIterable {
        case home, heart, routine, cocina, habits, sanctuary, profile

        var title: String {
            switch self {
            case .home:      return "Hoy"
            case .heart:     return "Salud"
            case .routine:   return "Rutina"
            case .cocina:    return "Cocina"
            case .habits:    return "Rachas"
            case .sanctuary: return "Santuario"
            case .profile:   return "Yo"
            }
        }

        var icon: String {
            switch self {
            case .home:      return "sun.max.fill"
            case .heart:     return "heart.fill"
            case .routine:   return "checkmark.circle.fill"
            case .cocina:    return "fork.knife"
            case .habits:    return "flame.fill"
            case .sanctuary: return "leaf.fill"
            case .profile:   return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selection {
                case .home:      HomeView()
                case .heart:     HeartRateView()
                case .routine:   RoutineView()
                case .cocina:    CocinaView()
                case .habits:    HabitsView()
                case .sanctuary: SanctuaryView()
                case .profile:   ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating pill tab bar
            FloatingTabBar(selection: $selection)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .background(SoulTheme.Color.background.ignoresSafeArea())
        .task { await health.requestAuthorization() }
    }
}

// MARK: - Floating tab bar

struct FloatingTabBar: View {
    @Binding var selection: MainTabView.Tab

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                        tabItem(tab).id(tab)
                    }
                }
                .padding(6)
            }
            .background(
                Capsule(style: .continuous)
                    .fill(SoulTheme.Color.surface)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(SoulTheme.Color.divider, lineWidth: 1)
                    )
            )
            .clipShape(Capsule(style: .continuous))
            .onChange(of: selection) { _, new in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(new, anchor: .center)
                }
            }
        }
    }

    private func tabItem(_ tab: MainTabView.Tab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.interactiveSpring(response: 0.25,
                                             dampingFraction: 0.8)) {
                selection = tab
            }
            SoulHaptics.tap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected
                             ? SoulTheme.Color.onAccent
                             : SoulTheme.Color.textSecondary)
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 11)
            .background(
                Capsule().fill(isSelected
                               ? AnyShapeStyle(SoulTheme.Color.primary)
                               : AnyShapeStyle(Color.clear))
            )
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }
}
