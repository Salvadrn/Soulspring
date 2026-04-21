import Foundation

/// Wraps a call to Claude to get a human-friendly summary of a lab report.
///
/// Three backends, in order of preference:
///   1. **Supabase Edge Function** (recommended for production). The app
///      calls your edge function `analyze-lab`, which holds the real
///      Anthropic key server-side. Set `AIConfig.edgeFunctionURL` to enable.
///   2. **Direct Anthropic** — only for local dev. Bundling the key in a
///      shipped iOS app makes it extractable, so don't do this in prod.
///   3. **Local stub** — deterministic summary from parsed biomarkers,
///      ensures the UI always renders something useful.
///
/// There is NO way to reach the Claude CLI from a mobile app. The CLI is a
/// developer tool that runs on a workstation; the network path the app
/// speaks is always the HTTPS Messages API (directly or via your proxy).
enum AIConfig {
    /// Preferred path: your Supabase Edge Function URL.
    /// Example: "https://YOUR-PROJECT.functions.supabase.co/analyze-lab"
    static var edgeFunctionURL: String = ""

    /// Dev only. Never ship with this set.
    static var anthropicAPIKey: String = ""

    static let model: String = "claude-opus-4-7"
}

enum LabAIService {

    static func summarize(report: LabReport) async -> String {
        if !AIConfig.edgeFunctionURL.isEmpty,
           let live = try? await callEdgeFunction(for: report) {
            return live
        }
        if !AIConfig.anthropicAPIKey.isEmpty,
           let live = try? await callAnthropic(for: report) {
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

    // MARK: - Direct Anthropic (dev only)

    private static func callAnthropic(for report: LabReport) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(AIConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",           forHTTPHeaderField: "anthropic-version")

        let prompt = buildPrompt(for: report)
        let body: [String: Any] = [
            "model": AIConfig.model,
            "max_tokens": 700,
            "system": "Eres médico funcional Soulspring. Das lecturas cálidas, claras y accionables sobre laboratorios. Nada alarmista. Tres párrafos máximo. Español neutro.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let parsed = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return parsed.content.first?.text ?? localSummary(for: report)
    }

    private static func buildPrompt(for report: LabReport) -> String {
        var lines: [String] = [
            "Analiza este laboratorio y devuelve un resumen para el usuario.",
            "Estudio: \(report.title) · \(report.lab) · \(report.reportedAt.formatted(date: .abbreviated, time: .omitted))",
            "",
            "Biomarcadores parseados:"
        ]
        for m in report.markers {
            var line = "- \(m.name): \(m.value) \(m.unit) [\(m.status.rawValue)]"
            if let lo = m.referenceLow, let hi = m.referenceHigh {
                line += " (ref \(lo)–\(hi))"
            }
            lines.append(line)
        }
        lines.append("")
        lines.append("Escribe: (1) lectura global, (2) top 3 puntos a mejorar, (3) acciones concretas Soulspring (experiencias, hábitos o consulta).")
        return lines.joined(separator: "\n")
    }

    private struct AnthropicResponse: Decodable {
        let content: [Block]
        struct Block: Decodable { let text: String }
    }

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
