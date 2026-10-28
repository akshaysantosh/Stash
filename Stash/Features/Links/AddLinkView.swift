import SwiftUI
import SwiftData
import UIKit

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toasts: ToastCenter
    @Query private var allLinks: [SavedLink]
    @Query(filter: #Predicate<SavedLink> { $0.upNextAt != nil && $0.isDone == false }) private var pinned: [SavedLink]

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
    @State private var selectedTags: [String] = []
    @State private var addToUpNext = false
    @FocusState private var urlFocused: Bool

    private var availableTags: [String] {
        Set(allLinks.flatMap(\.tags)).sorted()
    }

    private var trimmedURL: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Only http(s) links with a host count — this gates auto-fetch and saving.
    private var hasValidURL: Bool {
        guard let url = URL(string: trimmedURL), let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    /// Saving doesn't wait for a preview to succeed — a link with no title is still worth keeping
    /// (it falls back to the address) — it only waits while a fetch is in flight.
    private var canSave: Bool { hasValidURL && !isFetching }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link") {
                    HStack(spacing: AppSpacing.s) {
                        TextField("Paste a URL", text: $urlText)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($urlFocused)
                        if isFetching {
                            ProgressView()
                        }
                        // PasteButton pastes without iOS's "Allow Paste" prompt.
                        PasteButton(payloadType: String.self) { strings in
                            if let text = strings.first { urlText = text }
                        }
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.capsule)
                        .tint(Color.accent)
                    }

                    if let fetchError {
                        HStack(alignment: .firstTextBaseline) {
                            Text(fetchError)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.calloutWarnText)
                            Spacer()
                            Button("Try again") { Task { await fetchMetadata() } }
                                .font(AppFont.caption())
                        }
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
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                        }
                        TextField("Title", text: $fetchedTitle)
                        if let fetchedSnippet, !fetchedSnippet.isEmpty {
                            Text(fetchedSnippet)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(4)
                        }
                    }
                }

                if hasValidURL {
                    Section("Details") {
                        Picker("Category", selection: $category) {
                            ForEach(Category.allCases) { c in
                                Label(c.displayName, systemImage: c.symbolName).tag(c)
                            }
                        }
                        TextField("Note (optional)", text: $note, axis: .vertical)
                    }

                    Section {
                        Toggle(isOn: $addToUpNext) {
                            Label("Add to Up next", systemImage: "pin")
                        }
                        .tint(Color.accent)
                    } footer: {
                        if addToUpNext && pinned.count >= UpNext.limit {
                            Text("Up next is full — this replaces the oldest pin.")
                        } else {
                            Text("Pin it to the top of The Stash (up to \(UpNext.limit)).")
                        }
                    }

                    Section("Tags") {
                        TagDropdownField(availableTags: availableTags, selectedTags: $selectedTags)
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
            // Fetch the preview automatically as soon as the text becomes a valid link. `.task(id:)`
            // cancels the previous run whenever the text changes, so typing or pasting settles
            // before anything is fetched and a stale fetch can never overwrite a newer one.
            .task(id: urlText) { await autoFetch() }
            .onAppear { urlFocused = true }
        }
    }

    private func autoFetch() async {
        hasFetched = false
        fetchError = nil
        fetchedTitle = ""
        fetchedImageData = nil
        fetchedSnippet = nil
        fetchedDate = nil
        isFetching = false
        guard hasValidURL, let url = URL(string: trimmedURL) else { return }

        category = Category.guess(for: url)
        isFetching = true
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await fetchMetadata()
    }

    private func fetchMetadata() async {
        let requested = trimmedURL
        isFetching = true
        fetchError = nil
        do {
            let result = try await LinkMetadataService.fetch(for: requested)
            guard !Task.isCancelled, requested == trimmedURL else { return }
            fetchedTitle = result.title ?? ""
            fetchedImageData = result.imageData
            fetchedSnippet = result.snippet
            fetchedDate = result.publishedDate
            hasFetched = true
        } catch {
            guard !Task.isCancelled, requested == trimmedURL else { return }
            fetchError = "Couldn't load a preview — you can still save the link."
        }
        isFetching = false
    }

    private func save() {
        let link = SavedLink(
            url: trimmedURL,
            title: fetchedTitle.isEmpty ? trimmedURL : fetchedTitle,
            imageData: fetchedImageData,
            category: category,
            note: note,
            snippet: fetchedSnippet ?? "",
            publishedAt: fetchedDate,
            tags: selectedTags
        )
        modelContext.insert(link)
        if addToUpNext {
            UpNext.toggle(link, pinned: pinned)
        }
        // Feedback: a success haptic now, then — once the sheet has finished closing — the toast and
        // a glow on the new row.
        Haptics.added()
        toasts.show(Toast(kind: .added, message: addToUpNext ? "Stashed and pinned" : "Stashed"), after: 0.45)
        toasts.highlight(link.id, after: 0.45)
        dismiss()
    }
}
