import Foundation
import SwiftData

@Model
final class SavedLink {
    var id: UUID = UUID()
    var url: String = ""
    var title: String = ""
    var imageData: Data? = nil
    var categoryRaw: String = Category.other.rawValue
    var isDone: Bool = false
    var addedAt: Date = Date()
    var note: String = ""
    var snippet: String = ""
    var publishedAt: Date? = nil
    var tags: [String] = []

    init(
        url: String,
        title: String,
        imageData: Data? = nil,
        category: Category = .other,
        note: String = "",
        snippet: String = "",
        publishedAt: Date? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.imageData = imageData
        self.categoryRaw = category.rawValue
        self.isDone = false
        self.addedAt = Date()
        self.note = note
        self.snippet = snippet
        self.publishedAt = publishedAt
        self.tags = tags
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Bare domain for display (e.g. "podcasts.apple.com"), stripped of "www.".
    var displayHost: String {
        URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url
    }
}
