import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    var focus: FocusState<TodoFocus?>.Binding
    let previousTaskId: UUID?
    let nextTaskId: UUID?
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showCelebration = false
    @State private var checkboxScale: CGFloat = 1.0
    @State private var showTimestamp = false
    @State private var isExpanded = false

    private var isActive: Bool {
        isHovered || focus.wrappedValue == .task(item.id)
    }

    private var isKeyboardFocused: Bool {
        focus.wrappedValue == .task(item.id)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            checkboxView
            titleView
            Spacer()
            HStack(spacing: isActive ? 12 : 0) {
                timestampView
                deleteButton
            }
        }
        .opacity(item.isCompleted ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
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
        ZStack {
            Button(action: handleToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .font(.system(size: 18))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            sparkleOverlay
        }
    }

    private var sparkleOverlay: some View {
        let colors: [Color] = [.green, .yellow, .blue, .orange, .pink]
        return ForEach(0..<5, id: \.self) { i in
            let angle = (Double(i) / 5.0) * 2 * .pi - .pi / 2
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(colors[i])
                .scaleEffect(showCelebration ? 1.2 : 0)
                .opacity(showCelebration ? 0 : 1)
                .offset(
                    x: showCelebration ? cos(angle) * 20 : 0,
                    y: showCelebration ? sin(angle) * 20 : 0
                )
                .animation(.easeOut(duration: 0.4).delay(Double(i) * 0.03), value: showCelebration)
        }
    }

    private var titleView: some View {
        Text(item.title)
            .fontWeight(.medium)
            .strikethrough(item.isCompleted)
            .foregroundStyle(item.isCompleted ? .secondary : .primary)
            .lineLimit(item.isCompleted ? 1 : ((isKeyboardFocused || isExpanded) ? nil : 2))
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            .animation(.easeInOut(duration: 0.2), value: isKeyboardFocused || isExpanded)
    }

    private var timestampView: some View {
        Text(item.createdAt.relativeFormat)
            .font(.caption2)
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(item.isCompleted ? 0.05 : 0.08))
            .clipShape(Capsule())
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
        Button(action: onDelete) {
            Image(systemName: "delete.backward")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(isActive ? 0.8 : 0)
        .frame(width: isActive ? nil : 0)
        .clipped()
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    private var backgroundColor: Color {
        isActive ? Color.primary.opacity(0.05) : Color.clear
    }

    private func handleToggle() {
        if !item.isCompleted {
            triggerCelebration()
        }
        onToggle()
    }

    private func triggerCelebration() {
        showCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebration = false
        }
    }
}
