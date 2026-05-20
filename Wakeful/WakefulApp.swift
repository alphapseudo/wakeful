import SwiftUI

@main
struct WakefulApp: App {
    @StateObject private var manager = CaffeinateManager()
    @StateObject private var settings = WakeSettings()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(manager: manager, settings: settings)
        } label: {
            Label(
                "Wakeful",
                systemImage: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
