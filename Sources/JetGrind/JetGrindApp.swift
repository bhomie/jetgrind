import SwiftUI

@main
struct JetGrindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window is managed by AppDelegate directly to avoid
        // SwiftUI runtime warnings about SettingsLink in menu-bar-only apps.
        Settings { EmptyView() }
    }
}
