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

    private var meta: String {
        var parts = [link.category.displayName, link.displayHost]
        if let publishedAt = link.publishedAt {
            parts.append(publishedAt.formatted(date: .abbreviated, time: .omitted))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                if let data = link.imageData, let uiImage = UIImage(data: data) {
                    Button(action: openLink) {
                        Color.clear
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .overlay(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: AppSpacing.s) {
                    Text(link.title.isEmpty ? link.displayHost : link.title)
                        .font(AppFont.detailTitle())
                        .foregroundStyle(Color.ink)
                    Text(meta)
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                    if link.isDone {
                        Label("In the Vault", systemImage: "archivebox")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textMuted)
                    }
                }

                if !link.tags.isEmpty {
                    FlowLayout(horizontalSpacing: AppSpacing.s - 2, verticalSpacing: AppSpacing.s - 2) {
                        ForEach(link.tags, id: \.self) { tag in
                            Chip(text: tag.asTag)
                        }
                    }
                }

                Button(action: openLink) {
                    Label("Open link", systemImage: "arrow.up.right")
                }
                .buttonStyle(.solidAccent)

                if !link.snippet.isEmpty {
                    textSection("About", text: link.snippet)
                }
                if !link.note.isEmpty {
                    textSection("Your note", text: link.note)
                }
            }
            .padding(AppSpacing.l)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        link.isDone.toggle()
                    } label: {
                        Label(link.isDone ? "Move back to Stash" : "Mark done",
                              systemImage: link.isDone ? "arrow.uturn.left" : "checkmark.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.ink)
                }
                .accessibilityLabel("More actions")
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

    private func textSection(_ label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            SectionLabel(text: label)
            Text(text)
                .font(AppFont.body())
                .foregroundStyle(Color.bodyText)
        }
    }

    private func openLink() {
        if let url = URL(string: link.url) {
            openURL(url)
        }
    }
}
