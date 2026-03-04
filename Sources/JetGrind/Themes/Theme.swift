import SwiftUI
import AppKit

private func adaptiveColor(light: NSColor, dark: NSColor) -> SwiftUI.Color {
    SwiftUI.Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
    }))
}

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
        /// Action button label text
        static let actionLabel: CGFloat = 11
        /// Action button icon
        static let actionIcon: CGFloat = 12
        /// Description text
        static let description: CGFloat = 13
        /// Link pill label
        static let linkPillLabel: CGFloat = 11
        /// Link pill favicon
        static let linkPillFavicon: CGFloat = 12
    }

    // MARK: - Opacities

    enum Opacity {
        /// Completed row dimming
        static let completedRow: Double = 0.5
        /// Time pill / capsule background
        static let pillBackground: Double = 0.08
        /// Row highlight, focused row, sheet row background
        static let rowHighlight: Double = 0.12
        /// Visible action button (e.g. delete when active)
        static let buttonActive: Double = 0.8
        /// Add-todo / input container background
        static let inputBackground: Double = 0.15
        /// Link overlay backdrop dim
        static let linkOverlayDim: Double = 0.6
        /// Sheet overlay dim
        static let overlayDim: Double = 0.3
        /// Sheet drag handle
        static let handleMuted: Double = 0.5
        /// Ripple effect accent
        static let rippleAccent: Double = 0.3
        /// Description text
        static let descriptionText: Double = 0.7
        /// Edit dim on non-editing rows
        static let editDimOpacity: Double = 0.4
        /// Pastel row tint (dark mode)
        static let pastelRowDark: Double = 0.08
        /// Pastel row tint (light mode)
        static let pastelRowLight: Double = 0.12
        /// Warm input field tint
        static let inputWarm: Double = 0.10
    }

    // MARK: - Sizes

    enum Size {
        static let actionButtonSize: CGFloat = 26
        static let actionButtonExpandedWidth: CGFloat = 72
        static let actionButtonSpacing: CGFloat = 4
        static let linkPillHeight: CGFloat = 22
        static let linkPillCornerRadius: CGFloat = 11
        static let linkPillPaddingH: CGFloat = 8
        static let linkPillSpacing: CGFloat = 6
        static let linkPillInternalSpacing: CGFloat = 4
        static let editBlurRadius: CGFloat = 3.0
        static let inlinePillHeight: CGFloat = 18
        static let inlinePillPaddingH: CGFloat = 6
        static let inlinePillIconSize: CGFloat = 11
        static let inlinePillFontSize: CGFloat = 11
    }

    // MARK: - Semantic colors

    enum Color {
        /// Completed task checkmark (e.g. in sheet)
        static let completedCheckmark = SwiftUI.Color.green
        static let linkPillText = SwiftUI.Color.accentColor
        /// Warm cream/brown for input field
        static let inputWarm = adaptiveColor(light: NSColor(red: 0.40, green: 0.52, blue: 0.58, alpha: 1), dark: NSColor(red: 0.76, green: 0.62, blue: 0.48, alpha: 1))
    }

    // MARK: - Pastel palette

    enum Pastel {
        static let lavender = adaptiveColor(light: NSColor(red: 0.69, green: 0.61, blue: 0.85, alpha: 1), dark: NSColor(red: 0.58, green: 0.48, blue: 0.78, alpha: 1))
        static let peach    = adaptiveColor(light: NSColor(red: 0.93, green: 0.60, blue: 0.52, alpha: 1), dark: NSColor(red: 0.84, green: 0.48, blue: 0.40, alpha: 1))
        static let mint     = adaptiveColor(light: NSColor(red: 0.40, green: 0.78, blue: 0.70, alpha: 1), dark: NSColor(red: 0.30, green: 0.68, blue: 0.60, alpha: 1))
        static let sky      = adaptiveColor(light: NSColor(red: 0.45, green: 0.65, blue: 0.88, alpha: 1), dark: NSColor(red: 0.35, green: 0.55, blue: 0.80, alpha: 1))
        static let butter   = adaptiveColor(light: NSColor(red: 0.90, green: 0.78, blue: 0.42, alpha: 1), dark: NSColor(red: 0.82, green: 0.70, blue: 0.34, alpha: 1))
        static let rose     = adaptiveColor(light: NSColor(red: 0.88, green: 0.50, blue: 0.62, alpha: 1), dark: NSColor(red: 0.80, green: 0.40, blue: 0.52, alpha: 1))

        private static let all: [SwiftUI.Color] = [lavender, peach, mint, sky, butter, rose]

        static func color(for index: Int) -> SwiftUI.Color {
            all[index % all.count]
        }
    }
}
