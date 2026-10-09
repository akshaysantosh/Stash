import SwiftUI

/// One-row type filter: All · Watch · Listen · Read · More. "More" opens a menu with the
/// remaining categories, and shows the chosen one's name while it's active, so every category is
/// reachable without a second scrolling chip row.
struct TypePicker: View {
    @Binding var selection: Category?
    @Namespace private var pill
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let primary: [Category] = [.watch, .listen, .read]
    private var more: [Category] { Category.allCases.filter { !Self.primary.contains($0) } }
    private var isMoreSelected: Bool { selection.map(more.contains) ?? false }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            compactMenu
        } else {
            segmented
        }
    }

    /// At accessibility text sizes five segments can't fit on one row, so collapse the whole
    /// picker into a single menu button showing the current type.
    private var compactMenu: some View {
        Menu {
            Button("All") { select(nil) }
            ForEach(Category.allCases) { category in
                Button {
                    select(category)
                } label: {
                    Label(category.displayName, systemImage: category.symbolName)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.s) {
                Text(selection?.displayName ?? "All")
                Image(systemName: "chevron.down").font(.caption.weight(.bold))
            }
            .font(AppFont.chip())
            .foregroundStyle(Color.ink)
            .padding(.horizontal, AppSpacing.l)
            .padding(.vertical, AppSpacing.m)
            .background(Capsule().fill(Color.chipBg))
        }
    }

    private var segmented: some View {
        HStack(spacing: 0) {
            segment("All", isSelected: selection == nil) { select(nil) }
            ForEach(Self.primary) { category in
                segment(category.displayName, isSelected: selection == category) { select(category) }
            }
            Menu {
                ForEach(more) { category in
                    Button {
                        select(category)
                    } label: {
                        Label(category.displayName, systemImage: category.symbolName)
                    }
                }
            } label: {
                label(isMoreSelected ? (selection?.displayName ?? "More") : "More",
                      isSelected: isMoreSelected, showsChevron: !isMoreSelected)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.chipBg))
    }

    private func select(_ category: Category?) {
        withAnimation(.snappy(duration: 0.25)) { selection = category }
    }

    private func segment(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label(title, isSelected: isSelected, showsChevron: false)
        }
        .buttonStyle(.plain)
    }

    private func label(_ title: String, isSelected: Bool, showsChevron: Bool) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .font(AppFont.chip())
        .foregroundStyle(isSelected ? Color.ink : Color.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.s)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.bgCard)
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    .matchedGeometryEffect(id: "pill", in: pill)
            }
        }
        .contentShape(Capsule())
    }
}
