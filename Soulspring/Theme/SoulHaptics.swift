import SwiftUI
import UIKit

/// Centralized haptic feedback for Soulspring.
/// Generators are kept alive as static instances so they're warm on first use.
enum SoulHaptics {
    enum Kind {
        case tap        // soft impact — most button presses
        case select     // selection changed (toggles, pickers)
        case success    // notification success
        case warning
        case error
    }

    private static let soft   = UIImpactFeedbackGenerator(style: .soft)
    private static let light  = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    static func fire(_ kind: Kind = .tap) {
        switch kind {
        case .tap:     soft.impactOccurred()
        case .select:  selection.selectionChanged()
        case .success: notification.notificationOccurred(.success)
        case .warning: notification.notificationOccurred(.warning)
        case .error:   notification.notificationOccurred(.error)
        }
    }

    /// Convenience aliases.
    static func tap()     { fire(.tap) }
    static func select()  { fire(.select) }
    static func success() { fire(.success) }
}

extension View {
    /// Attach this to any tappable view that doesn't go through
    /// `SoulPrimaryButtonStyle` / `SoulSecondaryButtonStyle` to get a
    /// consistent haptic on tap.
    func hapticOnTap(_ kind: SoulHaptics.Kind = .tap) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { SoulHaptics.fire(kind) }
        )
    }
}
