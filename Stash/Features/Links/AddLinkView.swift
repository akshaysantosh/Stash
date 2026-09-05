import SwiftUI
import SwiftData
import UIKit

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var isFetching = false
    @State private var fetchError: String?
    @State private var fetchedTitle = ""
    @State private var fetchedImageData: Data?
    @State private var fetchedSnippet: String?
    @State private var fetchedDate: Date?
    @State private var hasFetched = false
    @State private var category: Category = .other
    @State private var note = ""

    private var canSave: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasFetched
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link") {
                    HStack {
                        TextField("Paste a URL", text: $urlText)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: urlText) { hasFetched = false }
                        Button {
                            if let clipboardString = UIPasteboard.general.string {
                                urlText = clipboardString
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }

                    Button {
                        Task { await fetchMetadata() }
                    } label: {
                        if isFetching {
                            ProgressView()
                        } else {
                            Text("Fetch Preview")
                        }
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetching)

                    if let fetchError {
                        Text(fetchError)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.calloutWarnText)
                    }
                }

                if hasFetched {
                    Section("Preview") {
                        if let fetchedImageData, let uiImage = UIImage(data: fetchedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                        }
                        TextField("Title", text: $fetchedTitle)
                        if let fetchedSnippet, !fetchedSnippet.isEmpty {
                            Text(fetchedSnippet)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(4)
                        }
                    }

                    Section("Details") {
                        Picker("Category", selection: $category) {
                            ForEach(Category.allCases) { c in
                                Label(c.displayName, systemImage: c.symbolName).tag(c)
                            }
                        }
                        TextField("Note (optional)", text: $note, axis: .vertical)
                    }
                }
            }
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func fetchMetadata() async {
        isFetching = true
        fetchError = nil
        do {
            let result = try await LinkMetadataService.fetch(for: urlText)
            fetchedTitle = result.title ?? ""
            fetchedImageData = result.imageData
            fetchedSnippet = result.snippet
            fetchedDate = result.publishedDate
            if let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                category = Category.guess(for: url)
            }
            hasFetched = true
        } catch {
            fetchError = error.localizedDescription
        }
        isFetching = false
    }

    private func save() {
        let link = SavedLink(
            url: urlText.trimmingCharacters(in: .whitespacesAndNewlines),
            title: fetchedTitle.isEmpty ? urlText : fetchedTitle,
            imageData: fetchedImageData,
            category: category,
            note: note,
            snippet: fetchedSnippet ?? "",
            publishedAt: fetchedDate
        )
        modelContext.insert(link)
        dismiss()
    }
}
