import SwiftUI

struct AddTodoView: View {
    @State private var title: String = ""
    var focus: FocusState<TodoFocus?>.Binding
    @Binding var injectedText: String
    let firstTaskId: UUID?
    let onAdd: (String) -> Void

    private var hasValidText: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a task...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
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
                .onChange(of: injectedText) { _, newValue in
                    if !newValue.isEmpty {
                        title = newValue
                        injectedText = ""
                    }
                }

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 18))
                .frame(width: 18, height: 18)
                .opacity(hasValidText ? 1 : 0)
                .scaleEffect(hasValidText ? 1 : 0.2)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: hasValidText)
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
