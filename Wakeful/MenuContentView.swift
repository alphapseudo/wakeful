import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var manager: CaffeinateManager
    @ObservedObject var settings: WakeSettings

    var body: some View {
        Text(manager.statusMessage)
            .disabled(true)

        Divider()

        Button(manager.isActive ? "Stop Wakeful" : "Start Wakeful") {
            manager.toggle(settings: settings)
        }
        .disabled(!settings.isCustomDurationValid && !manager.isActive)

        Menu("Duration: \(settings.durationDescription)") {
            ForEach(DurationMode.allCases.filter { $0 != .custom }) { mode in
                Button {
                    settings.durationMode = mode
                    manager.restartIfNeeded(settings: settings)
                } label: {
                    if settings.durationMode == mode {
                        Label(mode.displayName, systemImage: "checkmark")
                    } else {
                        Text(mode.displayName)
                    }
                }
            }

            Divider()

            Button {
                CustomDurationPanelController.shared.present(settings: settings, manager: manager)
            } label: {
                if settings.durationMode == .custom {
                    Label("Custom...", systemImage: "checkmark")
                } else {
                    Text("Custom...")
                }
            }
        }

        Menu("Settings") {
            Toggle("Keep display awake", isOn: $settings.keepDisplayAwake)
                .onChange(of: settings.keepDisplayAwake) { _ in
                    manager.restartIfNeeded(settings: settings)
                }
        }

        Divider()

        Button("Quit Wakeful") {
            manager.stopOnTerminate()
            NSApplication.shared.terminate(nil)
        }
    }
}
