@preconcurrency import AppKit
import Foundation
import SwiftUI

@MainActor
final class HUDWindowController {
    static let hudSize = CGSize(width: 280, height: 80)
    static let fadeInDuration = 0.15
    static let fadeOutDuration = 0.3

    private var window: HUDWindow?
    private var dismissalTask: Task<Void, Never>?
    private var presentationID = 0

    func show(identity: SpaceIdentity, holdDuration: Double, screen: NSScreen? = NSScreen.main) {
        guard let screen else {
            return
        }

        presentationID += 1
        let presentationID = presentationID
        dismissalTask?.cancel()

        let window = self.window ?? makeWindow()
        self.window = window
        window.contentView = NSHostingView(rootView: HUDView(identity: identity))
        window.setFrame(Self.frame(for: screen.visibleFrame), display: true)
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }

        let delay = Self.fadeInDuration + max(holdDuration, 0)
        dismissalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Self.nanoseconds(for: delay))
            guard !Task.isCancelled, self?.presentationID == presentationID else {
                return
            }

            self?.fadeOutCurrentWindow(presentationID: presentationID)
        }
    }

    static func frame(for screenFrame: CGRect, size: CGSize = hudSize) -> CGRect {
        let centerX = screenFrame.midX
        let centerY = screenFrame.maxY - (screenFrame.height * 0.2)

        return CGRect(
            x: centerX - (size.width / 2),
            y: centerY - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

    private func makeWindow() -> HUDWindow {
        let window = HUDWindow(
            contentRect: CGRect(origin: .zero, size: Self.hudSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.styleMask = .borderless
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.hidesOnDeactivate = false

        return window
    }

    private func fadeOutCurrentWindow(presentationID: Int) {
        guard let window else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard self?.presentationID == presentationID else {
                    return
                }

                self?.window?.orderOut(nil)
            }
        }
    }

    private static func nanoseconds(for seconds: Double) -> UInt64 {
        UInt64((seconds * 1_000_000_000).rounded())
    }
}
