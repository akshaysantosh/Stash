import SwiftData
import SwiftUI
import UIKit

/// Shown when the daily recall notification is tapped. Picks a genuinely random match at open
/// time (and again on "Show Another") rather than showing whatever the notification was
/// scheduled with, so it's always fresh.
struct DailyRecallView: View {
    let tag: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query private var links: [SavedLink]
    @State private var current: SavedLink?

    private var matches: [SavedLink] {
        links.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                if let current {
                    Chip(text: "#\(tag)", style: .alt)

                    if let data = current.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                    }

                    CardView {
                        Text(current.title)
                            .font(AppFont.cardHeadline())
                            .foregroundStyle(Color.ink)
                        Text(current.displayHost)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textFaint)
                            .padding(.top, 4)
                    }

                    if !current.snippet.isEmpty {
                        CardView {
                            Text(current.snippet)
                                .font(AppFont.body())
                                .foregroundStyle(Color.bodyText)
                        }
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button("Show Another") { pickRandom() }
                            .buttonStyle(.primary(.textMuted))
                            .disabled(matches.count < 2)
                        Button("Open") {
                            if let url = URL(string: current.url) { openURL(url) }
                        }
                        .buttonStyle(.primary)
                    }
                } else {
                    CalloutBanner(text: "Nothing tagged #\(tag) anymore.")
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.bgPage)
            .navigationTitle("Daily Recall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { pickRandom() }
    }

    private func pickRandom() {
        current = matches.randomElement()
    }
}
