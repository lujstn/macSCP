import SwiftUI

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
