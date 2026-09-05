import Foundation
import LinkPresentation
import UIKit

/// Fetches a title/thumbnail for any URL via Apple's LinkPresentation framework
/// (LPMetadataProvider) — the same engine behind Messages/Safari link previews, reading each
/// site's own Open Graph tags with no per-service integration.
enum LinkMetadataService {
    struct Result {
        let title: String?
        let imageData: Data?
        var snippet: String? = nil
        var publishedDate: Date? = nil
    }

    enum FetchError: LocalizedError {
        case invalidURL

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "That doesn't look like a valid web link."
            }
        }
    }

    private static let mobileSafariUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    static func fetch(for urlString: String) async throws -> Result {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme,
              scheme == "http" || scheme == "https", let host = url.host else {
            throw FetchError.invalidURL
        }
        let lowerHost = host.lowercased()

        // LPMetadataProvider's built-in YouTube handling frequently returns the channel name
        // instead of the video title, so YouTube links go through its own public oEmbed API
        // (no key required) which reports the video title correctly. oEmbed has no publish
        // date field, so that's still filled in via the generic page scrape below.
        let youtubeHosts = ["youtube.com", "youtu.be"]
        if youtubeHosts.contains(where: { lowerHost.contains($0) }), var result = await fetchYouTubeOEmbed(for: url) {
            result.publishedDate = await fetchPublishedDate(for: url)
            return result
        }

        let provider = LPMetadataProvider()
        let metadata = try? await provider.startFetchingMetadata(for: url)
        let imageData: Data?
        if let imageProvider = metadata?.imageProvider {
            imageData = await loadImageData(from: imageProvider)
        } else if let iconProvider = metadata?.iconProvider {
            imageData = await loadImageData(from: iconProvider)
        } else {
            imageData = nil
        }
        var title = metadata?.title
        var snippet: String?
        var publishedDate: Date?

        // X/Twitter's public oEmbed endpoint reliably returns the actual post text and date,
        // which LPMetadataProvider does not surface — use it as the snippet under the author's name.
        let xHosts = ["x.com", "twitter.com"]
        if xHosts.contains(where: { lowerHost.contains($0) }), let tweet = await fetchXOEmbed(for: url) {
            if let authorTitle = tweet.title { title = authorTitle }
            snippet = tweet.text
            publishedDate = tweet.date
        }

        // LinkedIn/Instagram/Facebook have no free API for post content and often serve thin
        // metadata to non-browser requests, but a raw og:description scrape sometimes recovers
        // the caption. Best-effort only — may come back empty.
        let socialScrapeHosts = ["linkedin.com", "instagram.com", "facebook.com", "fb.com"]
        if socialScrapeHosts.contains(where: { lowerHost.contains($0) }) {
            if let rawTitle = title { title = extractPersonName(from: rawTitle) }
            if snippet == nil {
                snippet = await fetchOGDescription(for: url)
            }
        }

        if publishedDate == nil {
            publishedDate = await fetchPublishedDate(for: url)
        }

        return Result(title: title, imageData: imageData, snippet: snippet, publishedDate: publishedDate)
    }

    private struct YouTubeOEmbedResponse: Decodable {
        let title: String?
        let thumbnailUrl: String?

        enum CodingKeys: String, CodingKey {
            case title
            case thumbnailUrl = "thumbnail_url"
        }
    }

    private static func fetchYouTubeOEmbed(for url: URL) async -> Result? {
        var components = URLComponents(string: "https://www.youtube.com/oembed")
        components?.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let oembedURL = components?.url,
              let (data, _) = try? await URLSession.shared.data(from: oembedURL),
              let response = try? JSONDecoder().decode(YouTubeOEmbedResponse.self, from: data) else {
            return nil
        }

        var imageData: Data?
        if let thumbnailURLString = response.thumbnailUrl, let thumbnailURL = URL(string: thumbnailURLString),
           let (imageBytes, _) = try? await URLSession.shared.data(from: thumbnailURL) {
            imageData = UIImage(data: imageBytes)?.compressedForStorage()
        }
        return Result(title: response.title, imageData: imageData)
    }

    private struct XOEmbedResponse: Decodable {
        let authorName: String?
        let html: String?

        enum CodingKeys: String, CodingKey {
            case authorName = "author_name"
            case html
        }
    }

    private struct TweetInfo {
        let title: String?
        let text: String?
        let date: Date?
    }

    private static func fetchXOEmbed(for url: URL) async -> TweetInfo? {
        var components = URLComponents(string: "https://publish.twitter.com/oembed")
        components?.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        guard let oembedURL = components?.url,
              let (data, _) = try? await URLSession.shared.data(from: oembedURL),
              let response = try? JSONDecoder().decode(XOEmbedResponse.self, from: data) else {
            return nil
        }
        let title = response.authorName
        let text = response.html.flatMap(extractTweetText)
        let date = response.html.flatMap(extractTweetDate)
        guard title != nil || text != nil else { return nil }
        return TweetInfo(title: title, text: text, date: date)
    }

    private static func extractTweetText(fromHTML html: String) -> String? {
        guard let pStart = html.range(of: "<p"),
              let tagEnd = html.range(of: ">", range: pStart.upperBound..<html.endIndex),
              let pEnd = html.range(of: "</p>", range: tagEnd.upperBound..<html.endIndex) else {
            return nil
        }
        let fragment = String(html[tagEnd.upperBound..<pEnd.lowerBound])
        let text = decodeHTML(fragment)
        return text.isEmpty ? nil : text
    }

    /// The oEmbed blockquote ends with the tweet's permalink date, e.g.
    /// `&mdash; jack (@jack) <a href="...">March 21, 2006</a></blockquote>`.
    private static func extractTweetDate(fromHTML html: String) -> Date? {
        let pattern = "<a[^>]*>([^<]+)</a>\\s*</blockquote>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range), let textRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.date(from: decodeHTML(String(html[textRange])))
    }

    /// LinkedIn/Instagram/Facebook's og:title is the whole post blurb — e.g.
    /// `"#aiproductmanagement #aipm #pm | Aakash Gupta | 33 comments"` or
    /// `"Marc Cleroux on Instagram"`. This trims it down to just the person's name.
    private static func extractPersonName(from title: String) -> String {
        if let range = title.range(of: " on (LinkedIn|Instagram|Facebook)", options: [.regularExpression, .caseInsensitive]) {
            let candidate = String(title[title.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            if !candidate.isEmpty { return candidate }
        }

        let segments = title.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        if segments.count > 1 {
            let countPattern = #"^[\d,]+\+?\s*(comments?|likes?|reactions?|replies?|shares?)$"#
            let isNoise: (String) -> Bool = { segment in
                if segment.isEmpty { return true }
                let words = segment.split(separator: " ")
                if !words.isEmpty, words.allSatisfy({ $0.hasPrefix("#") }) { return true }
                if segment.range(of: countPattern, options: [.regularExpression, .caseInsensitive]) != nil { return true }
                return false
            }
            if let candidate = segments.first(where: { !isNoise($0) }) {
                return candidate
            }
        }

        return title
    }

    private static func fetchOGDescription(for url: URL) async -> String? {
        guard let html = await fetchHTML(for: url) else { return nil }
        guard let description = extractMetaContent(anyOf: [("property", "og:description")], from: html), !description.isEmpty else {
            return nil
        }
        return description
    }

    /// Best-effort across any site: tries the common "article publish date" meta tags in turn.
    /// Many hosts (product pages, booking sites, YouTube's own watch page) omit all of these,
    /// in which case this simply returns nil rather than guessing.
    private static func fetchPublishedDate(for url: URL) async -> Date? {
        guard let html = await fetchHTML(for: url) else { return nil }
        let candidates: [(String, String)] = [
            ("property", "article:published_time"),
            ("itemprop", "datePublished"),
            ("property", "og:updated_time"),
            ("name", "date"),
            ("name", "pubdate")
        ]
        guard let content = extractMetaContent(anyOf: candidates, from: html) else { return nil }
        return parseDate(content)
    }

    private static func fetchHTML(for url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.setValue(mobileSafariUserAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else {
            return nil
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    private static func extractMetaContent(anyOf candidates: [(attribute: String, value: String)], from html: String) -> String? {
        for (attribute, value) in candidates {
            let escapedAttr = NSRegularExpression.escapedPattern(for: attribute)
            let escapedValue = NSRegularExpression.escapedPattern(for: value)
            let patterns = [
                "<meta[^>]+\(escapedAttr)=[\"']\(escapedValue)[\"'][^>]+content=[\"']([^\"']*)[\"']",
                "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+\(escapedAttr)=[\"']\(escapedValue)[\"']"
            ]
            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range), let contentRange = Range(match.range(at: 1), in: html) {
                    let value = decodeHTML(String(html[contentRange]))
                    if !value.isEmpty { return value }
                }
            }
        }
        return nil
    }

    private static func parseDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: string) { return date }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        let simple = DateFormatter()
        simple.locale = Locale(identifier: "en_US_POSIX")
        simple.dateFormat = "yyyy-MM-dd"
        return simple.date(from: String(string.prefix(10)))
    }

    private static func decodeHTML(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func loadImageData(from itemProvider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image.compressedForStorage())
            }
        }
    }
}
