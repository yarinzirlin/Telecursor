import SwiftUI

struct KeyRecorderButton: View {
    let label: String
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isRecording ? "Press a key\u{2026}" : label)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 120)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
