import SwiftUI

@main
struct SoulspringApp: App {
    @StateObject private var store  = AppStore()
    @StateObject private var health = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(health)
                .tint(SoulTheme.Color.primary)
                .task { store.publishWidgetSnapshots() }
        }
    }
}

/// Gates the navigation: login → onboarding formulario → main app.
struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if !store.auth.isAuthorized {
                LoginView()
                    .transition(.opacity)
            } else if !store.profile.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.auth.isAuthorized)
        .animation(.easeInOut(duration: 0.3), value: store.profile.hasCompletedOnboarding)
    }
}
