import SwiftUI

@main
struct JetGrindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settingsStore: appDelegate.settingsStore, todoStore: appDelegate.store)
        }
    }
}
