import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    var focus: FocusState<TodoFocus?>.Binding
    let previousTaskId: UUID?
    let nextTaskId: UUID?
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .lineLimit(2)

            Spacer()

            Text(item.createdAt.relativeFormat)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(focus.wrappedValue == .task(item.id) ? Color.accentColor.opacity(0.1) : Color.clear)
        .focusable()
        .focused(focus, equals: .task(item.id))
        .onKeyPress(.upArrow) {
            if let prevId = previousTaskId {
                focus.wrappedValue = .task(prevId)
            } else {
                focus.wrappedValue = .input
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if let nextId = nextTaskId {
                focus.wrappedValue = .task(nextId)
            }
            return .handled
        }
        .onKeyPress(.space) {
            onToggle()
            return .handled
        }
        .onKeyPress(.return) {
            onToggle()
            return .handled
        }
        .onKeyPress(.delete) {
            onDelete()
            return .handled
        }
    }
}
