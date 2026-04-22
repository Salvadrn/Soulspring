import SwiftUI

/// Top-level Rutina tab. Wraps RemindersView with its own header so it
/// stands on its own outside the Sanctuary section.
struct RoutineView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                VStack(spacing: 0) {
                    header
                    RemindersView()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "Tu día")
            Text("Rutina diaria.")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
