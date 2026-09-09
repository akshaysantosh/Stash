import SwiftUI
import SwiftData

struct LinksListView: View {
    let title: String
    private let isDone: Bool
    @Query private var links: [SavedLink]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddLink = false
    @State private var selectedCategory: Category?
    @State private var selectedTag: String?

    init(isDone: Bool, title: String) {
        self.title = title
        self.isDone = isDone
        _links = Query(filter: #Predicate<SavedLink> { $0.isDone == isDone }, sort: \SavedLink.addedAt, order: .reverse)
    }

    private enum Row: Identifiable {
        case header(Category)
        case link(SavedLink)

        var id: String {
            switch self {
            case .header(let category): return "header-\(category.rawValue)"
            case .link(let link): return "link-\(link.id)"
            }
        }
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

    private var rows: [Row] {
        guard selectedCategory == nil else {
            return filteredLinks.map { .link($0) }
        }
        let grouped = Dictionary(grouping: filteredLinks, by: { $0.category })
        var result: [Row] = []
        for category in Category.allCases {
            guard let items = grouped[category], !items.isEmpty else { continue }
            result.append(.header(category))
            result.append(contentsOf: items.map { .link($0) })
        }
        return result
    }

    private var emptyMessage: String {
        if let selectedTag {
            if let selectedCategory {
                return "Nothing tagged #\(selectedTag) in \(selectedCategory.displayName) yet."
            }
            return "Nothing tagged #\(selectedTag) yet."
        }
        if let selectedCategory {
            return "Nothing in \(selectedCategory.displayName) yet."
        }
        return isDone
            ? "Nothing checked off yet. Mark a link done from The Stash once you've gotten to it."
            : "Nothing saved yet. Tap + to stash a podcast, video, restaurant, or anything else worth coming back to."
    }

    private var emptyIcon: String {
        if let selectedCategory { return selectedCategory.symbolName }
        return isDone ? "checkmark.seal" : "bookmark.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: title)
                .overlay(alignment: .trailing) {
                    Text("\(filteredLinks.count) saved")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textFaint)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            categoryFilterRow
                .padding(.top, 4)
                .padding(.bottom, allTags.isEmpty ? 8 : 4)

            if !allTags.isEmpty {
                tagFilterRow
                    .padding(.bottom, 8)
            }

            if filteredLinks.isEmpty {
                EmptyStateView(symbolName: emptyIcon, message: emptyMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                List {
                    ForEach(rows) { row in
                        switch row {
                        case .header(let category):
                            SectionLabel(text: category.displayName)
                                .listRowBackground(Color.bgPage)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        case .link(let link):
                            NavigationLink {
                                LinkDetailView(link: link)
                            } label: {
                                LinkRow(link: link)
                            }
                            .listRowBackground(Color.bgCard)
                            .swipeActions(edge: .leading) {
                                Button {
                                    link.isDone.toggle()
                                } label: {
                                    Label(
                                        link.isDone ? "Reopen" : "Done",
                                        systemImage: link.isDone ? "arrow.uturn.left" : "checkmark"
                                    )
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
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddLink = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLink) {
            AddLinkView()
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(Category.allCases) { category in
                    filterChip(title: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All tags", isSelected: selectedTag == nil) {
                    selectedTag = nil
                }
                ForEach(allTags, id: \.self) { tag in
                    filterChip(title: "#\(tag)", isSelected: selectedTag == tag) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.bgCard : Color.chipText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.accent : Color.chipBg))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateView: View {
    let symbolName: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.chipBg)
                    .frame(width: 72, height: 72)
                Image(systemName: symbolName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.accent)
            }
            Text(message)
                .font(AppFont.secondaryDetail())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 48)
    }
}
