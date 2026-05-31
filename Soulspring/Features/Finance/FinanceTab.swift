import SwiftUI

/// Top-level Finanzas tab. Wraps FinancesView in its own NavigationStack
/// so it lives as a first-class section.
struct FinanceTab: View {
    var body: some View {
        NavigationStack {
            FinancesView()
        }
    }
}
