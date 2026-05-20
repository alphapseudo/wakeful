import AppKit
import SwiftUI

@MainActor
final class CustomDurationPanelController: NSObject, NSWindowDelegate {
    static let shared = CustomDurationPanelController()

    private var panel: NSPanel?

    func present(settings: WakeSettings, manager: CaffeinateManager) {
        close()

        let contentView = CustomDurationView(settings: settings, manager: manager) { [weak self] in
            self?.close()
        }

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.layoutSubtreeIfNeeded()
        let fittingSize = hostingController.view.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: fittingSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Custom Duration"
        panel.contentViewController = hostingController
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.delegate = self
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }

    func windowWillClose(_ notification: Notification) {
        panel = nil
    }
}
