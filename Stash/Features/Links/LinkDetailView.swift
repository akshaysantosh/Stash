import SwiftUI
import SwiftData
import UIKit

struct LinkDetailView: View {
    @Bindable var link: SavedLink
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingDeleteConfirm = false
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                Button(action: openLink) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let data = link.imageData, let uiImage = UIImage(data: data) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 320)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                openIndicator
                                    .padding(10)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppMetrics.cardRadius)
                                    .stroke(Color.borderCard, lineWidth: 1)
                            )
                        }

                        CardView {
                            HStack {
                                Chip(text: link.category.displayName)
                                Spacer()
                                if link.isDone {
                                    Chip(text: "Checked out", style: .success)
                                }
                            }
                            Text(link.title)
                                .font(AppFont.cardHeadline())
                                .foregroundStyle(Color.ink)
                                .padding(.top, 6)
                            HStack(spacing: 4) {
                                if let publishedAt = link.publishedAt {
                                    Text(publishedAt.formatted(date: .abbreviated, time: .omitted))
                                    Text("·")
                                }
                                Text(link.displayHost)
                            }
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textFaint)
                            .padding(.top, 8)

                            if !link.tags.isEmpty {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 6)], alignment: .leading, spacing: 6) {
                                    ForEach(link.tags, id: \.self) { tag in
                                        Chip(text: tag)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                if !link.snippet.isEmpty {
                    SectionLabel(text: "Post preview")
                    CardView {
                        Text(link.snippet)
                            .font(AppFont.body())
                            .foregroundStyle(Color.bodyText)
                    }
                }

                if !link.note.isEmpty {
                    SectionLabel(text: "Note")
                    CardView {
                        Text(link.note)
                            .font(AppFont.body())
                            .foregroundStyle(Color.bodyText)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    link.isDone.toggle()
                } label: {
                    Image(systemName: link.isDone ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(Color.accentSuccess)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditLinkView(link: link)
        }
        .confirmationDialog("Delete this link?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(link)
                dismiss()
            }
        }
    }

    private var openIndicator: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.ink)
            .padding(8)
            .background(Circle().fill(Color.bgCard.opacity(0.9)))
    }

    private func openLink() {
        if let url = URL(string: link.url) {
            openURL(url)
        }
    }
}
