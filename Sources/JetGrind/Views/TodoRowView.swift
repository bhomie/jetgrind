import SwiftUI

struct TodoRowView: View {
    @Binding var item: TodoItem
    let store: TodoStore
    var focus: FocusState<TodoFocus?>.Binding
    let previousTaskId: UUID?
    let nextTaskId: UUID?
    let hasCompletedItems: Bool
    let onDelete: () -> Void
    var onStartTravel: ((CGRect) -> Void)?

    @State private var isHovered = false
    @State private var showTimestamp = false
    @State private var isExpanded = false
    @State private var showConfetti = false
    @State private var isCompleting = false
    @State private var checkboxFrame: CGRect = .zero
    @State private var isEditing = false
    @State private var editText = ""

    private var isActive: Bool {
        !item.isCompleted && (isHovered || focus.wrappedValue == .task(item.id))
    }

    private var isKeyboardFocused: Bool {
        focus.wrappedValue == .task(item.id)
    }

    private var isHighlighted: Bool {
        isHovered || focus.wrappedValue == .task(item.id) || isInActionMode
    }

    private var isInActionMode: Bool {
        switch focus.wrappedValue {
        case .actionEdit(let id), .actionDelete(let id):
            return id == item.id
        default:
            return false
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            checkboxView
            ZStack(alignment: .leading) {
                titleView
                    .opacity(isEditing ? 0 : 1)
                inlineEditField
                    .opacity(isEditing ? 1 : 0)
                    .allowsHitTesting(isEditing)
            }
            .padding(.leading, 8)
            Spacer()
            if !isEditing {
                timestampView
            }
            actionArea
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(Color.primary.opacity(isKeyboardFocused ? Theme.Opacity.rowHighlight : 0))
        }
        .onPreferenceChange(CheckboxFrameKey.self) { frame in
            DispatchQueue.main.async {
                checkboxFrame = frame
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHighlighted)
        .opacity(item.isCompleted ? Theme.Opacity.completedRow : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
        .confettiOverlay(isActive: showConfetti)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardFocused || isExpanded)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInActionMode)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .focusable()
        .focused(focus, equals: .task(item.id))
        .focusEffectDisabled()
        .onKeyPress(.upArrow) {
            if isInActionMode {
                if let prevId = previousTaskId, let idx = focus.wrappedValue?.actionIndex {
                    focus.wrappedValue = TodoFocus.action(index: idx, taskId: prevId)
                }
                return .handled
            }
            if let prevId = previousTaskId {
                focus.wrappedValue = .task(prevId)
            } else {
                focus.wrappedValue = .input
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if isInActionMode {
                if let nextId = nextTaskId, let idx = focus.wrappedValue?.actionIndex {
                    focus.wrappedValue = TodoFocus.action(index: idx, taskId: nextId)
                }
                return .handled
            }
            if let nextId = nextTaskId {
                focus.wrappedValue = .task(nextId)
            } else if hasCompletedItems {
                focus.wrappedValue = .completedPill
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !item.isCompleted else { return .ignored }
            if isInActionMode {
                if let idx = focus.wrappedValue?.actionIndex, idx < 1 {
                    focus.wrappedValue = TodoFocus.action(index: idx + 1, taskId: item.id)
                }
                return .handled
            }
            if isKeyboardFocused {
                focus.wrappedValue = .actionEdit(item.id)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.leftArrow) {
            if isInActionMode {
                if let idx = focus.wrappedValue?.actionIndex {
                    if idx > 0 {
                        focus.wrappedValue = TodoFocus.action(index: idx - 1, taskId: item.id)
                    } else {
                        focus.wrappedValue = .task(item.id)
                    }
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            guard !isEditing, !isInActionMode else { return .ignored }
            handleToggle()
            return .handled
        }
        .onKeyPress(.escape) {
            if isInActionMode {
                focus.wrappedValue = .task(item.id)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            guard !isEditing, !isInActionMode else { return .ignored }
            onDelete()
            return .handled
        }
        .onKeyPress { keyPress in
            guard !isEditing, !isInActionMode else { return .ignored }
            if keyPress.key.character == "\u{7F}" || keyPress.key.character == "\u{08}" {
                onDelete()
                return .handled
            }
            return .ignored
        }
    }

    private var checkboxView: some View {
        Image(systemName: (item.isCompleted || isCompleting) ? "checkmark.circle.fill" : "circle")
            .font(.system(size: Theme.Font.icon))
            .foregroundStyle((item.isCompleted || isCompleting) ? Color.primary : .secondary)
            .scaleEffect(item.isCompleted || isCompleting ? 1 : 0.9)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: item.isCompleted)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isCompleting)
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: CheckboxFrameKey.self,
                    value: geometry.frame(in: .global)
                )
            })
            .onTapGesture {
                handleToggle()
            }
    }

    private var titleView: some View {
        Text(item.title)
            .font(.system(size: Theme.Font.titleMedium, weight: .medium))
            .strikethrough(item.isCompleted)
            .foregroundStyle(item.isCompleted ? .secondary : .primary)
            .lineLimit(isInActionMode || item.isCompleted ? 1 : ((isKeyboardFocused || isExpanded) ? nil : 2))
            .contentTransition(.opacity)
            .blur(radius: isCompleting ? 8 : 0)
            .opacity(isCompleting ? 0 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCompleting)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardFocused || isExpanded)
    }

