import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore

    var body: some View {
        VStack(spacing: 0) {
            AddTodoView { title in
                store.add(title: title)
            }

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
                        ForEach(store.items) { item in
                            TodoRowView(
                                item: item,
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
    }
}
