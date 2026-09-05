import Foundation
import SwiftUI

/// Intent-based, not source-based — what you'll actually do with the link later, rather than
/// which service it came from. Auto-suggested from the URL's domain, always user-editable.
enum Category: String, Codable, CaseIterable, Identifiable {
    case watch
    case listen
    case read
    case socials
    case visit
    case buy
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .watch: return "Watch"
        case .listen: return "Listen"
        case .read: return "Read"
        case .socials: return "Socials"
        case .visit: return "Visit"
        case .buy: return "Buy"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .watch: return "play.rectangle.fill"
        case .listen: return "headphones"
        case .read: return "doc.text.fill"
        case .socials: return "at"
        case .visit: return "fork.knife"
        case .buy: return "bag.fill"
        case .other: return "bookmark.fill"
        }
    }

    /// A distinct warm-palette tone per category, used as a subtle left-edge accent in list rows.
    var accentColor: Color {
        switch self {
        case .watch: return .accent
        case .listen: return .accentSuccess
        case .read: return .chipAltText
        case .socials: return .calloutInfoText
        case .visit: return .calloutWarnText
        case .buy: return .categoryGold
        case .other: return .categoryClay
        }
    }

    /// Best-effort guess from the URL's host — always overridable by the user.
    static func guess(for url: URL) -> Category {
        let host = (url.host ?? "").lowercased()

        let watchHosts = ["youtube.com", "youtu.be", "vimeo.com", "netflix.com", "tv.apple.com"]
        let listenHosts = ["open.spotify.com", "podcasts.apple.com", "music.apple.com", "soundcloud.com", "audible.com"]
        let socialsHosts = ["linkedin.com", "instagram.com", "facebook.com", "fb.com", "x.com", "twitter.com", "threads.net"]
        let buyHosts = ["amazon.com", "amazon.com.au", "ebay.com", "etsy.com"]
        let visitHosts = ["opentable.com", "resy.com", "maps.apple.com", "google.com/maps", "tripadvisor.com", "yelp.com"]

        if watchHosts.contains(where: { host.contains($0) }) { return .watch }
        if listenHosts.contains(where: { host.contains($0) }) { return .listen }
        if socialsHosts.contains(where: { host.contains($0) }) { return .socials }
        if buyHosts.contains(where: { host.contains($0) }) { return .buy }
        if visitHosts.contains(where: { host.contains($0) }) { return .visit }
        return .read
    }
}
