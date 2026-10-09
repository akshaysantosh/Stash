import SwiftUI
import UIKit

/// A flat, calm row: thumbnail, title, one meta line, and (optionally) a muted tag line.
/// Category shows only as a small symbol on the meta line — and only when the list isn't
/// already filtered to one category.
struct LinkRow: View {
    let link: SavedLink
    var showsCategory = true
    /// Marks a pinned link when it's shown in the regular list (not inside the Up next section).
    var showsPin = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static let thumbSize: CGFloat = 76

    private var meta: String {
        guard let publishedAt = link.publishedAt else { return link.displayHost }
        return "\(link.displayHost) · \(publishedAt.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var tagLine: String? {
        guard !link.tags.isEmpty else { return nil }
        let shown = link.tags.prefix(2).map(\.asTag).joined(separator: "  ")
        let extra = link.tags.count - 2
        return extra > 0 ? "\(shown)  +\(extra)" : shown
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Large text: stack the thumbnail above the text so the title gets the full width.
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                thumbnail
                textBlock
            }
        } else {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                thumbnail
                textBlock
                Spacer(minLength: 0)
            }
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(link.title.isEmpty ? link.displayHost : link.title)
                .font(AppFont.rowTitle())
                .foregroundStyle(Color.ink)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            HStack(spacing: AppSpacing.xs) {
                if showsPin {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accent)
                }
                if showsCategory {
                    Image(systemName: link.category.symbolName)
                        .font(.caption2)
                }
                Text(meta)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .font(AppFont.caption())
            .foregroundStyle(Color.textSecondary)
            if let tagLine {
                Text(tagLine)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = link.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Self.thumbSize, height: Self.thumbSize)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.thumb))
        } else {
            RoundedRectangle(cornerRadius: AppRadius.thumb)
                .fill(Color.chipBg)
                .frame(width: Self.thumbSize, height: Self.thumbSize)
                .overlay(
                    Image(systemName: link.category.symbolName)
                        .font(.title3)
                        .foregroundStyle(Color.textMuted)
                )
        }
    }
}
