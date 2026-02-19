import SwiftUI

// MARK: - Stable Form Rows

extension View {
    /// Prevents form row height from shifting when a TextField gains focus on iOS.
    @ViewBuilder
    func stableFormRow() -> some View {
        #if os(iOS)
        self.frame(minHeight: 22)
        #else
        self
        #endif
    }
}

// MARK: - Platform Colors

extension Color {
    static var platformWindowBackground: Color {
        #if os(macOS)
        Color(.windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var platformControlBackground: Color {
        #if os(macOS)
        Color(.controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }
}
