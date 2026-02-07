import SwiftUI

struct TravelingTask: Identifiable {
    let id: UUID
    let title: String
    var startFrame: CGRect
    var progress: CGFloat = 0
}

struct TodoListView: View {
    @Bindable var store: TodoStore
    @FocusState private var focus: TodoFocus?
    @State private var showEmptyState = false
    @State private var injectedText: String = ""
    @State private var showCompletedSheet = false
    @State private var pillFrame: CGRect = .zero
    @State private var travelingTasks: [TravelingTask] = []
    @State private var taskToAbsorb: UUID?

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
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(width: 320, height: 400)
        .onPreferenceChange(CompletedPillAnchorKey.self) { frame in
            pillFrame = frame
        }
        .overlay { travelingTasksOverlay }
        .overlay { completedSheetOverlay }
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
        TodoRowView(
            item: itemBinding,
            focus: $focus,
            previousTaskId: previousTaskId,
            nextTaskId: nextTaskId,
            hasCompletedItems: !completedItems.isEmpty,
            onDelete: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.delete(id: item.id)
                }
            },
            onStartTravel: { frame in
                startTravelAnimation(for: item, from: frame)
            }
        )
        .transition(.blurReplace)
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
    private var travelingTasksOverlay: some View {
        GeometryReader { geometry in
            ForEach(travelingTasks) { task in
                travelingTaskView(task: task, geometry: geometry)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func travelingTaskView(task: TravelingTask, geometry: GeometryProxy) -> some View {
        let localOrigin = geometry.frame(in: .global).origin
        let targetX = pillFrame.midX - localOrigin.x
        let targetY = pillFrame.midY - localOrigin.y
        let startX = task.startFrame.midX - localOrigin.x
        let startY = task.startFrame.midY - localOrigin.y
        let currentX = startX + (targetX - startX) * task.progress
        let currentY = startY + (targetY - startY) * task.progress
        let scale = 1.0 - (0.7 * task.progress)
        let opacity = task.progress < 0.9 ? 1.0 : (1.0 - (task.progress - 0.9) * 10.0)
        
        ZStack {
            // Particle trail
            TravelParticleView(
                position: CGPoint(x: currentX, y: currentY),
                isActive: task.progress > 0 && task.progress < 1.0
            )
            
            // Traveling checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Theme.Font.icon))
                .foregroundStyle(.primary)
                .scaleEffect(scale)
                .position(x: currentX, y: currentY)
                .opacity(opacity)
        }
    }

    @ViewBuilder
    private var completedSheetOverlay: some View {
        if showCompletedSheet {
            CompletedSheetView(store: store, isPresented: $showCompletedSheet, focus: $focus)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func startTravelAnimation(for item: TodoItem, from frame: CGRect) {
        let task = TravelingTask(id: item.id, title: item.title, startFrame: frame)
        travelingTasks.append(task)
        
        // Animate the travel
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            if let index = travelingTasks.firstIndex(where: { $0.id == item.id }) {
                travelingTasks[index].progress = 1.0
            }
        }
        
        // Remove after animation completes and trigger pill bounce
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            taskToAbsorb = item.id
            travelingTasks.removeAll { $0.id == item.id }
            
            // Reset absorption trigger
            try? await Task.sleep(for: .milliseconds(100))
            taskToAbsorb = nil
        }
    }
}
