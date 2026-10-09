import SwiftData
import SwiftUI
import UIKit

/// "Surprise me from #tag": a random unfinished link under one tag. Picked fresh each time (and
/// again on "Show another"), so it never repeats the link you're already looking at.
struct SurpriseMeView: View {
    let tag: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(filter: #Predicate<SavedLink> { $0.isDone == false }) private var unfinished: [SavedLink]
    @Query(filter: #Predicate<SavedLink> { $0.upNextAt != nil && $0.isDone == false }) private var pinned: [SavedLink]
    @State private var current: SavedLink?

    private var pool: [SavedLink] {
        unfinished.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                if let current {
                    card(for: current)
                } else {
                    CalloutBanner(text: "Nothing unfinished tagged \(tag.asTag).")
                    Spacer()
                }
            }
            .padding(AppSpacing.l)
            .background(Color.bgPage)
            .navigationTitle(tag.asTag)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { pickRandom() }
    }

    private func card(for link: SavedLink) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            if let data = link.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(link.title.isEmpty ? link.displayHost : link.title)
                    .font(AppFont.detailTitle())
                    .foregroundStyle(Color.ink)
                Text("\(link.category.displayName) · \(link.displayHost)")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.m) {
                HStack(spacing: AppSpacing.m) {
                    Button("Show another") { pickRandom() }
                        .buttonStyle(.primary)
                        .disabled(pool.count < 2)
                    Button("Open") {
                        if let url = URL(string: link.url) { openURL(url) }
                    }
                    .buttonStyle(.solidAccent)
                }
                Button {
                    UpNext.toggle(link, pinned: pinned)
                } label: {
                    Label(link.isUpNext ? "In Up next" : "Add to Up next",
                          systemImage: link.isUpNext ? "pin.fill" : "pin")
                        .font(AppFont.secondaryDetail().weight(.semibold))
                        .foregroundStyle(link.isUpNext ? Color.textMuted : Color.accent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func pickRandom() {
        let others = pool.filter { $0.id != current?.id }
        current = others.randomElement() ?? pool.randomElement()
    }
}
