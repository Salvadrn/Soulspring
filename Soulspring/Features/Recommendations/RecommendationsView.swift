import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            SoulBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        SoulEyebrow(text: "Para ti")
                        Text("Recomendaciones")
                            .font(SoulTheme.Font.hero)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text("Basadas en tus intereses: \(summary).")
                            .font(SoulTheme.Font.bodyText)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    .padding(.top, 8)

                    ForEach(byInterest().keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { interest in
                        section(for: interest, items: byInterest()[interest] ?? [])
                    }
                }
                .padding(.horizontal, SoulTheme.Spacing.lg)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(for interest: HealthInterest, items: [Recommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: interest.icon)
                    .foregroundStyle(SoulTheme.Color.primary)
                Text(interest.rawValue)
                    .font(SoulTheme.Font.sectionHead)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            VStack(spacing: 10) {
                ForEach(items) { rec in
                    RecommendationRow(rec: rec)
                }
            }
        }
    }

    private func byInterest() -> [HealthInterest: [Recommendation]] {
        Dictionary(grouping: store.recommendations, by: \.interest)
    }

    private var summary: String {
        let names = store.profile.interests.map(\.rawValue)
        guard !names.isEmpty else { return "bienestar general" }
        if names.count == 1 { return names[0] }
        let head = names.dropLast().joined(separator: ", ")
        return head + " y " + (names.last ?? "")
    }
}

struct RecommendationRow: View {
    let rec: Recommendation
    var body: some View {
        SoulCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .fill(SoulTheme.Gradient.sunset)
                        .frame(width: 52, height: 52)
                    Image(systemName: iconFor(rec.category))
                        .font(.system(size: 22))
                        .foregroundStyle(SoulTheme.Color.backgroundWarm)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.title)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(rec.summary)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        SoulChip(text: rec.category.rawValue,
                                 tint: SoulTheme.Palette.moss)
                        if rec.minutes > 0 {
                            SoulChip(text: "\(rec.minutes) min",
                                     tint: SoulTheme.Palette.earth)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }

    private func iconFor(_ c: Recommendation.Category) -> String {
        switch c {
        case .breathwork:  return "wind"
        case .movement:    return "figure.run"
        case .nutrition:   return "leaf.fill"
        case .restorative: return "bed.double.fill"
        case .study:       return "book.closed"
        case .ritual:      return "sparkles"
        }
    }
}
