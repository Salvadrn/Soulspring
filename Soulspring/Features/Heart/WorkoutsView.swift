import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter: Workout.Zone? = nil
    @State private var selected: Workout? = nil

    private var workouts: [Workout] {
        if let f = filter {
            return Workout.catalog.filter { $0.zone == f }
        }
        return Workout.catalog
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                filters
                ForEach(workouts) { w in
                    Button { selected = w } label: { WorkoutCard(workout: w) }
                        .buttonStyle(.plain)
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Entrenamiento")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { w in
            WorkoutDetailSheet(workout: w)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Movimiento")
            Text("Cuerpo fuerte, mente clara.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Todos", selected: filter == nil) { filter = nil }
                ForEach(Workout.Zone.allCases, id: \.self) { z in
                    chip(z.rawValue, selected: filter == z) { filter = z }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(title)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(selected ? SoulTheme.Color.backgroundWarm : SoulTheme.Color.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    Capsule().fill(selected
                                   ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                   : AnyShapeStyle(SoulTheme.Color.surface)))
                .overlay(Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
    }
}

// MARK: - Workout card

struct WorkoutCard: View {
    let workout: Workout
    var body: some View {
        SoulCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .fill(SoulTheme.Palette.cream)
                        .frame(width: 58, height: 58)
                    Text(workout.emoji).font(.system(size: 28))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(workout.summary)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        SoulChip(text: workout.zone.rawValue, tint: SoulTheme.Palette.moss)
                        SoulChip(text: "\(workout.durationMinutes) min", tint: SoulTheme.Palette.earth)
                        SoulChip(text: workout.intensity.rawValue, tint: SoulTheme.Palette.terracotta)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }
}

// MARK: - Detail

struct WorkoutDetailSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let workout: Workout
    @State private var started = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        hero
                        VStack(alignment: .leading, spacing: 8) {
                            SoulEyebrow(text: "Ejercicios")
                            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { idx, ex in
                                exerciseRow(idx: idx + 1, ex: ex)
                            }
                        }
                        actionButton
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
            }
        }
    }

    private var hero: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 10) {
                Text(workout.emoji).font(.system(size: 40))
                Text(workout.title)
                    .font(SoulTheme.Font.title)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(workout.summary)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                HStack(spacing: 8) {
                    SoulChip(text: "\(workout.durationMinutes) min", tint: SoulTheme.Palette.earth)
                    SoulChip(text: workout.zone.rawValue, tint: SoulTheme.Palette.moss)
                    SoulChip(text: workout.intensity.rawValue, tint: SoulTheme.Palette.terracotta)
                }
            }
        }
    }

    private func exerciseRow(idx: Int, ex: Workout.Exercise) -> some View {
        SoulCard {
            HStack(spacing: 12) {
                Text("\(idx)")
                    .font(SoulTheme.Font.display(20, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.primary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(ex.detail)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var actionButton: some View {
        Button {
            if started {
                store.markWorkoutDone(workout.id)
                dismiss()
            } else {
                started = true
            }
        } label: {
            HStack {
                Image(systemName: started ? "checkmark.circle.fill" : "play.fill")
                Text(started ? "Terminar" : "Iniciar entrenamiento")
            }
        }
        .buttonStyle(SoulPrimaryButtonStyle())
        .padding(.top, 6)
    }
}
