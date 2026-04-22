import SwiftUI

/// Browse the Soulspring audio library by category. Tap a track to open
/// the player sheet.
struct AudioLibraryView: View {
    @StateObject private var player = SoulAudioPlayer.shared
    @State private var selectedCategory: AudioTrack.Category? = nil

    private var filtered: [AudioTrack] {
        guard let cat = selectedCategory else { return AudioTrack.library }
        return AudioTrack.library.filter { $0.category == cat }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                SoulSectionHeader(
                    eyebrow: "Audios Soulspring",
                    title: "Tu biblioteca",
                    subtitle: "Meditaciones, yoga nidra, breathwork y sound healing — todo en bolsillo."
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(label: "Todos", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(AudioTrack.Category.allCases) { cat in
                            chip(label: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = (selectedCategory == cat) ? nil : cat
                            }
                        }
                    }
                }

                LazyVStack(spacing: 10) {
                    ForEach(filtered) { track in
                        Button {
                            player.play(track)
                        } label: {
                            trackRow(track)
                        }
                        .buttonStyle(.plain)
            .hapticOnTap()
                    }
                }

                if player.current != nil {
                    Spacer(minLength: 100) // leave room for mini-player
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulTheme.Color.background.ignoresSafeArea())
        .navigationTitle("Audios")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let track = player.current {
                MiniPlayer(track: track, player: player)
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, 8)
            }
        }
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(isSelected
                                 ? SoulTheme.Color.onAccent
                                 : SoulTheme.Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected
                                   ? AnyShapeStyle(SoulTheme.Color.primary)
                                   : AnyShapeStyle(SoulTheme.Color.surface))
                )
                .overlay(Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }

    private func trackRow(_ track: AudioTrack) -> some View {
        let isCurrent = player.current?.id == track.id
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(SoulTheme.Color.primary.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: isCurrent && player.isPlaying
                      ? "pause.fill"
                      : track.category.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text("\(track.teacher) · \(track.formattedDuration)")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Text(track.blurb)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(isCurrent
                        ? SoulTheme.Color.primary.opacity(0.4)
                        : SoulTheme.Color.divider,
                        lineWidth: isCurrent ? 1.5 : 0.5)
        )
    }
}

// MARK: - Mini player (sticky at bottom while a track is loaded)

struct MiniPlayer: View {
    let track: AudioTrack
    @ObservedObject var player: SoulAudioPlayer

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(SoulTheme.Color.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: track.category.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .lineLimit(1)
                Text("\(formatTime(player.elapsed)) / \(track.formattedDuration)")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Spacer()

            Button { player.skip(by: -15) } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            .hapticOnTap()

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.onAccent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(SoulTheme.Color.primary))
            }
            .hapticOnTap()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(SoulTheme.Color.surface)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
        )
    }

    private func formatTime(_ s: Double) -> String {
        let total = Int(s)
        let m = total / 60
        let r = total % 60
        return "\(m):\(String(format: "%02d", r))"
    }
}
