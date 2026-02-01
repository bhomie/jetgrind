import SwiftUI

struct AddTodoView: View {
    @State private var title: String = ""
    @State private var iconRotation: Double = 0
    @State private var iconColor: Color = .secondary
    var focus: FocusState<TodoFocus?>.Binding
    @Binding var injectedText: String
    let firstTaskId: UUID?
    let onAdd: (String) -> Void

    private var isFocused: Bool {
        focus.wrappedValue == .input
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a task...", text: $title)
                .textFieldStyle(.plain)
                .focused(focus, equals: .input)
                .onSubmit {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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
                .onChange(of: injectedText) { _, newValue in
                    if !newValue.isEmpty {
                        title = newValue
                        injectedText = ""
                    }
                }

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(iconColor)
                .font(.system(size: 18))
                .rotationEffect(.degrees(iconRotation))
                .onChange(of: isFocused) { _, focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        iconRotation = focused ? 90 : 0
                        iconColor = focused ? Color.accentColor : .secondary
                    }
                }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.primary.opacity(0.15))
        )
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
}
