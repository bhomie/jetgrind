import SwiftUI

struct TodoRowView: View {
    @Binding var item: TodoItem
    var focus: FocusState<TodoFocus?>.Binding
    let previousTaskId: UUID?
    let nextTaskId: UUID?
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showTimestamp = false
    @State private var isExpanded = false
    @State private var showRipple = false
    @State private var showConfetti = false

    private var isActive: Bool {
        !item.isCompleted && (isHovered || focus.wrappedValue == .task(item.id))
    }

    private var isKeyboardFocused: Bool {
        focus.wrappedValue == .task(item.id)
    }

    private var isHighlighted: Bool {
        isHovered || focus.wrappedValue == .task(item.id)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            checkboxView
            titleView
                .padding(.leading, 12)
            Spacer()
            timestampView
            deleteButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        .opacity(item.isCompleted ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
        .rippleEffect(isActive: showRipple)
        .confettiOverlay(isActive: showConfetti)
        .animation(.easeInOut(duration: 0.2), value: isKeyboardFocused || isExpanded)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
        .focusable()
        .focused(focus, equals: .task(item.id))
        .focusEffectDisabled()
        .onKeyPress(.upArrow) {
            if let prevId = previousTaskId {
                focus.wrappedValue = .task(prevId)
            } else {
                focus.wrappedValue = .input
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if let nextId = nextTaskId {
                focus.wrappedValue = .task(nextId)
            }
            return .handled
        }
        .onKeyPress(.space) {
            handleToggle()
            return .handled
        }
        .onKeyPress(.return) {
            handleToggle()
            return .handled
        }
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            onDelete()
            return .handled
        }
        .onKeyPress { keyPress in
            // Handle backspace key (MacBook keyboards use this as "Delete")
            if keyPress.key.character == "\u{7F}" || keyPress.key.character == "\u{08}" {
                onDelete()
                return .handled
            }
            return .ignored
        }
    }

    private var checkboxView: some View {
        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 16))
            .foregroundStyle(item.isCompleted ? Color.accentColor : .secondary)
            .scaleEffect(item.isCompleted ? 1 : 0.9)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: item.isCompleted)
            .onTapGesture {
                handleToggle()
            }
    }

    private var titleView: some View {
        Text(item.title)
            .font(.system(size: 12, weight: .medium))
            .strikethrough(item.isCompleted)
            .foregroundStyle(item.isCompleted ? .secondary : .primary)
            .lineLimit(item.isCompleted ? 1 : ((isKeyboardFocused || isExpanded) ? nil : 2))
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            .animation(.easeInOut(duration: 0.2), value: isKeyboardFocused || isExpanded)
    }

    private var timestampView: some View {
        Text(item.createdAt.relativeFormat)
            .font(.system(size: 7))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
            }
            .opacity(showTimestamp ? 1 : 0)
            .blur(radius: showTimestamp ? 0 : 8)
            .animation(.easeOut(duration: 0.25), value: showTimestamp)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showTimestamp = true
                }
            }
    }

    private var deleteButton: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: isActive ? 12 : 0)
            Button(action: onDelete) {
                Image(systemName: "delete.backward")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 0.8 : 0)
            .scaleEffect(isActive ? 1 : 0.2)
            .frame(width: isActive ? nil : 0)
            .clipped()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: item.isCompleted)
    }

    private var backgroundColor: Color {
        isHighlighted ? Color.primary.opacity(0.05) : Color.clear
    }

    private func handleToggle() {
        // Only celebrate when completing, not uncompleting
        if !item.isCompleted {
            Task { @MainActor in
                showRipple = true
                try? await Task.sleep(for: .milliseconds(100))
                showConfetti = true
                try? await Task.sleep(for: .milliseconds(400))
                showRipple = false
                showConfetti = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.isCompleted.toggle()
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                item.isCompleted.toggle()
            }
        }
    }
}
