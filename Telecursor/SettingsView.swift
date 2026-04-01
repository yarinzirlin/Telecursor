import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Hotkeys") {
                HStack {
                    Text("Next Screen")
                    Spacer()
                    KeyRecorderButton(
                        label: appState.forwardHotkey.displayName,
                        isRecording: appState.recordingTarget == .forward
                    ) {
                        if appState.recordingTarget == .forward {
                            appState.stopRecording()
                        } else {
                            appState.startRecording(target: .forward)
                        }
                    }
                }
                HStack {
                    Text("Previous Screen")
                    Spacer()
                    KeyRecorderButton(
                        label: appState.reverseHotkey.displayName,
                        isRecording: appState.recordingTarget == .reverse
                    ) {
                        if appState.recordingTarget == .reverse {
                            appState.stopRecording()
                        } else {
                            appState.startRecording(target: .reverse)
                        }
                    }
                }
            }

            Section("Accessibility") {
                HStack {
                    Image(systemName: appState.accessibilityGranted
                          ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(appState.accessibilityGranted ? .green : .red)
                    Text(appState.accessibilityGranted ? "Granted" : "Required")
                    Spacer()
                    if !appState.accessibilityGranted {
                        Button("Grant Access") { appState.requestAccessibility() }
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: loginItemBinding)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }

    private var loginItemBinding: Binding<Bool> {
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
                    print("Login item error: \(error)")
                }
            }
        )
    }
}
