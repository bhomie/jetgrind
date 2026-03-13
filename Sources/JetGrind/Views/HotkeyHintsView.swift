import SwiftUI

struct HotkeyHintsView: View {
    let newTaskShortcut: String
    let visible: Bool

    var body: some View {
        HStack {
            Spacer()
            staggeredHint(index: 0) {
                hint(systemImage: "return.left", label: "complete")
            }
            Spacer()
            staggeredHint(index: 1) {
                hint(key: "E", label: "edit")
            }
            Spacer()
            staggeredHint(index: 2) {
                hint(systemImage: "delete.left", label: "delete")
            }
            Spacer()
            staggeredHint(index: 3) {
                hint(key: newTaskShortcut, label: "new task")
            }
            Spacer()
        }
        .font(.system(size: Theme.Font.caption))
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
    }

    private func staggeredHint<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .scaleEffect(visible ? 1 : 0.01, anchor: .bottom)
            .opacity(visible ? 1 : 0)
            .blur(radius: visible ? 0 : 4)
            .animation(
                visible
                    ? .spring(response: 0.3).delay(0.5 + Double(index) * 0.08)
                    : .spring(response: 0.3).delay(Double(index) * 0.08),
                value: visible
            )
    }

    private func hint(key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .fontWeight(.medium)
            Text(label)
        }
    }

    private func hint(systemImage: String, label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .fontWeight(.medium)
            Text(label)
        }
    }
}
