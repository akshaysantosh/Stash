#if DEBUG
import SwiftData
import SwiftUI
import UIKit

/// Debug-only: launch with `-seedSampleData` to run against an in-memory store filled with
/// sample links (thumbnails are drawn in code, so no network is needed). Used for screenshots
/// and eyeballing layouts in the Simulator.
enum SampleData {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([SavedLink.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        for link in links() { context.insert(link) }
        try? context.save()
        return container
    }

    static func links() -> [SavedLink] {
        func day(_ daysAgo: Int) -> Date { Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date() }

        let items: [SavedLink] = [
            SavedLink(url: "https://www.youtube.com/watch?v=sample1", title: "Opportunities in AI — a practical talk for builders",
                      imageData: art(.systemRed, "play.fill"), category: .watch,
                      snippet: "A walk-through of where applied AI is creating the most value right now, and how small teams can take advantage of it.",
                      publishedAt: day(12), tags: ["ai", "product"]),
            SavedLink(url: "https://open.spotify.com/episode/sample2", title: "Inside the design process at a fast-growing product company",
                      imageData: art(.systemGreen, "headphones"), category: .listen,
                      snippet: "A long conversation about shipping quickly without losing craft.",
                      publishedAt: day(20), tags: ["product", "storytelling"]),
            SavedLink(url: "https://example.substack.com/p/storytelling-for-product-people", title: "Storytelling for product people: the three-sentence pitch",
                      imageData: art(.systemOrange, "doc.text.fill"), category: .read,
                      note: "Try this for the next roadmap review.",
                      snippet: "Why the best product managers are really narrators, and a simple template for turning a spec into a story.",
                      publishedAt: day(3), tags: ["storytelling", "product", "leadership"]),
            SavedLink(url: "https://www.youtube.com/watch?v=sample4", title: "How good teams decide what not to build",
                      imageData: art(.systemIndigo, "play.fill"), category: .watch,
                      publishedAt: day(30), tags: ["product"]),
            SavedLink(url: "https://podcasts.apple.com/au/podcast/sample5", title: "The long road to a calmer inbox",
                      imageData: nil, category: .listen, publishedAt: day(6), tags: ["leadership"]),
            SavedLink(url: "https://example.substack.com/p/ai-agents-field-notes", title: "Field notes on building AI agents in production",
                      imageData: art(.systemTeal, "doc.text.fill"), category: .read,
                      snippet: "What broke, what held up, and what we'd do differently.",
                      publishedAt: day(1), tags: ["ai"]),
            SavedLink(url: "https://www.linkedin.com/posts/sample7", title: "A thoughtful post on career sabbaticals",
                      imageData: nil, category: .socials, publishedAt: day(8), tags: []),
            SavedLink(url: "https://www.opentable.com/r/sample8", title: "Little Pasta Bar — Surry Hills",
                      imageData: art(.systemBrown, "fork.knife"), category: .visit, tags: []),
            SavedLink(url: "https://www.amazon.com.au/dp/sample9", title: "Noise-cancelling headphones",
                      imageData: art(.systemGray, "bag.fill"), category: .buy, tags: []),
        ]
        let vaulted: [SavedLink] = [
            SavedLink(url: "https://www.youtube.com/watch?v=sample10", title: "A short history of the spreadsheet",
                      imageData: art(.systemPurple, "play.fill"), category: .watch, publishedAt: day(40), tags: ["product"]),
            SavedLink(url: "https://example.substack.com/p/done-reading", title: "Writing clearly under time pressure",
                      imageData: art(.systemPink, "doc.text.fill"), category: .read, publishedAt: day(50), tags: ["storytelling"]),
            SavedLink(url: "https://open.spotify.com/episode/sample11", title: "What makes a great product conversation",
                      imageData: art(.systemMint, "headphones"), category: .listen, publishedAt: day(58), tags: ["product", "leadership"]),
            SavedLink(url: "https://www.youtube.com/watch?v=sample12", title: "A beginner's guide to prompting",
                      imageData: art(.systemCyan, "play.fill"), category: .watch, publishedAt: day(66), tags: ["ai"]),
        ]
        vaulted.forEach { $0.isDone = true }
        // Newest first in the order written above, so screenshots show a predictable mix.
        let all = items + vaulted
        for (index, link) in all.enumerated() {
            link.addedAt = Date().addingTimeInterval(-Double(index) * 3600)
        }
        // Two links pinned to Up next so the section shows in screenshots.
        items[2].upNextAt = Date().addingTimeInterval(-120)
        items[5].upNextAt = Date().addingTimeInterval(-60)
        return all
    }

    private static func art(_ color: UIColor, _ symbol: String) -> Data? {
        let size = CGSize(width: 640, height: 360)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [color.withAlphaComponent(0.95).cgColor, color.withAlphaComponent(0.55).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            let config = UIImage.SymbolConfiguration(pointSize: 110, weight: .regular)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                glyph.draw(at: CGPoint(x: (size.width - glyph.size.width) / 2, y: (size.height - glyph.size.height) / 2))
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif
