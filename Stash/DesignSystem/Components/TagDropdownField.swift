import SwiftUI

/// Multi-select picker over tags that already exist elsewhere in the stash — deliberately
/// no free-text entry here. Picking from a controlled vocabulary at save time keeps tagging
/// fast when you're mid-share from another app; inventing brand-new tags still happens via
/// a link's Edit screen after the fact.
///
/// Uses a plain Button presenting a sheet (rather than a `Menu`) — a `Menu` nested in a
/// Form/List row here turned out not to reliably receive taps, a known-ish SwiftUI quirk
/// where List can swallow taps meant for custom interactive content in a row.
struct TagDropdownField: View {
    let availableTags: [String]
    @Binding var selectedTags: [String]
    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if availableTags.isEmpty {
                Text("No tags yet — tag a link from its Edit screen and it'll show up here next time.")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
            } else {
                HStack {
                    Spacer()
                    Button {
                        showingPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedTags.isEmpty ? "Add tags" : "\(selectedTags.count) tag\(selectedTags.count == 1 ? "" : "s") selected")
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.accent)
                    }
                    .buttonStyle(.borderless)
                }

                if !selectedTags.isEmpty {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        ForEach(selectedTags, id: \.self) { tag in
                            Button {
                                toggle(tag)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("#\(tag)").font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(Color.chipText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.chipBg))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                List(availableTags, id: \.self) { tag in
                    Button {
                        toggle(tag)
                    } label: {
                        HStack {
                            Text(tag)
                                .foregroundStyle(Color.bodyText)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accent)
                            }
                        }
                    }
                }
                .navigationTitle("Select Tags")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingPicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func toggle(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}
