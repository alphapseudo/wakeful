import AppKit
import Foundation

@MainActor
final class CaffeinateManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var statusMessage = "Off"
    @Published private(set) var lastError: String?

    private var process: Process?
    private var expiresAt: Date?
    private var countdownTimer: Timer?
    private var terminateObserver: NSObjectProtocol?

    init() {
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopOnTerminate()
            }
        }
    }

    deinit {
        if let terminateObserver {
            NotificationCenter.default.removeObserver(terminateObserver)
        }
    }

    func start(settings: WakeSettings) {
        guard settings.isCustomDurationValid else {
            lastError = "Custom duration must be at least 1 minute"
            statusMessage = lastError ?? "Off"
            return
        }

        stop()
        lastError = nil

        let caffeinate = Process()
        caffeinate.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        caffeinate.arguments = buildArguments(from: settings)
        caffeinate.standardOutput = FileHandle.nullDevice
        caffeinate.standardError = FileHandle.nullDevice
        caffeinate.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.handleProcessEnded(expected: true)
            }
        }

        do {
            try caffeinate.run()
            process = caffeinate
            isActive = true

            if let seconds = settings.durationSeconds {
                expiresAt = Date().addingTimeInterval(TimeInterval(seconds))
                remainingSeconds = seconds
                statusMessage = "Wakeful — \(settings.formattedDuration(seconds)) left"
                startCountdownTimer()
            } else {
                expiresAt = nil
                remainingSeconds = nil
                statusMessage = "Wakeful — Until stopped"
            }
        } catch {
            lastError = "Failed to start caffeinate"
            statusMessage = lastError ?? "Off"
            isActive = false
            process = nil
        }
    }

    func stop() {
        countdownTimer?.invalidate()
        countdownTimer = nil

        if let process, process.isRunning {
            process.terminationHandler = nil
            process.terminate()
        }

        process = nil
        expiresAt = nil
        remainingSeconds = nil
        isActive = false
        if lastError == nil {
            statusMessage = "Off"
        }
    }

    func toggle(settings: WakeSettings) {
        if isActive {
            stop()
            lastError = nil
            statusMessage = "Off"
        } else {
            start(settings: settings)
        }
    }

    func restartIfNeeded(settings: WakeSettings) {
        guard isActive else { return }
        start(settings: settings)
    }

    func stopOnTerminate() {
        stop()
    }

    private func buildArguments(from settings: WakeSettings) -> [String] {
        var args = ["-i"]
        if settings.keepDisplayAwake {
            args.append("-d")
        }
        if let seconds = settings.durationSeconds {
            args.append(contentsOf: ["-t", String(seconds)])
        }
        return args
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }

    private func updateRemainingTime() {
        guard let expiresAt else { return }
        let remaining = max(0, Int(expiresAt.timeIntervalSinceNow.rounded(.down)))
        remainingSeconds = remaining > 0 ? remaining : nil

        if remaining > 0 {
            statusMessage = "Wakeful — \(WakeSettings.formattedDuration(remaining)) left"
        } else {
            handleProcessEnded(expected: true)
        }
    }

    private func handleProcessEnded(expected: Bool) {
        guard isActive || expected else { return }

        countdownTimer?.invalidate()
        countdownTimer = nil
        process = nil
        expiresAt = nil
        remainingSeconds = nil
        isActive = false
        statusMessage = "Off"
    }
}
