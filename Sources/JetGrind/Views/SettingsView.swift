import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var todoStore: TodoStore
    @State private var showClearConfirmation = false

    private var hasCompletedTasks: Bool {
        todoStore.items.contains { $0.isCompleted }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    // Registration can fail if not in an app bundle
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: launchAtLogin)
                Toggle("Show Shortcut Hints", isOn: $settingsStore.showShortcutHints)
            }

            Section("Keyboard Shortcut") {
                HotKeyRecorderView(settingsStore: settingsStore)
            }

            Section {
                Button("Clear Completed Tasks", role: .destructive) {
                    showClearConfirmation = true
                }
                .disabled(!hasCompletedTasks)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize()
        .alert("Clear Completed Tasks?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                todoStore.clearCompleted()
            }
        } message: {
            Text("This will permanently remove all completed tasks.")
        }
    }
}
