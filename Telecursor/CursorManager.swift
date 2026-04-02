import CoreGraphics

@_silgen_name("_CGSDefaultConnection")
private func _CGSDefaultConnection() -> UInt32

@_silgen_name("CGSSetCursorScale")
private func CGSSetCursorScale(_ connection: UInt32, _ scale: Float)

final class CursorManager {
    private var lastPositions: [CGDirectDisplayID: CGPoint] = [:]
    private let connection = _CGSDefaultConnection()
    var pulseDuration: Double = 0.6

    private func currentDisplayID() -> CGDirectDisplayID? {
        guard let event = CGEvent(source: nil) else { return nil }
        let point = event.location
        var displayID: CGDirectDisplayID = 0
        var count: UInt32 = 0
        CGGetDisplaysWithPoint(point, 1, &displayID, &count)
        return count > 0 ? displayID : nil
    }

    private func sortedDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &displays, &count)
        return displays.sorted {
            let a = CGDisplayBounds($0)
            let b = CGDisplayBounds($1)
            return a.origin.x != b.origin.x ? a.origin.x < b.origin.x : a.origin.y < b.origin.y
        }
    }

    private func saveCurrentPosition() {
        guard let displayID = currentDisplayID(),
              let event = CGEvent(source: nil) else { return }
        let point = event.location
        let bounds = CGDisplayBounds(displayID)
        lastPositions[displayID] = CGPoint(
            x: point.x - bounds.origin.x,
            y: point.y - bounds.origin.y
        )
    }

    private func teleport(to displayID: CGDirectDisplayID) {
        let bounds = CGDisplayBounds(displayID)
        let target: CGPoint
        if let saved = lastPositions[displayID] {
            let x = min(max(saved.x, 1), bounds.width - 1)
            let y = min(max(saved.y, 1), bounds.height - 1)
            target = CGPoint(x: bounds.origin.x + x, y: bounds.origin.y + y)
        } else {
            target = CGPoint(x: bounds.midX, y: bounds.midY)
        }
        CGWarpMouseCursorPosition(target)
        pulseCursor()
    }

    private func pulseCursor() {
        let conn = connection
        let duration = pulseDuration
        DispatchQueue.global(qos: .userInteractive).async {
            let peakScale: Float = 4.0
            let rampUpTime = 0.07
            let rampDownTime = max(duration - rampUpTime, 0.05)
            let rampUp = max(Int(rampUpTime / 0.012), 1)
            let rampDown = max(Int(rampDownTime / 0.012), 1)
            let upDelay = UInt32(rampUpTime / Double(rampUp) * 1_000_000)
            let downDelay = UInt32(rampDownTime / Double(rampDown) * 1_000_000)

            for i in 0...rampUp {
                let t = Float(i) / Float(rampUp)
                CGSSetCursorScale(conn, 1.0 + (peakScale - 1.0) * t)
                usleep(upDelay)
            }
            for i in 0...rampDown {
                let t = Float(i) / Float(rampDown)
                let ease = t * t
                CGSSetCursorScale(conn, peakScale - (peakScale - 1.0) * ease)
                usleep(downDelay)
            }
            CGSSetCursorScale(conn, 1.0)
        }
    }

    func cycleScreen(forward: Bool) {
        let displays = sortedDisplayIDs()
        guard displays.count > 1,
              let current = currentDisplayID(),
              let index = displays.firstIndex(of: current) else { return }
        saveCurrentPosition()
        let next = forward
            ? (index + 1) % displays.count
            : (index - 1 + displays.count) % displays.count
        teleport(to: displays[next])
    }
}
