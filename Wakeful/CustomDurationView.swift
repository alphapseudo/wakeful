import SwiftUI

struct CustomDurationView: View {
    @ObservedObject var settings: WakeSettings
    @ObservedObject var manager: CaffeinateManager
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Duration")
                .font(.headline)

            HStack {
                Stepper("Hours: \(settings.customHours)", value: $settings.customHours, in: 0...23)
            }

            HStack {
                Stepper("Minutes: \(settings.customMinutes)", value: $settings.customMinutes, in: 0...59)
            }

            Text("Total: \(settings.formattedDuration(settings.customDurationSeconds))")
                .foregroundStyle(.secondary)

            if !settings.isCustomDurationValid {
                Text("Duration must be at least 1 minute.")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onDismiss()
                }
                Button("Apply") {
                    settings.durationMode = .custom
                    manager.restartIfNeeded(settings: settings)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!settings.isCustomDurationValid)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
