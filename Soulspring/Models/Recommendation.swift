import Foundation

struct Recommendation: Identifiable, Hashable {
    let id = UUID()
    let interest: HealthInterest
    let title: String
    let summary: String
    let minutes: Int
    let category: Category

    enum Category: String {
        case breathwork  = "Respiración"
        case movement    = "Movimiento"
        case nutrition   = "Nutrición"
        case restorative = "Restaurativo"
        case study       = "Estudio"
        case ritual      = "Ritual"
    }
}

enum RecommendationEngine {
    /// Curates a feed of recommendations from the user's selected interests.
    static func feed(for interests: Set<HealthInterest>) -> [Recommendation] {
        let pool = catalog.filter { interests.contains($0.interest) }
        return pool.isEmpty ? Array(catalog.prefix(4)) : pool
    }

    static let catalog: [Recommendation] = [
        .init(interest: .cardiovascular,
              title: "Coherencia cardíaca 5–5",
              summary: "Respira 5 segundos dentro, 5 segundos fuera. Baja tu HRV en minutos.",
              minutes: 6, category: .breathwork),
        .init(interest: .cardiovascular,
              title: "Caminata Zona 2",
              summary: "35 minutos a ritmo conversacional. Construye base aeróbica.",
              minutes: 35, category: .movement),
        .init(interest: .sleep,
              title: "Ritual de anochecer",
              summary: "Luz cálida, té de tila y 10 respiraciones 4-7-8 antes de dormir.",
              minutes: 15, category: .ritual),
        .init(interest: .sleep,
              title: "Yoga nidra",
              summary: "Relajación profunda guiada para restaurar tu sistema nervioso.",
              minutes: 20, category: .restorative),
        .init(interest: .nutrition,
              title: "Plato del Santuario",
              summary: "Mitad plantas, un cuarto proteína limpia, un cuarto grano ancestral.",
              minutes: 0, category: .nutrition),
        .init(interest: .nutrition,
              title: "Hidratación mineral",
              summary: "Agua con limón, sal rosada y clorofila al despertar.",
              minutes: 3, category: .ritual),
        .init(interest: .movement,
              title: "Fuerza + movilidad",
              summary: "Rutina de 7 movimientos fundamentales, 25 minutos.",
              minutes: 25, category: .movement),
        .init(interest: .mindfulness,
              title: "Meditación de presencia",
              summary: "Observa tu respiración sin modificarla. Regresa cada vez que te pierdas.",
              minutes: 12, category: .breathwork),
        .init(interest: .longevity,
              title: "Ayuno intermitente 14:10",
              summary: "Ventana de alimentación entre 10:00 y 20:00. Activa autofagia.",
              minutes: 0, category: .nutrition),
        .init(interest: .longevity,
              title: "Baño de contraste",
              summary: "3 ciclos de 2 min calor / 30 seg frío. Mitocondrias felices.",
              minutes: 10, category: .restorative),
        .init(interest: .detox,
              title: "Cepillado en seco",
              summary: "Estimula linfa antes de la ducha durante 4 minutos.",
              minutes: 4, category: .ritual),
        .init(interest: .detox,
              title: "Infusión alcalina",
              summary: "Jengibre, cúrcuma, limón y pizca de pimienta negra.",
              minutes: 5, category: .nutrition),
        .init(interest: .emotional,
              title: "Journaling somático",
              summary: "¿Qué siente mi cuerpo hoy? Escribe sin editar por 10 minutos.",
              minutes: 10, category: .ritual),
        .init(interest: .emotional,
              title: "Caminata consciente",
              summary: "20 min al aire libre escuchando solo tus pasos y tu respiración.",
              minutes: 20, category: .restorative),
    ]
}
