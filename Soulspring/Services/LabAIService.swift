import Foundation

/// Wraps a call to Claude (or any LLM) to get a human-friendly summary of a
/// lab report. Runs either:
///   • **Live**, when `AIConfig.anthropicAPIKey` is filled in — hits the
///     Anthropic Messages API directly.
///   • **Local stub**, otherwise — produces a deterministic summary from
///     the parsed biomarkers so the UI still renders something useful.
///
/// Keep the API key **server-side** for production. The stub here is fine
/// for development and demos.
enum AIConfig {
    static var anthropicAPIKey: String = ""   // fill in to enable live calls
    static let model: String = "claude-opus-4-7"
}

enum LabAIService {

    static func summarize(report: LabReport) async -> String {
        if !AIConfig.anthropicAPIKey.isEmpty {
            if let live = try? await callAnthropic(for: report) {
                return live
            }
        }
        return localSummary(for: report)
    }

    // MARK: - Live Anthropic call

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
