import SwiftUI

struct AddTodoView: View {
    @State private var title: String = ""
    var focus: FocusState<TodoFocus?>.Binding
    let firstTaskId: UUID?
    let onAdd: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 18))

            TextField("Add a task...", text: $title)
                .textFieldStyle(.plain)
                .focused(focus, equals: .input)
                .onSubmit {
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
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}
