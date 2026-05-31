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
    static let url: String      = "https://wbemkfaacbainvxgtgte.supabase.co"
    /// Legacy JWT-format anon key. Required for Edge Functions with verify_jwt=true
    /// (the modern publishable key sb_publishable_... is not a JWT and fails JWT validation).
    static let anonKey: String  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndiZW1rZmFhY2JhaW52eGd0Z3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3OTEyODAsImV4cCI6MjA5MjM2NzI4MH0.wRdCLttYe7inaCWhngNR4cRaXZkBa1VQ4l8tfXUdarE"

    static var isConfigured: Bool {
        !url.contains("YOUR-PROJECT") && !anonKey.contains("YOUR-ANON-KEY")
    }
}
