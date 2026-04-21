import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, heart, habits, sanctuary, profile
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Hoy", systemImage: "sun.max") }
                .tag(Tab.home)

            HeartRateView()
                .tabItem { Label("Salud", systemImage: "heart") }
                .tag(Tab.heart)

            HabitsView()
                .tabItem { Label("Hábitos", systemImage: "flame") }
                .tag(Tab.habits)

            SanctuaryView()
                .tabItem { Label("Santuario", systemImage: "leaf") }
                .tag(Tab.sanctuary)

            ProfileView()
                .tabItem { Label("Yo", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(SoulTheme.Color.primary)
        .task {
            await health.requestAuthorization()
        }
    }
}
