import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = Theme.Size.linkPillSpacing

    struct CacheData {
        var rows: [[Int]]       // indices per row
        var sizes: [CGSize]     // size per subview (indexed by subview index)
        var rowHeights: [CGFloat] // max height per row
    }

    func makeCache(subviews: Subviews) -> CacheData {
        computeCache(subviews: subviews, proposalWidth: nil)
    }

    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache = computeCache(subviews: subviews, proposalWidth: nil)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        // Recompute rows if proposal width differs from cached layout
        let rows = computeRows(sizes: cache.sizes, maxWidth: maxWidth)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { cache.sizes[$0].height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 {
                height += spacing
            }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        // Refresh sizes from subviews (they may have changed since makeCache)
        for i in subviews.indices {
            cache.sizes[i] = subviews[i].sizeThatFits(.unspecified)
        }
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(sizes: cache.sizes, maxWidth: maxWidth)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { cache.sizes[$0].height }.max() ?? 0
            var x = bounds.minX
            for idx in row {
                let size = cache.sizes[idx]
                subviews[idx].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeCache(subviews: Subviews, proposalWidth: CGFloat?) -> CacheData {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposalWidth ?? .infinity
        let rows = computeRows(sizes: sizes, maxWidth: maxWidth)
        let rowHeights = rows.map { row in
            row.map { sizes[$0].height }.max() ?? 0
        }
        return CacheData(rows: rows, sizes: sizes, rowHeights: rowHeights)
    }

    private func computeRows(sizes: [CGSize], maxWidth: CGFloat) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0

        for i in sizes.indices {
            let size = sizes[i]
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(i)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
