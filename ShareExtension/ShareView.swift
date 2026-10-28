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
    @State private var addToUpNext = false
    @State private var didSave = false
    /// How long the "Stashed" celebration shows before the extension closes (longer in debug builds).
    private var celebrationSeconds: Double {
        #if DEBUG
        4.0   // debug builds linger so the animation can be inspected; release closes after 1s
        #else
        1.0
        #endif
    }

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
                            .disabled(sharedURL == nil || isFetchingMetadata || didSave)
                    }
                }
        }
        .overlay {
            if didSave {
                ZStack {
                    PaperBackground()
                    VStack(spacing: AppSpacing.l) {
                        SavedBurst()
                        Text(addToUpNext ? "Stashed and pinned" : "Stashed")
                            .font(AppFont.cardHeadline())
                            .foregroundStyle(Color.ink)
                    }
                }
                .transition(.opacity)
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

                    CardView {
                        Toggle(isOn: $addToUpNext) {
                            Label("Add to Up next", systemImage: "pin")
                                .font(AppFont.body())
                                .foregroundStyle(Color.bodyText)
                        }
                        .tint(Color.accent)
                        Text("Pin it to the top of The Stash (up to \(UpNext.limit)).")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textMuted)
                    }

                    if let saveError {
                        CalloutBanner(text: saveError, style: .warn)
                    }
                }
                .padding(16)
            }
            .background(PaperBackground())
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
        .background(PaperBackground())
    }

    /// Finds the link in whatever the host app shared. Apps differ a lot: Safari hands over a typed
    /// URL, YouTube/Instagram/Spotify often share plain text with a link in it, Messages and Notes
    /// share text, and some put the link only in the item's attributed text or title. Try each in
    /// turn and return the first real web link.
    private func extractURL() async -> URL? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }

        // 1. Properly typed URL attachments.
        for item in items {
            for attachment in item.attachments ?? [] where attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                if let url = await webURL(from: await loadValue(from: attachment, type: UTType.url)) { return url }
            }
        }
        // 2. Text attachments (plain text, UTF-8/16 text, rich text...) with a link inside.
        for item in items {
            for attachment in item.attachments ?? [] where attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                if let url = await webURL(from: await loadValue(from: attachment, type: UTType.text)) { return url }
            }
        }
        // 3. The item's own text/title, for apps that attach nothing usable.
        for item in items {
            for text in [item.attributedContentText?.string, item.attributedTitle?.string] {
                if let text, let url = firstWebURL(in: text) { return url }
            }
        }
        return nil
    }

    private func loadValue(from attachment: NSItemProvider, type: UTType) async -> Any? {
        await withCheckedContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: type.identifier, options: nil) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    /// Turns whatever `loadItem` returned (a URL, NSURL, String, Data, attributed text) into a web link.
    private func webURL(from value: Any?) async -> URL? {
        switch value {
        case let url as URL:
            return isWeb(url) ? url : nil
        case let string as String:
            return firstWebURL(in: string)
        case let attributed as NSAttributedString:
            return firstWebURL(in: attributed.string)
        case let data as Data:
            if let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) {
                return firstWebURL(in: string)
            }
            return nil
        default:
            return nil
        }
    }

    private func isWeb(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased()
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    private func firstWebURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = URL(string: trimmed), isWeb(direct) { return direct }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).compactMap(\.url).first(where: isWeb)
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
            if addToUpNext {
                let descriptor = FetchDescriptor<SavedLink>(predicate: #Predicate { $0.upNextAt != nil && $0.isDone == false })
                UpNext.toggle(link, pinned: (try? context.fetch(descriptor)) ?? [])
            }
            try context.save()
            // A little celebration, then close.
            Haptics.added()
            withAnimation(.easeOut(duration: 0.2)) { didSave = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + celebrationSeconds) { onFinish() }
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
