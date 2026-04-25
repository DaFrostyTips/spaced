@preconcurrency import AppKit
import SwiftUI

@MainActor
final class SettingsPanelController {
    private let model: SpacedController
    private var panel: NSPanel?

    init(model: SpacedController) {
        self.model = model
    }

    func show() {
        let panel = self.panel ?? makePanel()
        self.panel = panel

        NSApp.activate(ignoringOtherApps: true)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 680),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.title = "Spaced"
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.minSize = CGSize(width: 460, height: 560)
        panel.contentViewController = NSHostingController(
            rootView: MenuBarPopover(model: model)
                .frame(minWidth: 460, minHeight: 560)
        )

        return panel
    }
}
