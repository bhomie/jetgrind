import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore
    var settingsStore: SettingsStore
    @FocusState private var focus: TodoFocus?
    @State private var showEmptyState = false
    @State private var showAllDoneState = false
    @State private var injectedText: String = ""
    @State private var showCompletedView = false
    @State private var completedViewEntryTaskId: UUID?
    @State private var taskToAbsorb: UUID?
    @State private var expandedTaskId: UUID?
    @State private var editingTaskId: UUID?
    @State private var lastCompletedIndex: Int?
    @State private var isScrolledFromTop = false

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
                            allDoneStateView
                                .onAppear {
                                    showAllDoneState = true
                                }
                                .onDisappear {
                                    showAllDoneState = false
                                }
                        } else {
                            ScrollView {
                                ScrollViewReader { proxy in
                                    LazyVStack(spacing: 4) {
                                        ForEach(Array(incompleteItems.enumerated()), id: \.element.id) { index, item in
                                            let prevId = index > 0 ? incompleteItems[index - 1].id : nil
                                            let nextId = index < incompleteItems.count - 1 ? incompleteItems[index + 1].id : nil

                                            todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId, rowIndex: index)
                                        }
                                        Spacer().frame(height: 36)
                                    }
                                    .padding(.horizontal, 8)
                                    .onChange(of: focus) { oldFocus, newFocus in
                                        guard let newFocus else { return }

                                        switch newFocus {
                                        case .task(let id):
                                            let newIndex = incompleteItems.firstIndex(where: { $0.id == id }) ?? 0
                                            let oldIndex: Int
                                            switch oldFocus {
                                            case .task(let oldId):
                                                oldIndex = incompleteItems.firstIndex(where: { $0.id == oldId }) ?? 0
                                            case .input:
                                                oldIndex = -1
                                            default:
                                                return // action/edit focus on same row — no scroll
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
            .overlay(alignment: .bottom) {
                if settingsStore.showShortcutHints {
                    HotkeyHintsView(newTaskShortcut: settingsStore.displayString)
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)
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
        .onChange(of: focus) { _, newFocus in
            switch newFocus {
            case .input:
                withAnimation(Theme.Anim.fanOut) {
                    expandedTaskId = nil
                }
            case .task(let id):
                let item = store.items.first { $0.id == id }
                let hasContent = item?.description != nil || !(item?.links.isEmpty ?? true)
                withAnimation(Theme.Anim.fanOut) {
                    expandedTaskId = hasContent ? id : nil
                }
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusTaskInput)) { _ in
            focus = .input
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidClose)) { _ in
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
            // Set cascade index to 0 (items shift up from the top)
            lastCompletedIndex = 0
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                taskToAbsorb = nil
                lastCompletedIndex = nil
            }
        }
    }

    @ViewBuilder
    private func todoRow(item: TodoItem, previousTaskId: UUID?, nextTaskId: UUID?, rowIndex: Int = 0) -> some View {
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
                if editingTaskId == item.id {
                    editingTaskId = nil
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.delete(id: item.id)
                }
            },
            onOpenCompleted: !completedItems.isEmpty ? { openCompletedView(fromTaskId: item.id) } : nil,
            isExpanded: expandedBinding,
            isEditBlurred: editingTaskId != nil && editingTaskId != item.id,
            onExpand: {
                withAnimation(Theme.Anim.fanOut) {
                    expandedTaskId = item.id
                }
            },
            onEditingChanged: { isEditing in
                withAnimation(Theme.Anim.fanOut) {
                    editingTaskId = isEditing ? item.id : nil
                }
            },
            rowIndex: rowIndex,
            cascadeDelay: {
                guard let ci = lastCompletedIndex else { return 0 }
                return max(0, Double(rowIndex - ci)) * 0.03
            }()
        )
        .transition(.move(edge: .top).combined(with: .scale(scale: 0.95)).combined(with: .opacity))
    }

    private var emptyStateView: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Pastel.mint.opacity(0.08), Theme.Pastel.butter.opacity(0.06), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 12) {
                Text("🌱")
                    .font(.system(size: Theme.Font.hero))
                    .offset(y: showEmptyState ? -4 : 4)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: showEmptyState)

                Text("Plant your first task")
                    .font(.system(size: Theme.Font.body, weight: .bold))
                    .foregroundStyle(.secondary)
                    .opacity(showEmptyState ? 1.0 : 0)
                    .blur(radius: showEmptyState ? 0 : 4)

                HStack(spacing: 3) {
                    Text(settingsStore.displayString)
                        .fontWeight(.medium)
                    Text("new task")
                }
                .font(.system(size: Theme.Font.caption))
                .foregroundStyle(.secondary)
                .opacity(showEmptyState ? 1.0 : 0)
                .blur(radius: showEmptyState ? 0 : 4)
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showEmptyState)
    }

    private var allDoneStateView: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Pastel.lavender.opacity(0.08), Theme.Pastel.rose.opacity(0.06), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: Theme.Font.hero))
                    .rotationEffect(.degrees(showAllDoneState ? 10 : -10))
                    .scaleEffect(showAllDoneState ? 1.1 : 0.95)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showAllDoneState)

                Text("Crushed it!")
                    .font(.system(size: Theme.Font.body, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
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
