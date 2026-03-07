import SwiftUI

struct HotkeyHintsView: View {
    let newTaskShortcut: String

    var body: some View {
        HStack {
            Spacer()
            hint(systemImage: "return.left", label: "complete")
            Spacer()
            hint(key: "E", label: "edit")
            Spacer()
            hint(systemImage: "delete.left", label: "delete")
            Spacer()
            hint(key: newTaskShortcut, label: "new task")
            Spacer()
        }
        .font(.system(size: Theme.Font.caption))
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
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
