import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore
    @FocusState private var focus: TodoFocus?
    @State private var showEmptyState = false
    @State private var injectedText: String = ""
    @State private var showCompletedView = false
    @State private var completedViewEntryTaskId: UUID?
    @State private var taskToAbsorb: UUID?
    @State private var expandedTaskId: UUID?
    @State private var editingTaskId: UUID?

    private var incompleteItems: [TodoItem] {
        store.items.filter { !$0.isCompleted }
    }

    private var completedItems: [TodoItem] {
        store.items.filter { $0.isCompleted }
    }

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                AddTodoView(
                    focus: $focus,
                    injectedText: $injectedText,
                    firstTaskId: incompleteItems.first?.id,
                    onAdd: { title in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.add(title: title)
                        }
                    },
                    completedCount: completedItems.count,
                    showCompletedView: showCompletedView,
                    onOpenCompleted: { openCompletedView() },
                    onCloseCompleted: { dismissCompletedView() },
                    taskAbsorbed: taskToAbsorb
                )

                ZStack {
                    // Main content
                    Group {
                        if incompleteItems.isEmpty && completedItems.isEmpty {
                            emptyStateView
                        } else if incompleteItems.isEmpty {
                            VStack() {
                                Image(systemName: "party.popper")
                                    .font(.system(size: Theme.Font.emptyStateIcon))
                                    .foregroundStyle(.tertiary)
                                Text("All done!")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack() {
                                    ForEach(Array(incompleteItems.enumerated()), id: \.element.id) { index, item in
                                        let prevId = index > 0 ? incompleteItems[index - 1].id : nil
                                        let nextId = index < incompleteItems.count - 1 ? incompleteItems[index + 1].id : nil

                                        todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId)
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
                    }
                    .opacity(showCompletedView ? 0 : 1)
                    .blur(radius: showCompletedView ? 4 : 0)
                    .allowsHitTesting(!showCompletedView)

                    // Completed tab content
                    CompletedTabView(
                        store: store,
                        focus: $focus,
                        onDismiss: { dismissCompletedView() },
                        onDismissToTask: { taskId in dismissCompletedView(focusTaskId: taskId) }
                    )
                    .opacity(showCompletedView ? 1 : 0)
                    .allowsHitTesting(showCompletedView)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCompletedView)

                Spacer(minLength: 0)
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
        .onChange(of: focus) { _, newFocus in
            switch newFocus {
            case .input:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedTaskId = nil
                }
            case .task(let id):
                let item = store.items.first { $0.id == id }
                let hasContent = item?.description != nil || !(item?.links.isEmpty ?? true)
                if hasContent {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expandedTaskId = id
                    }
                }
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusTaskInput)) { _ in
            focus = .input
        }
        .onChange(of: store.items.isEmpty) { _, isEmpty in
            if isEmpty {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85).delay(0.1)) {
                    showEmptyState = true
                }
            } else {
                showEmptyState = false
            }
        }
        .onAppear {
            showEmptyState = store.items.isEmpty
        }
        .onChange(of: completedItems.count) { oldCount, newCount in
            guard newCount > oldCount else { return }
            taskToAbsorb = UUID()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                taskToAbsorb = nil
            }
        }
    }

    @ViewBuilder
    private func todoRow(item: TodoItem, previousTaskId: UUID?, nextTaskId: UUID?) -> some View {
        let itemBinding = Binding(
            get: { store.items.first { $0.id == item.id } ?? item },
            set: { newValue in
                if let idx = store.items.firstIndex(where: { $0.id == item.id }) {
                    store.items[idx] = newValue
                }
            }
        )
        let expandedBinding = Binding(
            get: { expandedTaskId == item.id },
            set: { newValue in
                expandedTaskId = newValue ? item.id : nil
            }
        )
        TodoRowView(
            item: itemBinding,
            store: store,
            focus: $focus,
            previousTaskId: previousTaskId,
            nextTaskId: nextTaskId,
            onDelete: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.delete(id: item.id)
                }
            },
            onOpenCompleted: !completedItems.isEmpty ? { openCompletedView(fromTaskId: item.id) } : nil,
            isExpanded: expandedBinding,
            isEditBlurred: editingTaskId != nil && editingTaskId != item.id,
            onExpand: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedTaskId = item.id
                }
            },
            onEditingChanged: { isEditing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    editingTaskId = isEditing ? item.id : nil
                }
            }
        )
        .transition(.opacity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: Theme.Font.emptyStateIcon))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showEmptyState)
    }

    private func openCompletedView(fromTaskId: UUID? = nil) {
        guard !completedItems.isEmpty else { return }
        completedViewEntryTaskId = fromTaskId
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showCompletedView = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let first = completedItems.first {
                focus = .completedTask(first.id)
            }
        }
    }

    private func dismissCompletedView(focusTaskId: UUID? = nil) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showCompletedView = false
        }
        if let taskId = focusTaskId {
            focus = .task(taskId)
        } else if let entryId = completedViewEntryTaskId {
            focus = .task(entryId)
            completedViewEntryTaskId = nil
        } else {
            focus = .input
        }
    }
}
