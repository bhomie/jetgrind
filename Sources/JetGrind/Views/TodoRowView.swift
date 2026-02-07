import SwiftUI

struct TodoRowView: View {
    @Binding var item: TodoItem
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
    @State private var rowFrame: CGRect = .zero
    @State private var checkboxFrame: CGRect = .zero

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
        .background(GeometryReader { geometry in
            Color.clear.preference(
                key: RowFrameKey.self,
                value: geometry.frame(in: .global)
            )
        })
        .onPreferenceChange(RowFrameKey.self) { frame in
            rowFrame = frame
        }
        .onPreferenceChange(CheckboxFrameKey.self) { frame in
            checkboxFrame = frame
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHighlighted)
        .opacity(item.isCompleted ? Theme.Opacity.completedRow : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
        .confettiOverlay(isActive: showConfetti)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardFocused || isExpanded)
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
            } else if hasCompletedItems {
                focus.wrappedValue = .completedPill
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
            .lineLimit(item.isCompleted ? 1 : ((isKeyboardFocused || isExpanded) ? nil : 2))
            .contentTransition(.opacity)
            .offset(x: isCompleting ? -320 : 0)
            .opacity(isCompleting ? 0 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCompleting)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardFocused || isExpanded)
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
            .opacity(showTimestamp && !isCompleting ? 1 : 0)
            .blur(radius: isCompleting ? 8 : (showTimestamp ? 0 : 8))
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isCompleting)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showTimestamp)
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
                Image(systemName: "arrow.return.left")
                    .font(.system(size: Theme.Font.icon))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? Theme.Opacity.buttonActive : 0)
            .scaleEffect(isActive ? 1 : 0.2)
            .frame(width: isActive ? nil : 0)
            .clipped()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: item.isCompleted)
    }

    private var backgroundColor: Color {
        isHighlighted ? Color.primary.opacity(Theme.Opacity.rowHighlight) : Color.clear
    }

    private func handleToggle() {
        // Only celebrate when completing, not uncompleting
        if !item.isCompleted {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
            showConfetti = true
                isCompleting = true
                try? await Task.sleep(for: .milliseconds(400))
                showConfetti = false
                
                // Trigger travel animation
                onStartTravel?(checkboxFrame != .zero ? checkboxFrame : rowFrame)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    item.isCompleted.toggle()
                }
                // Reset completing state after animation
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

private struct RowFrameKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct CheckboxFrameKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
