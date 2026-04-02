import SwiftUI
import ServiceManagement
import ApplicationServices

final class AppState: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = AppState()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
            hotkeyManager.isEnabled = isEnabled
        }
    }

    @Published var forwardHotkey: HotkeyCombo {
        didSet {
            saveHotkey(forwardHotkey, key: "forwardHotkey")
            hotkeyManager.forwardCombo = forwardHotkey
        }
    }

    @Published var reverseHotkey: HotkeyCombo {
        didSet {
            saveHotkey(reverseHotkey, key: "reverseHotkey")
            hotkeyManager.reverseCombo = reverseHotkey
        }
    }

    enum RecordingTarget { case none, forward, reverse }
    @Published var recordingTarget: RecordingTarget = .none
    @Published var accessibilityGranted = false

    @Published var pulseDuration: Double {
        didSet {
            UserDefaults.standard.set(pulseDuration, forKey: "pulseDuration")
            cursorManager.pulseDuration = pulseDuration
        }
    }

    let hotkeyManager = HotkeyManager()
    let cursorManager = CursorManager()
    private var settingsWindow: NSWindow?
    private var accessibilityTimer: Timer?

    private override init() {
        isEnabled = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true
        forwardHotkey = Self.loadHotkey(key: "forwardHotkey") ?? .defaultForward
        reverseHotkey = Self.loadHotkey(key: "reverseHotkey") ?? .defaultReverse
        pulseDuration = UserDefaults.standard.object(forKey: "pulseDuration") as? Double ?? 0.6
    }

    func start() {
        hotkeyManager.forwardCombo = forwardHotkey
        hotkeyManager.reverseCombo = reverseHotkey
        hotkeyManager.isEnabled = isEnabled
        hotkeyManager.onForwardHotkey = { [weak self] in
            self?.cursorManager.cycleScreen(forward: true)
        }
        hotkeyManager.onReverseHotkey = { [weak self] in
            self?.cursorManager.cycleScreen(forward: false)
        }
        cursorManager.pulseDuration = pulseDuration
        hotkeyManager.start()
        checkAccessibility()

        if !accessibilityGranted {
            requestAccessibility()
        }
    }

    // MARK: - Settings Window

    func openSettings() {
        startAccessibilityPolling()
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView().environmentObject(self)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Telecursor Settings"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    func windowWillClose(_ notification: Notification) {
        stopAccessibilityPolling()
    }

    // MARK: - Accessibility

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrustedWithOptions(nil)
    }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    func startAccessibilityPolling() {
        checkAccessibility()
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibility()
        }
    }

    func stopAccessibilityPolling() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = nil
    }

    // MARK: - Hotkey Recording

    func startRecording(target: RecordingTarget) {
        recordingTarget = target
        hotkeyManager.isRecording = true
        hotkeyManager.onRecordedKey = { [weak self] combo in
            guard let self else { return }
            if let combo {
                switch recordingTarget {
                case .forward: forwardHotkey = combo
                case .reverse: reverseHotkey = combo
                case .none: break
                }
            }
            stopRecording()
        }
    }

    func stopRecording() {
        recordingTarget = .none
        hotkeyManager.isRecording = false
        hotkeyManager.onRecordedKey = nil
    }

    // MARK: - Persistence

    private func saveHotkey(_ combo: HotkeyCombo, key: String) {
        if let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadHotkey(key: String) -> HotkeyCombo? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HotkeyCombo.self, from: data)
    }
}
