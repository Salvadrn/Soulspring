import Foundation

/// Produces a human-friendly summary of a lab report.
///
/// Two backends, in order of preference:
///   1. **Supabase Edge Function** (recommended for production). The app
///      calls your edge function `analyze-lab`, which holds any model
///      provider key server-side. Set `AIConfig.edgeFunctionURL` to enable.
///   2. **Local stub** — deterministic summary from parsed biomarkers,
///      ensures the UI always renders something useful even offline.
///
/// The app never embeds a model-provider API key: summarization either goes
/// through your own server-side function or stays fully on-device.
enum AIConfig {
    /// Preferred path: your Supabase Edge Function URL.
    /// Example: "https://YOUR-PROJECT.functions.supabase.co/analyze-lab"
    static var edgeFunctionURL: String = ""
}

enum LabAIService {

    static func summarize(report: LabReport) async -> String {
        if !AIConfig.edgeFunctionURL.isEmpty,
           let live = try? await callEdgeFunction(for: report) {
            return live
        }
        return localSummary(for: report)
    }

    // MARK: - Supabase Edge Function (preferred)

    /// POSTs `{report: {...}}` to the edge function; expects `{summary: "..."}`.
    private static func callEdgeFunction(for report: LabReport) async throws -> String {
        guard let url = URL(string: AIConfig.edgeFunctionURL) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if SupabaseConfig.isConfigured {
            req.setValue("Bearer \(SupabaseConfig.anonKey)",
                         forHTTPHeaderField: "Authorization")
            req.setValue(SupabaseConfig.anonKey,
                         forHTTPHeaderField: "apikey")
        }

        let payload: [String: Any] = [
            "title":       report.title,
            "lab":         report.lab,
            "reportedAt":  ISO8601DateFormatter().string(from: report.reportedAt),
            "markers":     report.markers.map { marker -> [String: Any] in
                [
                    "name":  marker.name,
                    "value": marker.value,
                    "unit":  marker.unit,
                    "status": marker.status.rawValue,
                    "refLow":  marker.referenceLow as Any,
                    "refHigh": marker.referenceHigh as Any,
                ]
            },
            "rawText": report.rawText
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(EdgeResponse.self, from: data)
        return decoded.summary
    }

    private struct EdgeResponse: Decodable { let summary: String }

    // MARK: - Local stub

    private static func localSummary(for report: LabReport) -> String {
        let high = report.markers.filter { $0.status == .high }
        let low  = report.markers.filter { $0.status == .low }
        let ok   = report.markers.filter { $0.status == .normal }

        var parts: [String] = []

        if report.markers.isEmpty {
            return "No pudimos extraer biomarcadores de este PDF. Intenta con uno legible o agrega los valores manualmente para que el equipo del Sanctuary los revise."
        }

        parts.append("Se procesaron \(report.markers.count) biomarcadores. \(ok.count) dentro de rango, \(high.count) elevados y \(low.count) bajos.")

        if !high.isEmpty {
            let names = high.prefix(3).map { "\($0.name) (\(formatted($0.value)) \($0.unit))" }
                           .joined(separator: ", ")
            parts.append("Elevados que sugerimos revisar: \(names). Estos marcadores responden bien a ajustes de nutrición, sueño y manejo de estrés.")
        }
        if !low.isEmpty {
            let names = low.prefix(3).map { "\($0.name) (\(formatted($0.value)) \($0.unit))" }
                          .joined(separator: ", ")
            parts.append("Por debajo del rango: \(names). Podría indicar carencias nutricionales o absorción — vale la pena discutirlo con un profesional.")
        }

        parts.append("Acciones Soulspring: agenda una consulta de medicina funcional para un plan bio-individualizado, integra una rutina de Zona 2 y suma el ritual del caldo regenerador en tu estancia.")

        return parts.joined(separator: "\n\n")
    }

    private static func formatted(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", d)
            : String(format: "%.2f", d)
    }
}
