import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore
    @FocusState private var focus: TodoFocus?
    @State private var showEmptyState = false
    @State private var injectedText: String = ""
    @State private var showCompletedSheet = false
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
                    }
                )

                if incompleteItems.isEmpty && completedItems.isEmpty {
                    emptyStateView
                } else if incompleteItems.isEmpty {
                    // Only completed items exist - show message
                    VStack(spacing: 12) {
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
                        LazyVStack(spacing: 0) {
                            ForEach(Array(incompleteItems.enumerated()), id: \.element.id) { index, item in
                                let prevId = index > 0 ? incompleteItems[index - 1].id : nil
                                let nextId = index < incompleteItems.count - 1 ? incompleteItems[index + 1].id : nil
                                
                                todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                // Completed pill at bottom-left
                if !completedItems.isEmpty {
                    HStack {
                        CompletedPillView(
                            count: completedItems.count,
                            focus: $focus,
                            lastIncompleteTaskId: incompleteItems.last?.id,
                            onOpen: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCompletedSheet = true
                                    if let firstCompleted = completedItems.first {
                                        focus = .completedTask(firstCompleted.id)
                                    }
                                }
                            },
                            taskAbsorbed: taskToAbsorb
                        )
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(width: 320, height: 400)
        .overlay { completedDimmerOverlay }
        .overlay { completedSheetContent }
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
            case .input, .completedPill:
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
            hasCompletedItems: !completedItems.isEmpty,
            onDelete: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.delete(id: item.id)
                }
            },
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

    @ViewBuilder
    private var completedDimmerOverlay: some View {
        if showCompletedSheet {
            Color.black.opacity(Theme.Opacity.overlayDim)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCompletedSheet = false
                        focus = .completedPill
                    }
                }
        }
    }

    @ViewBuilder
    private var completedSheetContent: some View {
        if showCompletedSheet {
            CompletedSheetView(store: store, isPresented: $showCompletedSheet, focus: $focus)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
