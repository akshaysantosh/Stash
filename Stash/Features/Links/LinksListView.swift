import SwiftUI
import SwiftData

struct LinksListView: View {
    let title: String
    private let isDone: Bool
    @Query private var links: [SavedLink]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("sortOldestFirst") private var sortOldestFirst = false
    @State private var showingAddLink = false
    @State private var selectedCategory: Category?
    @State private var selectedTag: String?
    @State private var searchText = ""
    @State private var surprise: SurpriseRequest?

    init(isDone: Bool, title: String) {
        self.title = title
        self.isDone = isDone
        _links = Query(filter: #Predicate<SavedLink> { $0.isDone == isDone }, sort: \SavedLink.addedAt, order: .reverse)
    }

    private struct SurpriseRequest: Identifiable {
        let tag: String
        var id: String { tag }
    }

    // MARK: Derived data

    private var allTags: [String] {
        Set(links.flatMap(\.tags)).sorted()
    }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var filteredLinks: [SavedLink] {
        var result = sortOldestFirst ? Array(links.reversed()) : links
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if let selectedTag {
            result = result.filter { $0.tags.contains(selectedTag) }
        }
        if !query.isEmpty {
            result = result.filter { matches($0, query) }
        }
        return result
    }

    private func matches(_ link: SavedLink, _ text: String) -> Bool {
        link.title.localizedStandardContains(text)
            || link.displayHost.localizedStandardContains(text)
            || link.note.localizedStandardContains(text)
            || link.snippet.localizedStandardContains(text)
            || link.tags.contains { $0.localizedStandardContains(text) }
    }

    /// Pinned links, in the order they were pinned (oldest pin first).
    private var pinned: [SavedLink] {
        links.filter(\.isUpNext).sorted { ($0.upNextAt ?? .distantPast) < ($1.upNextAt ?? .distantPast) }
    }

    private var isFiltering: Bool { selectedCategory != nil || selectedTag != nil || !query.isEmpty }

    /// Up next only leads the list when you're looking at everything — as soon as you filter or
    /// search, pinned links join the normal results (marked with a pin) so nothing is hidden.
    private var showsUpNext: Bool { !isDone && !isFiltering && !pinned.isEmpty }

    private var mainLinks: [SavedLink] {
        showsUpNext ? filteredLinks.filter { !$0.isUpNext } : filteredLinks
    }

    private var countText: String {
        isFiltering ? "\(filteredLinks.count) of \(links.count)" : "\(links.count) saved"
    }

    private var emptyMessage: String {
        if !query.isEmpty { return "No matches for “\(query)”." }
        if let selectedTag {
            if let selectedCategory {
                return "Nothing tagged \(selectedTag.asTag) in \(selectedCategory.displayName) yet."
            }
            return "Nothing tagged \(selectedTag.asTag) yet."
        }
        if let selectedCategory {
            return "Nothing in \(selectedCategory.displayName) yet."
        }
        return isDone
            ? "Your Vault is empty. Mark a link as done to keep it here."
            : "Nothing saved yet. Add a podcast, video, restaurant, or anything else worth coming back to."
    }

    private var emptyIcon: String {
        if !query.isEmpty { return "magnifyingglass" }
        if let selectedCategory { return selectedCategory.symbolName }
        return isDone ? "archivebox" : "bookmark"
    }

    private var showsAddInEmptyState: Bool { !isDone && !isFiltering }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))

                if showsUpNext {
                    sectionLabel("Up next · \(pinned.count) of \(UpNext.limit)")
                    ForEach(pinned) { link in
                        row(for: link, showsPin: false)
                    }
                    if !mainLinks.isEmpty {
                        sectionLabel("Everything else")
                    }
                }

                if filteredLinks.isEmpty {
                    EmptyStateView(symbolName: emptyIcon, message: emptyMessage, actionTitle: showsAddInEmptyState ? "Add a link" : nil) {
                        showingAddLink = true
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(mainLinks) { link in
                        row(for: link, showsPin: link.isUpNext)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, isDone ? AppSpacing.l : 88, for: .scrollContent)

            if !isDone {
                FloatingAddButton { showingAddLink = true }
                    .padding(.trailing, AppSpacing.l + AppSpacing.xs)
                    .padding(.bottom, AppSpacing.l)
            }
        }
        .background(Color.bgPage)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search saved links")
        .toolbar {
            if !allTags.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { tagMenu }
            }
        }
        .sheet(isPresented: $showingAddLink) {
            AddLinkView()
        }
        .sheet(item: $surprise) { request in
            SurpriseMeView(tag: request.tag)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            TypePicker(selection: $selectedCategory)

            // At accessibility text sizes the count, sort menu and tag pill can't share a line.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.s))
                : AnyLayout(HStackLayout(spacing: AppSpacing.s))
            layout {
                HStack(spacing: AppSpacing.s) {
                    Text(countText)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textMuted)
                    sortMenu
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                if let selectedTag {
                    activeTag(selectedTag)
                }
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Button {
                sortOldestFirst = false
            } label: {
                if sortOldestFirst { Text("Newest first") } else { Label("Newest first", systemImage: "checkmark") }
            }
            Button {
                sortOldestFirst = true
            } label: {
                if sortOldestFirst { Label("Oldest first", systemImage: "checkmark") } else { Text("Oldest first") }
            }
        } label: {
            HStack(spacing: 3) {
                Text("·")
                Text(sortOldestFirst ? "Oldest first" : "Newest first")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(AppFont.caption())
            .foregroundStyle(Color.textMuted)
        }
        .accessibilityLabel("Sort order")
    }

    /// The active tag pill, with a dice beside it for "Surprise me from this tag" — only shown
    /// once you're already looking at a tag (and only for links you haven't finished).
    private func activeTag(_ tag: String) -> some View {
        HStack(spacing: AppSpacing.s) {
            if !isDone {
                Button {
                    surprise = SurpriseRequest(tag: tag)
                } label: {
                    Image(systemName: "dice")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.chipAltBg))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Surprise me from \(tag.asTag)")
            }
            Button {
                withAnimation(.snappy) { selectedTag = nil }
            } label: {
                Chip(text: tag.asTag, style: .selected, showsRemove: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear tag filter \(tag)")
        }
    }

    private var tagMenu: some View {
        Menu {
            if selectedTag != nil {
                Button("Show all tags") { selectedTag = nil }
                Divider()
            }
            ForEach(allTags, id: \.self) { tag in
                Button {
                    selectedTag = tag
                } label: {
                    if selectedTag == tag {
                        Label(tag.asTag, systemImage: "checkmark")
                    } else {
                        Text(tag.asTag)
                    }
                }
            }
        } label: {
            Image(systemName: selectedTag == nil ? "tag" : "tag.fill")
                .foregroundStyle(selectedTag == nil ? Color.ink : Color.accent)
        }
        .accessibilityLabel("Filter by tag")
    }

    private func sectionLabel(_ text: String) -> some View {
        SectionLabel(text: text)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.xs, trailing: AppSpacing.l))
    }

    // MARK: Rows

    private func row(for link: SavedLink, showsPin: Bool) -> some View {
        ZStack {
            LinkRow(link: link, showsCategory: selectedCategory == nil, showsPin: showsPin)
            // A hidden link overlay keeps the row tappable without the system disclosure chevron.
            NavigationLink {
                LinkDetailView(link: link)
            } label: { EmptyView() }
            .opacity(0)
        }
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(Color.borderCard)
        .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            dynamicTypeSize.isAccessibilitySize ? AppSpacing.l : AppSpacing.l + LinkRow.thumbSize + AppSpacing.m
        }
        .swipeActions(edge: .leading) {
            Button {
                link.toggleDone()
            } label: {
                Label(link.isDone ? "Reopen" : "Done", systemImage: link.isDone ? "arrow.uturn.left" : "checkmark")
            }
            .tint(Color.accentSuccess)
            if !link.isDone {
                Button {
                    UpNext.toggle(link, pinned: pinned)
                } label: {
                    Label(link.isUpNext ? "Unpin" : "Up next", systemImage: link.isUpNext ? "pin.slash" : "pin")
                }
                .tint(Color.accent)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(link)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            if !link.isDone {
                Button {
                    UpNext.toggle(link, pinned: pinned)
                } label: {
                    Label(link.isUpNext ? "Remove from Up next" : "Add to Up next",
                          systemImage: link.isUpNext ? "pin.slash" : "pin")
                }
            }
            Button {
                link.toggleDone()
            } label: {
                Label(link.isDone ? "Reopen" : "Mark done", systemImage: link.isDone ? "arrow.uturn.left" : "checkmark")
            }
            Button(role: .destructive) {
                modelContext.delete(link)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct EmptyStateView: View {
    let symbolName: String
    let message: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: symbolName)
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Color.textMuted)
            Text(message)
                .font(AppFont.secondaryDetail())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.horizontal, AppSpacing.xxl + AppSpacing.l)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl + AppSpacing.l)
    }
}
