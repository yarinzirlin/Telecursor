import SwiftUI

@main
struct TelecursorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Telecursor", systemImage: "arrow.left.arrow.right") {
            MenuContent()
        }
    }
}

struct MenuContent: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        Toggle("Enabled", isOn: $appState.isEnabled)
        Divider()
        Button("Settings\u{2026}") {
            appState.openSettings()
        }
        Divider()
        Button("Quit Telecursor") {
            NSApplication.shared.terminate(nil)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let running = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Bundle.main.bundleIdentifier
        }
        if running.count > 1 {
            NSApp.terminate(nil)
            return
        }
        AppState.shared.start()
    }
}
