import SwiftUI

struct AddTodoView: View {
    @State private var title: String = ""
    let onAdd: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 18))

            TextField("Add a task...", text: $title)
                .textFieldStyle(.plain)
                .onSubmit {
                    onAdd(title)
                    title = ""
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}
