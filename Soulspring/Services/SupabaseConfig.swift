import Foundation

/// Credentials for the Soulspring Supabase project.
///
/// Fill these in with your project's URL and anon (public) key. Never commit
/// service role keys here — those belong on the server.
///
/// Suggested table layout (all with `user_id uuid references auth.users`):
///   • `profiles`      — name, age_bracket, activity_level, interests[], goal, tier
///   • `habits`        — title, cue, icon, color_hex, target_per_day
///   • `habit_checks`  — habit_id, completed_at
///   • `reminders`     — title, kind, time, is_on
///   • `orders`        — meal_id, scheduled_for, notes
///   • `health_snapshots` — bpm, rhr, hrv, steps, kcal, sleep_hours, captured_at
///
/// Use Row Level Security with `user_id = auth.uid()` on every table.
enum SupabaseConfig {
    static let url: String      = "https://YOUR-PROJECT.supabase.co"
    static let anonKey: String  = "YOUR-ANON-KEY"

    static var isConfigured: Bool {
        !url.contains("YOUR-PROJECT") && !anonKey.contains("YOUR-ANON-KEY")
    }
}
