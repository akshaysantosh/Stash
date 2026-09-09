import SwiftUI

/// Lays out children left-to-right, wrapping to a new row when a child would overflow the
/// available width — unlike `LazyVGrid(.adaptive)`, each child keeps its own natural size
/// instead of being squeezed into equal-width columns (which is what made tag chips wrap
/// their text and collapse into tall ellipses).
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(item.size))
                x += item.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let last = rows.count - 1
            if rows[last].items.isEmpty {
                rows[last] = Row(items: [RowItem(subview: subview, size: size)], width: size.width, height: size.height)
                continue
            }
            let neededWidth = rows[last].width + horizontalSpacing + size.width
            if neededWidth > maxWidth {
                rows.append(Row(items: [RowItem(subview: subview, size: size)], width: size.width, height: size.height))
            } else {
                rows[last].items.append(RowItem(subview: subview, size: size))
                rows[last].width = neededWidth
                rows[last].height = max(rows[last].height, size.height)
            }
        }
        return rows
    }
}
