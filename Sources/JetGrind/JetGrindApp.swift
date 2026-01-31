import SwiftUI

@main
struct JetGrindApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            TodoListView(store: store)
        } label: {
            Image(systemName: "checkmark.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
