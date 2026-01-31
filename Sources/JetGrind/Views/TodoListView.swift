import SwiftUI

enum TodoFocus: Hashable {
    case input
    case task(UUID)
}

struct TodoListView: View {
    @Bindable var store: TodoStore
    @FocusState private var focus: TodoFocus?

    var body: some View {
        VStack(spacing: 0) {
            AddTodoView(
                focus: $focus,
                firstTaskId: store.items.first?.id,
                onAdd: { title in
                    store.add(title: title)
                }
            )

            Divider()

            if store.items.isEmpty {
                ContentUnavailableView {
                    Label("No Tasks", systemImage: "checkmark.circle")
                } description: {
                    Text("Add a task to get started")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                            TodoRowView(
                                item: item,
                                focus: $focus,
                                previousTaskId: index > 0 ? store.items[index - 1].id : nil,
                                nextTaskId: index < store.items.count - 1 ? store.items[index + 1].id : nil,
                                onToggle: { store.toggle(id: item.id) },
                                onDelete: { store.delete(id: item.id) }
                            )

                            if item.id != store.items.last?.id {
                                Divider()
                                    .padding(.leading, 42)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .focusTaskInput)) { _ in
            focus = .input
        }
    }
}
