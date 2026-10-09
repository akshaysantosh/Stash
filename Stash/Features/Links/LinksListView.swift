import SwiftUI
import SwiftData

struct LinksListView: View {
    let title: String
    private let isDone: Bool
    @Query private var links: [SavedLink]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddLink = false
    @State private var showingSettings = false
    @State private var selectedCategory: Category?
    @State private var selectedTag: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(isDone: Bool, title: String) {
        self.title = title
        self.isDone = isDone
        _links = Query(filter: #Predicate<SavedLink> { $0.isDone == isDone }, sort: \SavedLink.addedAt, order: .reverse)
    }

    private var allTags: [String] {
        Set(links.flatMap(\.tags)).sorted()
    }

    private var filteredLinks: [SavedLink] {
        var result = links
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if let selectedTag {
            result = result.filter { $0.tags.contains(selectedTag) }
        }
        return result
    }

    private var isFiltering: Bool { selectedCategory != nil || selectedTag != nil }

    private var countText: String {
        isFiltering ? "\(filteredLinks.count) of \(links.count)" : "\(links.count) saved"
    }

    private var emptyMessage: String {
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
        if let selectedCategory { return selectedCategory.symbolName }
        return isDone ? "archivebox" : "bookmark"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))

                if filteredLinks.isEmpty {
                    EmptyStateView(symbolName: emptyIcon, message: emptyMessage, actionTitle: showsAddInEmptyState ? "Add a link" : nil) {
                        showingAddLink = true
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredLinks) { link in
                        row(for: link)
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.ink)
                }
                .accessibilityLabel("Daily recall settings")
            }
            if !allTags.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { tagMenu }
            }
        }
        .sheet(isPresented: $showingAddLink) {
            AddLinkView()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
                .presentationDetents([.medium, .large])
        }
    }

    private var showsAddInEmptyState: Bool { !isDone && !isFiltering }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            TypePicker(selection: $selectedCategory)

            HStack(spacing: AppSpacing.s) {
                Text(countText)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
                Spacer()
                if let selectedTag {
                    Button {
                        withAnimation(.snappy) { self.selectedTag = nil }
                    } label: {
                        Chip(text: selectedTag.asTag, style: .selected, showsRemove: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear tag filter \(selectedTag)")
                }
            }
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

    private func row(for link: SavedLink) -> some View {
        ZStack {
            LinkRow(link: link, showsCategory: selectedCategory == nil)
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
                link.isDone.toggle()
            } label: {
                Label(link.isDone ? "Reopen" : "Done", systemImage: link.isDone ? "arrow.uturn.left" : "checkmark")
            }
            .tint(Color.accentSuccess)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(link)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                link.isDone.toggle()
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
