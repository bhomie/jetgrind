import SwiftUI

enum TodoFocus: Hashable {
    case input
    case task(UUID)
}

struct TodoListView: View {
    @Bindable var store: TodoStore
    @FocusState private var focus: TodoFocus?
    @State private var showEmptyState = false
    @State private var injectedText: String = ""

    private var incompleteItems: [TodoItem] {
        store.items.filter { !$0.isCompleted }
    }

    private var completedItems: [TodoItem] {
        store.items.filter { $0.isCompleted }
    }

    private var allSortedItems: [TodoItem] {
        incompleteItems + completedItems
    }

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                AddTodoView(
                    focus: $focus,
                    injectedText: $injectedText,
                    firstTaskId: allSortedItems.first?.id,
                    onAdd: { title in
                        withAnimation(.easeOut(duration: 0.25)) {
                            store.add(title: title)
                        }
                    }
                )

                if store.items.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(incompleteItems.enumerated()), id: \.element.id) { index, item in
                                let prevId = index > 0 ? incompleteItems[index - 1].id : nil
                                let nextId = index < incompleteItems.count - 1 ? incompleteItems[index + 1].id : completedItems.first?.id
                                todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId)
                            }

                            if !incompleteItems.isEmpty && !completedItems.isEmpty {
                                Spacer()
                                    .frame(height: 16)
                            }

                            ForEach(Array(completedItems.enumerated()), id: \.element.id) { index, item in
                                let prevId = index > 0 ? completedItems[index - 1].id : incompleteItems.last?.id
                                let nextId = index < completedItems.count - 1 ? completedItems[index + 1].id : nil
                                todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
        .onKeyPress { keyPress in
            guard store.items.isEmpty,
                  focus != .input,
                  !keyPress.modifiers.contains(.command),
                  !keyPress.modifiers.contains(.control)
            else { return .ignored }
            
            let char = keyPress.key.character
            guard char.isLetter || char.isNumber || char.isPunctuation || char.isWhitespace
            else { return .ignored }
            
            injectedText = String(char)
            focus = .input
            return .handled
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusTaskInput)) { _ in
            focus = .input
        }
        .onChange(of: store.items.isEmpty) { _, isEmpty in
            if isEmpty {
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    showEmptyState = true
                }
            } else {
                showEmptyState = false
            }
        }
        .onAppear {
            showEmptyState = store.items.isEmpty
        }
    }

    @ViewBuilder
    private func todoRow(item: TodoItem, previousTaskId: UUID?, nextTaskId: UUID?) -> some View {
        TodoRowView(
            item: item,
            focus: $focus,
            previousTaskId: previousTaskId,
            nextTaskId: nextTaskId,
            onToggle: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggle(id: item.id)
                }
            },
            onDelete: {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.delete(id: item.id)
                }
            }
        )
        .transition(.blurReplace)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
                .opacity(showEmptyState ? 1.0 : 0)
                .blur(radius: showEmptyState ? 0 : 8)

            Text("No Tasks")
                .font(.headline)
                .foregroundStyle(.secondary)
                .opacity(showEmptyState ? 1.0 : 0)
                .blur(radius: showEmptyState ? 0 : 4)

            Text("Add a task to get started")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .opacity(showEmptyState ? 1.0 : 0)
                .blur(radius: showEmptyState ? 0 : 4)
        }
        .frame(maxHeight: .infinity)
        .animation(.easeOut(duration: 0.3), value: showEmptyState)
    }
}