    private var inlineEditField: some View {
        TextField("Edit task", text: $editText)
            .textFieldStyle(.plain)
            .font(.system(size: Theme.Font.titleMedium, weight: .medium))
            .focusable()
            .focused(focus, equals: .editing(item.id))
            .focusEffectDisabled()
            .onSubmit {
                store.updateTitle(id: item.id, newTitle: editText)
                isEditing = false
                focus.wrappedValue = .task(item.id)
            }
            .onKeyPress(.escape) {
                isEditing = false
                focus.wrappedValue = .task(item.id)
                return .handled
            }
    }

    private var actionArea: some View {
        let visible = isActive || isInActionMode
        return HStack(spacing: isInActionMode ? Theme.Size.actionButtonSpacing : 6) {
            unifiedActionButton(icon: "pencil", label: "Edit", focusCase: .actionEdit(item.id), action: startEditing)
                .onKeyPress(.return) {
                    startEditing()
                    return .handled
                }
            unifiedActionButton(icon: "trash", label: "Delete", focusCase: .actionDelete(item.id), action: onDelete)
                .onKeyPress(.return) {
                    onDelete()
                    return .handled
                }
        }
        .padding(.leading, visible ? 12 : 0)
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.2)
        .frame(width: visible ? nil : 0)
        .clipped()
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: visible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInActionMode)
    }

    private func unifiedActionButton(icon: String, label: String, focusCase: TodoFocus, action: @escaping () -> Void) -> some View {
        let isFocused = focus.wrappedValue == focusCase
        return Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: Theme.Font.actionIcon))
                Text(label)
                    .font(.system(size: Theme.Font.actionLabel, weight: .medium))
                    .transition(.asymmetric(
                        insertion: .push(from: .leading),
                        removal: .push(from: .trailing)
                    ))
                    .opacity(isFocused ? 1 : 0)
                    .frame(width: isFocused ? nil : 0, alignment: .leading)
                    .clipped()
            }
            .foregroundStyle(isInActionMode && isFocused ? .primary : .secondary)
            .padding(.horizontal, isInActionMode ? (isFocused ? 10 : 6) : 4)
            .padding(.vertical, isInActionMode ? 5 : 2)
            .frame(height: Theme.Size.actionButtonSize)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(isInActionMode ? (isFocused ? Theme.Opacity.rowHighlight : Theme.Opacity.pillBackground) : 0))
            }
        }
        .buttonStyle(.plain)
        .focusable()
        .focused(focus, equals: focusCase)
        .focusEffectDisabled()
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInActionMode)
    }

    private var timestampView: some View {
        Text(item.createdAt.relativeFormat)
            .font(.system(size: Theme.Font.timestamp))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(Theme.Opacity.pillBackground))
            }
            .opacity(showTimestamp && !isCompleting && !isInActionMode ? 1 : 0)
            .blur(radius: isCompleting ? 8 : (showTimestamp && !isInActionMode ? 0 : 8))
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isCompleting)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showTimestamp)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isInActionMode)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showTimestamp = true
                }
            }
    }

    private func startEditing() {
        isEditing = true
        editText = item.title
        focus.wrappedValue = .editing(item.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: nil)
        }
    }

    private func handleToggle() {
        if !item.isCompleted {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
            showConfetti = true
                isCompleting = true
                try? await Task.sleep(for: .milliseconds(400))
                showConfetti = false

                onStartTravel?(checkboxFrame)

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    item.isCompleted.toggle()
                }
                try? await Task.sleep(for: .milliseconds(200))
                isCompleting = false
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                item.isCompleted.toggle()
            }
        }
    }
}

private struct CheckboxFrameKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
