import SwiftUI

/// Top-level Soul AI tab. Wraps SoulChatView in a NavigationStack with its
/// own header so it stands as a first-class section.
struct SoulAITab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                VStack(spacing: 0) {
                    header
                    SoulChatView()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "Tu coach")
            Text("Soul AI.")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
