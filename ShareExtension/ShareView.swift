import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct ShareView: View {
    let extensionContext: NSExtensionContext?
    let onFinish: () -> Void
    let onCancel: () -> Void

    @State private var sharedURL: URL?
    @State private var isLoadingURL = true
    @State private var isFetchingMetadata = false
    @State private var fetchedTitle = ""
    @State private var fetchedImageData: Data?
    @State private var fetchedSnippet: String?
    @State private var fetchedDate: Date?
    @State private var category: Category = .other
    @State private var availableTags: [String] = []
    @State private var selectedTags: [String] = []
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Save to Stash")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save)
                            .disabled(sharedURL == nil || isFetchingMetadata)
                    }
                }
        }
        .task {
            loadAvailableTags()
            sharedURL = await extractURL()
            isLoadingURL = false
            if let sharedURL {
                await fetchMetadata(for: sharedURL)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoadingURL || isFetchingMetadata {
            statusView(isLoadingURL ? "Reading link…" : "Fetching preview…", showsSpinner: true)
        } else if sharedURL == nil {
            statusView("Couldn't find a link to save from this share.", showsSpinner: false)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                    CardView {
                        if let fetchedImageData, let uiImage = UIImage(data: fetchedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                        }
                        Text(fetchedTitle.isEmpty ? (sharedURL?.absoluteString ?? "") : fetchedTitle)
                            .font(AppFont.cardHeadline())
                            .foregroundStyle(Color.ink)
                            .padding(.top, 6)
                        if let fetchedSnippet, !fetchedSnippet.isEmpty {
                            Text(fetchedSnippet)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(4)
                                .padding(.top, 4)
                        }
                    }

                    CardView {
                        HStack {
                            Text("Category")
                                .font(AppFont.body())
                                .foregroundStyle(Color.bodyText)
                            Spacer()
                            Picker("Category", selection: $category) {
                                ForEach(Category.allCases) { c in
                                    Label(c.displayName, systemImage: c.symbolName).tag(c)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.accent)
                        }
                    }

                    CardView {
                        Text("Tags")
                            .font(AppFont.body())
                            .foregroundStyle(Color.bodyText)
                        TagDropdownField(availableTags: availableTags, selectedTags: $selectedTags)
                            .padding(.top, 4)
                    }

                    if let saveError {
                        CalloutBanner(text: saveError, style: .warn)
                    }
                }
                .padding(16)
            }
            .background(Color.bgPage)
        }
    }

    private func statusView(_ message: String, showsSpinner: Bool) -> some View {
        VStack(spacing: 12) {
            if showsSpinner {
                ProgressView()
            }
            Text(message)
                .font(AppFont.secondaryDetail())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPage)
    }

    private func extractURL() async -> URL? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }

        for item in items {
            guard let attachments = item.attachments else { continue }

            // Safari and most apps hand over a properly-typed URL attachment.
            for attachment in attachments where attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                if let url = await loadURL(from: attachment) { return url }
            }

            // Some apps (YouTube among them) share plain text with a link embedded in it instead.
            for attachment in attachments where attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                if let text = await loadText(from: attachment), let url = firstURL(in: text) { return url }
            }
        }
        return nil
    }

    private func loadURL(from attachment: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                continuation.resume(returning: data as? URL)
            }
        }
    }

    private func loadText(from attachment: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                continuation.resume(returning: data as? String)
            }
        }
    }

    private func firstURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, range: range)?.url
    }

    private func fetchMetadata(for url: URL) async {
        isFetchingMetadata = true
        if let result = try? await LinkMetadataService.fetch(for: url.absoluteString) {
            fetchedTitle = result.title ?? ""
            fetchedImageData = result.imageData
            fetchedSnippet = result.snippet
            fetchedDate = result.publishedDate
        }
        category = Category.guess(for: url)
        isFetchingMetadata = false
    }

    /// Both saving and loading tag suggestions need a context onto the shared App Group store —
    /// this is created fresh each time rather than held in state, since the extension's process
    /// is short-lived and there's no other view that needs a long-lived container.
    private func makeSharedContext() throws -> ModelContext? {
        guard let groupURL = AppGroup.containerURL else { return nil }
        let schema = Schema([SavedLink.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: groupURL.appendingPathComponent("Stash.sqlite"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func loadAvailableTags() {
        guard let context = try? makeSharedContext() else { return }
        guard let links = try? context.fetch(FetchDescriptor<SavedLink>()) else { return }
        availableTags = Set(links.flatMap(\.tags)).sorted()
    }

    private func save() {
        guard let sharedURL else { return }
        do {
            guard let context = try makeSharedContext() else {
                saveError = "Couldn't reach Stash's shared storage — the App Group isn't set up correctly."
                return
            }
            let link = SavedLink(
                url: sharedURL.absoluteString,
                title: fetchedTitle.isEmpty ? sharedURL.absoluteString : fetchedTitle,
                imageData: fetchedImageData,
                category: category,
                snippet: fetchedSnippet ?? "",
                publishedAt: fetchedDate,
                tags: selectedTags
            )
            context.insert(link)
            try context.save()
            onFinish()
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
