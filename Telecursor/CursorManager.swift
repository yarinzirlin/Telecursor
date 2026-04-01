import CoreGraphics

final class CursorManager {
    private var lastPositions: [CGDirectDisplayID: CGPoint] = [:]

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
