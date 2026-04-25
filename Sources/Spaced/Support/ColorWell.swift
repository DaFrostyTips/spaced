@preconcurrency import AppKit
import SwiftUI

struct ColorSwatchButton: View {
    @Binding var colorHex: String

    var body: some View {
        Button {
            ColorPanelBridge.shared.show(colorHex: colorHex) { newHex in
                colorHex = newHex
            }
        } label: {
            Circle()
                .fill(ColorHex.color(from: colorHex))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .help("Change Space color")
    }
}

@MainActor
private final class ColorPanelBridge: NSObject {
    static let shared = ColorPanelBridge()

    private var onChange: ((String) -> Void)?
    private var observer: NSObjectProtocol?

    func show(colorHex: String, onChange: @escaping (String) -> Void) {
        self.onChange = onChange

        let panel = NSColorPanel.shared
        panel.color = ColorHex.nsColor(from: colorHex)
        panel.showsAlpha = false
        panel.isContinuous = true
        installObserver(for: panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installObserver(for panel: NSColorPanel) {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }

        observer = NotificationCenter.default.addObserver(
            forName: NSColorPanel.colorDidChangeNotification,
            object: panel,
            queue: .main
        ) { [weak self] notification in
            guard let panel = notification.object as? NSColorPanel else {
                return
            }

            Task { @MainActor in
                self?.onChange?(ColorHex.hex(from: panel.color))
            }
        }
    }
}
