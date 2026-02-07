import SwiftUI

enum Theme {
    // MARK: - Font sizes

    enum Font {
        /// Time pill / timestamp label
        static let timestamp: CGFloat = 12
        /// Body text, input field, list row text
        static let body: CGFloat = 12
        /// Body text medium weight (titles, labels)
        static let bodyMedium: CGFloat = 12
        /// Body text semibold (section headers)
        static let bodySemibold: CGFloat = 12
        /// Row title, checkbox, small icons
        static let title: CGFloat = 16
        /// Row title medium weight
        static let titleMedium: CGFloat = 16
        /// Action icon (delete, etc.)
        static let icon: CGFloat = 16
        /// Large icon (add button)
        static let iconLarge: CGFloat = 18
        /// Empty state / hero icon
        static let emptyStateIcon: CGFloat = 48
    }

    // MARK: - Opacities

    enum Opacity {
        /// Completed row dimming
        static let completedRow: Double = 0.5
        /// Time pill / capsule background
        static let pillBackground: Double = 0.08
        /// Row highlight, focused row, sheet row background
        static let rowHighlight: Double = 0.05
        /// Visible action button (e.g. delete when active)
        static let buttonActive: Double = 0.8
        /// Add-todo / input container background
        static let inputBackground: Double = 0.15
        /// Sheet overlay dim
        static let overlayDim: Double = 0.3
        /// Sheet drag handle
        static let handleMuted: Double = 0.5
        /// Ripple effect accent
        static let rippleAccent: Double = 0.3
    }

    // MARK: - Semantic colors

    enum Color {
        /// Completed task checkmark (e.g. in sheet)
        static let completedCheckmark = SwiftUI.Color.green
    }
}
