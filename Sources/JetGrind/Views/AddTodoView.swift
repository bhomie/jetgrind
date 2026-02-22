import SwiftUI

struct AddTodoView: View {
    @State private var title: String = ""
    var focus: FocusState<TodoFocus?>.Binding
    @Binding var injectedText: String
    let firstTaskId: UUID?
    let onAdd: (String) -> Void
    let completedCount: Int
    let showCompletedView: Bool
    let onOpenCompleted: () -> Void
    let onCloseCompleted: () -> Void
    var taskAbsorbed: UUID?

    @State private var bounceScale: CGFloat = 1.0
    @State private var countScale: CGFloat = 1.0

    private var hasValidText: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let containerCornerRadius: CGFloat = 12
    private let collapsedSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 8) {
            // Left container: input field / pencil icon
            inputContainer

            // Right container: completed button
            if completedCount > 0 {
                completedContainer
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCompletedView)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .onChange(of: taskAbsorbed) { _, newValue in
            if newValue != nil {
                triggerBounce()
            }
        }
    }

    @ViewBuilder
    private var inputContainer: some View {
        HStack(spacing: 0) {
            // TextField (visible when completed view closed)
            TextField("Add a task...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: Theme.Font.body))
                .focused(focus, equals: .input)
                .onSubmit {
                    guard hasValidText else { return }
                    onAdd(title)
                    title = ""
                }
                .onKeyPress(.downArrow) {
                    if let firstId = firstTaskId {
                        focus.wrappedValue = .task(firstId)
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.rightArrow) {
                    if completedCount > 0 {
                        onOpenCompleted()
                        return .handled
                    }
                    return .ignored
                }
                .onChange(of: injectedText) { _, newValue in
                    if !newValue.isEmpty {
                        title = newValue
                        injectedText = ""
                    }
                }
                .opacity(showCompletedView ? 0 : 1)
                .frame(maxWidth: showCompletedView ? 0 : .infinity)
                .clipped()

            // Plus icon — always present, centers when collapsed
            Button(action: {
                if showCompletedView {
                    onCloseCompleted()
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(showCompletedView ? .secondary : Color.accentColor)
                    .font(.system(size: Theme.Font.iconLarge))
                    .frame(width: Theme.Font.iconLarge, height: Theme.Font.iconLarge)
            }
            .buttonStyle(.plain)
            .padding(.leading, showCompletedView ? 0 : 8)
            .opacity(showCompletedView ? 1 : (hasValidText ? 1 : 0))
            .scaleEffect(showCompletedView ? 1 : (hasValidText ? 1 : 0.2))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: hasValidText)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, showCompletedView ? 0 : 12)
        .frame(maxWidth: showCompletedView ? collapsedSize : .infinity)
        .frame(height: collapsedSize)
        .background(
            RoundedRectangle(cornerRadius: containerCornerRadius)
                .fill(.primary.opacity(Theme.Opacity.inputBackground))
        )
    }

    @ViewBuilder
    private var completedContainer: some View {
        Button(action: {
            if showCompletedView {
                onCloseCompleted()
            } else {
                onOpenCompleted()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: Theme.Font.actionIcon))
                if showCompletedView {
                    Text("Completed")
                        .font(.system(size: Theme.Font.bodyMedium, weight: .semibold))
                    Spacer()
                }
                Text("\(completedCount)")
                    .font(.system(size: Theme.Font.bodyMedium, weight: .medium))
                    .contentTransition(.numericText())
                    .scaleEffect(countScale)
            }
            .foregroundStyle(showCompletedView ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .scaleEffect(bounceScale)
        .padding(.vertical, 12)
        .padding(.horizontal, showCompletedView ? 12 : 0)
        .frame(maxWidth: showCompletedView ? .infinity : collapsedSize)
        .frame(height: collapsedSize)
        .background(
            RoundedRectangle(cornerRadius: containerCornerRadius)
                .fill(.primary.opacity(Theme.Opacity.inputBackground))
        )
    }

    private func triggerBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            countScale = 1.15
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                countScale = 1.0
            }
        }
    }
}
