@preconcurrency import AppKit
import SwiftUI

@main
struct SpacedApp: App {
    @NSApplicationDelegateAdaptor(SpacedAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            Text("Spaced runs from the menu bar.")
                .padding(24)
                .frame(width: 320)
        }
    }
}

@MainActor
final class SpacedAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: SpacedController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = SpacedController()
        self.controller = controller
        controller.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        controller?.refreshLaunchAtLoginState()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controller?.showSettingsPanel()
        return true
    }
}
