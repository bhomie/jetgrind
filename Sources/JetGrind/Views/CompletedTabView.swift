import SwiftUI

struct CompletedTabView: View {
    @Bindable var store: TodoStore
    var focus: FocusState<TodoFocus?>.Binding
    let onDismiss: () -> Void
    let onDismissToTask: (UUID) -> Void

    @State private var isScrolledFromTop = false

    private var completedItems: [TodoItem] {
        store.items.filter { $0.isCompleted }
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 4) {
                    ForEach(Array(completedItems.enumerated()), id: \.element.id) { index, item in
                        let prevId = index > 0 ? completedItems[index - 1].id : nil
                        let nextId = index < completedItems.count - 1 ? completedItems[index + 1].id : nil
                        completedRow(item: item, previousId: prevId, nextId: nextId, isFirst: index == 0, rowIndex: index)
                    }
                    Spacer().frame(height: 36)
                }
                .padding(.horizontal, 8)
                .onChange(of: focus.wrappedValue) { oldFocus, newFocus in
                    guard let newFocus else { return }

                    switch newFocus {
                    case .completedTask(let id):
                        let newIndex = completedItems.firstIndex(where: { $0.id == id }) ?? 0
                        let oldIndex: Int
                        if case .completedTask(let oldId) = oldFocus {
                            oldIndex = completedItems.firstIndex(where: { $0.id == oldId }) ?? 0
                        } else {
                            oldIndex = -1
                        }
                        if oldIndex == newIndex { return }
                        let anchor: UnitPoint = newIndex > oldIndex
                            ? UnitPoint(x: 0.5, y: 0.85)
                            : UnitPoint(x: 0.5, y: 0.15)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(id, anchor: anchor)
                        }
                    default:
                        break
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 5
        } action: { _, isScrolled in
            withAnimation(.easeInOut(duration: 0.2)) {
                isScrolledFromTop = isScrolled
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: isScrolledFromTop ? .clear : .black, location: 0),
                    .init(color: .black, location: isScrolledFromTop ? 0.12 : 0),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 0.2), value: isScrolledFromTop)
        )
    }

    private func deleteTask(item: TodoItem, nextId: UUID?, previousId: UUID?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            store.delete(id: item.id)
        }
        if let nextId = nextId {
            focus.wrappedValue = .completedTask(nextId)
        } else if let prevId = previousId {
            focus.wrappedValue = .completedTask(prevId)
        } else {
            onDismiss()
        }
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
    private func completedRow(item: TodoItem, previousId: UUID?, nextId: UUID?, isFirst: Bool, rowIndex: Int = 0) -> some View {
        let isFocused = focus.wrappedValue == .completedTask(item.id)
        let pastelColor = Theme.Pastel.color(for: rowIndex)

        HStack(spacing: 12) {
            if let emoji = item.emoji {
                Text(emoji)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: Theme.Font.icon))
                    .foregroundStyle(Theme.Color.completedCheckmark)
            }

            Text(item.title)
                .font(.system(size: Theme.Font.bodyMedium, weight: .medium))
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(item.createdAt.relativeFormat)
                .font(.system(size: Theme.Font.body))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(pastelColor.opacity(Theme.Opacity.pillBackground)))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(pastelColor.opacity(isFocused ? Theme.Opacity.pastelRowDark * 3 : Theme.Opacity.pastelRowDark))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            deleteTask(item: item, nextId: nextId, previousId: previousId)
            return .handled
        }
        .onKeyPress { keyPress in
            if keyPress.key.character == "\u{7F}" {
                deleteTask(item: item, nextId: nextId, previousId: previousId)
                return .handled
            }
            return .ignored
        }
    }
}
