import SwiftUI

/// Conversational coach. Sends user message + full context (profile, racha,
/// bioage, recent labs, recent moods) to the chat-with-soul Edge Function.
struct SoulChatView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager

    @State private var messages: [SoulChatService.Message] = []
    @State private var input: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String? = nil

    private let suggestions = [
        "¿Qué hago si duermo mal toda la semana?",
        "Tengo el HRV bajo, ¿qué cambio primero?",
        "Plan rápido para hoy con poco tiempo.",
        "¿Qué experiencia del Sanctuary me recomiendas?"
    ]

    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if messages.isEmpty {
                                emptyState
                            } else {
                                ForEach(messages) { msg in
                                    bubble(msg).id(msg.id)
                                }
                            }
                            if isSending { typingIndicator }
                            if let err = errorText {
                                Text(err)
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.heart)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(SoulTheme.Spacing.lg)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
        }
        .navigationTitle("Chat con Soul")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Empty / suggestions

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(SoulTheme.Color.primary.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SoulTheme.Color.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Soul")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("Tu coach de bienestar.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }

            Text("Conozco tu racha, tu BioAge, tus labs y tu perfil. Pregúntame lo que necesites resolver hoy.")
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Sugerencias")
                    .font(SoulTheme.Font.eyebrow)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                ForEach(suggestions, id: \.self) { s in
                    Button { input = s } label: {
                        HStack {
                            Text(s)
                                .font(SoulTheme.Font.bodyText)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .fill(SoulTheme.Color.surface))
                        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
            .hapticOnTap()
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: Message bubble

    private func bubble(_ msg: SoulChatService.Message) -> some View {
        HStack(alignment: .top) {
            if msg.role == .assistant {
                bubbleContent(msg, isUser: false)
                Spacer(minLength: 32)
            } else {
                Spacer(minLength: 32)
                bubbleContent(msg, isUser: true)
            }
        }
    }

    private func bubbleContent(_ msg: SoulChatService.Message, isUser: Bool) -> some View {
        Text(msg.content)
            .font(SoulTheme.Font.bodyText)
            .foregroundStyle(isUser
                             ? SoulTheme.Color.onAccent
                             : SoulTheme.Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                    .fill(isUser
                          ? AnyShapeStyle(SoulTheme.Color.primary)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                    .stroke(isUser ? Color.clear : SoulTheme.Color.divider, lineWidth: 0.5)
            )
    }

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(SoulTheme.Color.textSecondary)
                    .frame(width: 6, height: 6)
                    .opacity(0.5)
                    .scaleEffect(1)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: isSending)
            }
            Text("Soul está pensando…")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: Composer

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Pregúntale a Soul…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(SoulTheme.Color.surface))
                .overlay(Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5))

            Button {
                Task { await sendCurrent() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(SoulTheme.Color.primary))
                    .opacity(canSend ? 1 : 0.5)
            }
            .disabled(!canSend)
            .hapticOnTap()
        }
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.bottom, 110)   // clear the floating tab bar
        .padding(.top, 8)
        .background(SoulTheme.Color.background)
    }

    private var canSend: Bool {
        !isSending && !input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Send

    private func sendCurrent() async {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let userMsg = SoulChatService.Message(role: .user, content: text)
        messages.append(userMsg)
        input = ""
        errorText = nil
        isSending = true

        do {
            let reply = try await SoulChatService.shared.send(
                messages: messages,
                context: buildContext()
            )
            messages.append(SoulChatService.Message(role: .assistant, content: reply))
        } catch {
            errorText = error.localizedDescription
        }
        isSending = false
    }

    private func buildContext() -> SoulChatService.Context {
        let bioResult = BioAgeCalculator.compute(
            profile: store.profile,
            inputs: store.bioAgeInputs,
            restingHR: health.restingHeartRate,
            hrv: health.hrv,
            steps: health.steps,
            sleepHours: health.sleepHours
        )
        let recentMood = store.moodLog.prefix(5).map {
            SoulChatService.Context.MoodEntry(score: $0.score, emoji: $0.emoji, note: $0.note)
        }
        let labsSummary: String? = {
            guard let last = store.labReports.first else { return nil }
            if let summary = last.aiSummary, !summary.isEmpty { return summary }
            return "Reporte: \(last.title) — \(last.lab)"
        }()
        return SoulChatService.Context(
            name: store.profile.name.isEmpty ? nil : store.profile.name,
            age_bracket: store.profile.age.rawValue,
            activity_level: store.profile.activity.rawValue,
            interests: store.profile.interests.map { $0.rawValue },
            goal: store.profile.goal.isEmpty ? nil : store.profile.goal,
            current_streak_days: store.streak.currentStreak,
            bio_age_years: bioResult.biologicalAge,
            chronological_age_years: bioResult.chronologicalAge,
            recent_lab_summary: labsSummary,
            recent_mood: recentMood.isEmpty ? nil : Array(recentMood),
            membership_tier: store.profile.membershipTier.rawValue
        )
    }
}
