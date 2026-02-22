import SwiftUI

struct CompletedTabView: View {
    @Bindable var store: TodoStore
    var focus: FocusState<TodoFocus?>.Binding
    let onDismiss: () -> Void
    let onDismissToTask: (UUID) -> Void

    private var completedItems: [TodoItem] {
        store.items.filter { $0.isCompleted }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(completedItems.enumerated()), id: \.element.id) { index, item in
                    let prevId = index > 0 ? completedItems[index - 1].id : nil
                    let nextId = index < completedItems.count - 1 ? completedItems[index + 1].id : nil
                    completedRow(item: item, previousId: prevId, nextId: nextId, isFirst: index == 0)
                }
            }
        }
        .scrollIndicators(.hidden)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func uncompleteTask(item: TodoItem, nextId: UUID?, previousId: UUID?) {
        guard let idx = store.items.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            store.items[idx].isCompleted = false
        }
        store.save()
        if let nextId = nextId {
            focus.wrappedValue = .completedTask(nextId)
        } else if let prevId = previousId {
            focus.wrappedValue = .completedTask(prevId)
        } else {
            onDismissToTask(item.id)
        }
    }

    @ViewBuilder
    private func completedRow(item: TodoItem, previousId: UUID?, nextId: UUID?, isFirst: Bool) -> some View {
        let isFocused = focus.wrappedValue == .completedTask(item.id)

        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Theme.Font.icon))
                .foregroundStyle(Theme.Color.completedCheckmark)

            Text(item.title)
                .font(.system(size: Theme.Font.bodyMedium, weight: .medium))
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(item.createdAt.relativeFormat)
                .font(.system(size: Theme.Font.body))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(Theme.Opacity.rowHighlight)))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isFocused ? Color.primary.opacity(Theme.Opacity.rowHighlight) : Color.clear)
        .focusable()
        .focused(focus, equals: .completedTask(item.id))
        .focusEffectDisabled()
        .onKeyPress(.upArrow) {
            if let prevId = previousId {
                focus.wrappedValue = .completedTask(prevId)
            } else {
                onDismiss()
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if let nextId = nextId {
                focus.wrappedValue = .completedTask(nextId)
            }
            return .handled
        }
        .onKeyPress(.leftArrow) {
            onDismiss()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onKeyPress(.return) {
            uncompleteTask(item: item, nextId: nextId, previousId: previousId)
            return .handled
        }
    }
}
