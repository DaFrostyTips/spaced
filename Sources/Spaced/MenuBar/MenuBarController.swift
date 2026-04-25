@preconcurrency import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let model: SpacedController
    private let popover: NSPopover
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    init(model: SpacedController) {
        self.model = model
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = nil
        popover.contentViewController = NSHostingController(rootView: MenuBarPopover(model: model))

        super.init()
        bindModel()
    }

    func setVisible(_ visible: Bool) {
        if visible {
            ensureStatusItem()
            refreshButton()
        } else {
            popover.performClose(nil)
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
        }
    }

    private func bindModel() {
        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.refreshButton()
                }
            }
            .store(in: &cancellables)
    }

    private func ensureStatusItem() {
        guard statusItem == nil else {
            return
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover)
        button.imagePosition = .imageOnly
        button.toolTip = "Spaced"
    }

    private func refreshButton() {
        guard let button = statusItem?.button else {
            return
        }

        let identity = model.currentIdentity ?? model.sortedIdentities.first
        let symbolName = identity?.symbolName ?? DefaultIdentities.fallbackSymbolName
        let colorHex = identity?.colorHex ?? DefaultIdentities.fallbackColorHex
        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: identity.map { "Spaced \($0.name)" } ?? "Spaced"
        ) ?? NSImage(systemSymbolName: DefaultIdentities.fallbackSymbolName, accessibilityDescription: "Spaced")

        image?.isTemplate = true
        button.image = image
        button.contentTintColor = ColorHex.nsColor(from: colorHex)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
