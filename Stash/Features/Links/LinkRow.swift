import SwiftUI
import UIKit

struct LinkRow: View {
    let link: SavedLink

    private var meta: String {
        guard let publishedAt = link.publishedAt else { return link.displayHost }
        return "\(publishedAt.formatted(.dateTime.month(.abbreviated).day())) · \(link.displayHost)"
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(link.category.accentColor)
                .frame(width: 3)
                .padding(.vertical, 8)

            thumbnail

            VStack(alignment: .leading, spacing: 3) {
                Text(link.title.isEmpty ? link.displayHost : link.title)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                Text(meta)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                if !link.snippet.isEmpty {
                    Text(link.snippet)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = link.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.chipBg)
                .frame(width: 68, height: 68)
                .overlay(
                    Image(systemName: link.category.symbolName)
                        .font(.system(size: 20))
                        .foregroundStyle(link.category.accentColor)
                )
        }
    }
}
