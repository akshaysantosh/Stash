import Foundation

/// "Up next" is a short pinned queue — a few things to get to soon, not another pile. It holds at
/// most `limit` links; pinning one more quietly releases the oldest pin.
enum UpNext {
    static let limit = 3

    /// Pins `link`, or unpins it if it's already pinned. `pinned` is every currently pinned link.
    static func toggle(_ link: SavedLink, pinned: [SavedLink]) {
        if link.isUpNext {
            link.upNextAt = nil
            return
        }
        let others = pinned
            .filter { $0.id != link.id }
            .sorted { ($0.upNextAt ?? .distantPast) < ($1.upNextAt ?? .distantPast) }
        let overflow = others.count - (limit - 1)
        if overflow > 0 {
            others.prefix(overflow).forEach { $0.upNextAt = nil }
        }
        link.upNextAt = Date()
    }
}
