import CoreGraphics
import Carbon.HIToolbox

final class HotkeyManager {
    var onForwardHotkey: (() -> Void)?
    var onReverseHotkey: (() -> Void)?
    var onRecordedKey: ((HotkeyCombo?) -> Void)?
    var forwardCombo: HotkeyCombo = .defaultForward
    var reverseCombo: HotkeyCombo = .defaultReverse
    var isEnabled = true
    var isRecording = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var retryTimer: Timer?

    func start() {
        guard tryCreateTap() else {
            retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                if self?.tryCreateTap() == true {
                    self?.retryTimer?.invalidate()
                    self?.retryTimer = nil
                }
            }
            return
        }
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func tryCreateTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    fileprivate func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        if isRecording {
            if keyCode == Int64(kVK_Escape) {
                DispatchQueue.main.async { self.onRecordedKey?(nil) }
            } else {
                let combo = HotkeyCombo.from(keyCode: keyCode, flags: flags)
                DispatchQueue.main.async { self.onRecordedKey?(combo) }
            }
            return nil
        }

        guard isEnabled else { return Unmanaged.passUnretained(event) }

        if forwardCombo.matches(keyCode: keyCode, flags: flags) {
            DispatchQueue.main.async { self.onForwardHotkey?() }
            return nil
        }
        if reverseCombo.matches(keyCode: keyCode, flags: flags) {
            DispatchQueue.main.async { self.onReverseHotkey?() }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo!).takeUnretainedValue()
    return manager.handleEvent(type: type, event: event)
}
