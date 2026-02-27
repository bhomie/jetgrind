import SwiftUI
import AppKit

struct LinkPillView: View {
    let link: LinkItem
    var tintColor: Color = Theme.Color.linkPillText
    @State private var isHovered = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(link.url)
        } label: {
            HStack(spacing: Theme.Size.linkPillInternalSpacing) {
                faviconImage
                Text(link.displayTitle)
                    .font(.system(size: Theme.Font.linkPillLabel, weight: .medium))
                    .foregroundStyle(tintColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, Theme.Size.linkPillPaddingH)
            .frame(height: Theme.Size.linkPillHeight)
            .background {
                Capsule()
                    .fill(tintColor.opacity(isHovered ? Theme.Opacity.linkPillHover : Theme.Opacity.linkPillBackground))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(link.url.absoluteString)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    @ViewBuilder
    private var faviconImage: some View {
        if let data = link.faviconData, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: Theme.Font.linkPillFavicon, height: Theme.Font.linkPillFavicon)
                .clipShape(Circle())
        } else {
            Image(systemName: "globe")
                .font(.system(size: Theme.Font.linkPillFavicon))
                .foregroundStyle(.secondary)
        }
    }
}
