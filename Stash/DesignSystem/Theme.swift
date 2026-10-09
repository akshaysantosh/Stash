import SwiftUI

/// Akshay's personal design system: warm cream/terracotta palette, calm and editorial.
/// Light-mode only by design (the source system is `color-scheme: light`) — see StashApp.
/// Started as a verbatim copy of PriceTrack's theme; Stash's copy has since diverged on purpose
/// (text styles for Dynamic Type, spacing/radius scales, a darker muted text colour).
///
/// Accent rule: terracotta is for the one primary action on a screen, the selected state, and
/// links — not for decoration.
extension Color {
    static let ink = Color(hex: "#1a1815")
    static let bodyText = Color(hex: "#2b2926")
    static let textSecondary = Color(hex: "#6b6862")
    /// Metadata, hints and tags. Darkened from the old #8f8b84 so small text stays readable on cream.
    static let textMuted = Color(hex: "#7a766f")
    static let bgPage = Color(hex: "#f7f6f3")
    static let bgCard = Color(hex: "#ffffff")
    static let borderCard = Color(hex: "#e5e2da")
    static let accent = Color(hex: "#b5541f")
    static let accentSuccess = Color(hex: "#4a7a4a")
    static let chipBg = Color(hex: "#ede9e1")
    static let chipText = Color(hex: "#45423d")
    static let chipAltBg = Color(hex: "#fbe8d9")
    static let chipAltText = Color(hex: "#8a4a15")
    static let calloutInfoBg = Color(hex: "#fdf8e8")
    static let calloutInfoBorder = Color(hex: "#e8dca0")
    static let calloutInfoText = Color(hex: "#7d6c34")
    static let calloutWarnBg = Color(hex: "#fdf0ea")
    static let calloutWarnBorder = Color(hex: "#f0c1a0")
    static let calloutWarnText = Color(hex: "#9a4a1f")
}

/// Built on text styles so everything scales with Dynamic Type.
enum AppFont {
    static func detailTitle() -> Font { .title2.weight(.bold) }
    static func cardHeadline() -> Font { .headline.weight(.bold) }
    static func rowTitle() -> Font { .callout.weight(.semibold) }
    static func sectionLabel() -> Font { .caption.weight(.semibold) }
    static func button() -> Font { .callout.weight(.semibold) }
    static func chip() -> Font { .footnote.weight(.semibold) }
    static func body() -> Font { .subheadline }
    static func secondaryDetail() -> Font { .footnote }
    static func caption() -> Font { .caption }
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum AppRadius {
    static let thumb: CGFloat = 14
    static let button: CGFloat = 14
    static let card: CGFloat = 16
    static let banner: CGFloat = 12
}

enum AppMetrics {
    static let cardRadius = AppRadius.card
    static let cardPadding = AppSpacing.l
    static let cardSpacing = AppSpacing.l
}

extension String {
    /// Tags are stored bare ("ai") and always displayed as "#ai", everywhere.
    var asTag: String { "#\(self)" }
}
