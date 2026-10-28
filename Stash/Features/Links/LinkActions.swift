import SwiftData
import SwiftUI

/// Deleting and vaulting a link, each with its own haptic, an animated change in the list, and a
/// toast with Undo — so the same thing happens whether you swipe a row, long-press it, or use the
/// menu on a link's own page.
@MainActor
enum LinkActions {
    /// Everything needed to put a deleted link back exactly as it was.
    private struct Snapshot {
        let id: UUID, url: String, title: String, imageData: Data?, category: Category
        let isDone: Bool, addedAt: Date, note: String, snippet: String, publishedAt: Date?
        let tags: [String], upNextAt: Date?

        init(_ link: SavedLink) {
            id = link.id; url = link.url; title = link.title; imageData = link.imageData
            category = link.category; isDone = link.isDone; addedAt = link.addedAt; note = link.note
            snippet = link.snippet; publishedAt = link.publishedAt; tags = link.tags; upNextAt = link.upNextAt
        }

        func restore() -> SavedLink {
            let link = SavedLink(url: url, title: title, imageData: imageData, category: category,
                                 note: note, snippet: snippet, publishedAt: publishedAt, tags: tags)
            link.id = id
            link.isDone = isDone
            link.addedAt = addedAt
            link.upNextAt = upNextAt
            return link
        }
    }

    static func delete(_ link: SavedLink, in context: ModelContext, toasts: ToastCenter) {
        let snapshot = Snapshot(link)
        Haptics.deleted()
        withAnimation(.snappy(duration: 0.3)) { context.delete(link) }
        toasts.show(Toast(kind: .deleted, message: "Link deleted") {
            Haptics.reopened()
            withAnimation(.snappy(duration: 0.3)) { context.insert(snapshot.restore()) }
        })
    }

    static func toggleDone(_ link: SavedLink, toasts: ToastCenter) {
        let wasDone = link.isDone
        let previousUpNext = link.upNextAt
        wasDone ? Haptics.reopened() : Haptics.vaulted()
        withAnimation(.snappy(duration: 0.35)) { link.toggleDone() }
        toasts.show(Toast(kind: wasDone ? .reopened : .vaulted,
                          message: wasDone ? "Back in The Stash" : "Moved to the Vault") {
            Haptics.reopened()
            withAnimation(.snappy(duration: 0.35)) {
                link.isDone = wasDone
                link.upNextAt = previousUpNext
            }
        })
    }
}
