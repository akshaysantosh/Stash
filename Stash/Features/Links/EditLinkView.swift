import SwiftData
import SwiftUI

/// Edits a copy of the link's fields and only writes back on Save — Cancel truly discards,
/// unlike touching `link` directly via @Bindable.
struct EditLinkView: View {
    let link: SavedLink

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allLinks: [SavedLink]

    @State private var title: String
    @State private var category: Category
    @State private var note: String
    @State private var tags: [String]
    @State private var newTagText = ""

    init(link: SavedLink) {
        self.link = link
        _title = State(initialValue: link.title)
        _category = State(initialValue: link.category)
        _note = State(initialValue: link.note)
        _tags = State(initialValue: link.tags)
    }

    private var suggestedTags: [String] {
        let known = Set(allLinks.flatMap(\.tags))
        return known.subtracting(tags).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { c in
                            Label(c.displayName, systemImage: c.symbolName).tag(c)
                        }
                    }
                    TextField("Note (optional)", text: $note, axis: .vertical)
                }

                Section("Tags") {
                    HStack {
                        TextField("Add a tag", text: $newTagText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { addTag(newTagText) }
                        Button("Add") { addTag(newTagText) }
                            .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !tags.isEmpty {
                        FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                tagChip(tag, removable: true)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if !suggestedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Previously used")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textMuted)
                            FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    tagChip(tag, removable: false)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Edit Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func tagChip(_ tag: String, removable: Bool) -> some View {
        Button {
            if removable {
                removeTag(tag)
            } else {
                addTag(tag)
            }
        } label: {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.system(size: 13, weight: .semibold))
                if removable {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundStyle(removable ? Color.chipText : Color.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(removable ? Color.chipBg : Color.bgPage))
            .overlay(
                Capsule().stroke(removable ? Color.clear : Color.borderCard, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func addTag(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        tags.append(trimmed)
        newTagText = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func save() {
        link.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        link.category = category
        link.note = note
        link.tags = tags
        dismiss()
    }
}
