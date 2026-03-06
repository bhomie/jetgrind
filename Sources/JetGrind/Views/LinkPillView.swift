import SwiftUI
import AppKit

struct LinkPillView: View {
    let link: LinkItem
    var tintColor: Color = Theme.Color.linkPillText
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    private var pastelOpacity: Double {
        colorScheme == .dark ? Theme.Opacity.pastelRowDark : Theme.Opacity.pastelRowLight
    }

    var body: some View {
        Button {
            NSWorkspace.shared.open(link.url)
        } label: {
            HStack(spacing: Theme.Size.linkPillInternalSpacing) {
                faviconImage
                Text(link.displayTitle)
                    .font(.system(size: Theme.Font.caption, weight: .medium))
                    .foregroundStyle(tintColor)
                    .lineLimit(1)
            }
            .padding(.leading, (Theme.Size.linkPillHeight - Theme.Font.body) / 2)
            .padding(.trailing, Theme.Size.linkPillPaddingH)
            .frame(height: Theme.Size.linkPillHeight)
            .background {
                Capsule()
                    .fill(tintColor.opacity(isHovered ? pastelOpacity + 0.04 : pastelOpacity))
                    .blendMode(.plusDarker)
                    .overlay {
                        Capsule()
                            .fill(.black.opacity(0.1))
                    }
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
                .frame(width: Theme.Font.body, height: Theme.Font.body)
                .clipShape(Circle())
        } else {
            Image(systemName: "globe")
                .font(.system(size: Theme.Font.body))
                .foregroundStyle(.secondary)
        }
    }
}
