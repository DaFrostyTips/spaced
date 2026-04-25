@preconcurrency import AppKit
import Foundation

@MainActor
final class SpaceObserver {
    var onInitialSpaceID: (Int) -> Void = { _ in }
    var onSpaceChange: (Int) -> Void = { _ in }

    private let provider: SpaceIDProviding
    private let notificationCenter: NotificationCenter
    private let debounceNanoseconds: UInt64
    private var notificationObserver: NSObjectProtocol?
    private var debounceTask: Task<Void, Never>?
    private var tracker = SpaceIDChangeTracker()

    init(
        provider: SpaceIDProviding = CGSSpaceIDProvider(),
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        debounceNanoseconds: UInt64 = 120_000_000
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        self.debounceNanoseconds = debounceNanoseconds
    }

    deinit {
        if let notificationObserver {
            notificationCenter.removeObserver(notificationObserver)
        }
        debounceTask?.cancel()
    }

    func start() {
        let currentSpaceID = provider.currentSpaceID()
        tracker.recordInitial(currentSpaceID)
        onInitialSpaceID(currentSpaceID)

        notificationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleDebouncedCheck()
            }
        }
    }

    func currentSpaceID() -> Int {
        provider.currentSpaceID()
    }

    func stop() {
        if let notificationObserver {
            notificationCenter.removeObserver(notificationObserver)
            self.notificationObserver = nil
        }

        debounceTask?.cancel()
        debounceTask = nil
    }

    func processSpaceCheckForTesting() {
        processSpaceCheck()
    }

    private func scheduleDebouncedCheck() {
        debounceTask?.cancel()

        let delay = debounceNanoseconds
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else {
                return
            }

            self?.processSpaceCheck()
        }
    }

    private func processSpaceCheck() {
        let currentSpaceID = provider.currentSpaceID()
        guard let changedSpaceID = tracker.changedSpaceID(from: currentSpaceID) else {
            return
        }

        onSpaceChange(changedSpaceID)
    }
}
