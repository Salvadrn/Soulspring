import SwiftUI

/// Grid of medallas. Locked ones show as muted silhouettes with a progress
/// ring; unlocked ones get the brand color treatment + the date earned.
struct AchievementsView: View {
    @EnvironmentObject private var store: AppStore

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                summary

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.achievementProgress) { progress in
                        MedallionCard(
                            progress: progress,
                            unlockedAt: store.unlockedAchievements[progress.achievement.id]
                        )
                    }
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulTheme.Color.background.ignoresSafeArea())
        .navigationTitle("Medallas")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.reconcileAchievements() }
    }

    private var summary: some View {
        let total = store.achievementProgress.count
        let unlocked = store.achievementProgress.filter(\.isUnlocked).count
        return SoulCard(padding: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(SoulTheme.Color.divider, lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: total == 0 ? 0 : Double(unlocked) / Double(total))
                        .stroke(SoulTheme.Color.primary, style: .init(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    Text("\(unlocked)")
                        .font(SoulTheme.Font.metric)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tus medallas")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("\(unlocked) de \(total) desbloqueadas. Cada una se gana, ninguna se compra.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
    }
}

private struct MedallionCard: View {
    let progress: AchievementEngine.Progress
    let unlockedAt: Date?

    var isUnlocked: Bool { progress.isUnlocked }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUnlocked
                          ? AnyShapeStyle(progress.achievement.tint.opacity(0.18))
                          : AnyShapeStyle(SoulTheme.Color.divider.opacity(0.5)))
                    .frame(width: 54, height: 54)
                Circle()
                    .trim(from: 0, to: progress.ratio)
                    .stroke(isUnlocked
                            ? progress.achievement.tint
                            : SoulTheme.Color.textTertiary,
                            style: .init(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 54, height: 54)
                Image(systemName: progress.achievement.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isUnlocked
                                     ? progress.achievement.tint
                                     : SoulTheme.Color.textTertiary)
            }

            Text(progress.achievement.title)
                .font(SoulTheme.Font.body(14, weight: .bold))
                .foregroundStyle(isUnlocked
                                 ? SoulTheme.Color.textPrimary
                                 : SoulTheme.Color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(progress.achievement.blurb)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack {
                Text("\(progress.current) / \(progress.achievement.target)")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Spacer()
                if let date = unlockedAt {
                    Text(date, format: .dateTime.day().month())
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(progress.achievement.tint)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(isUnlocked
                        ? progress.achievement.tint.opacity(0.4)
                        : SoulTheme.Color.divider, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environmentObject(AppStore())
    }
}
