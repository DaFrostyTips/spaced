@preconcurrency import AppKit
import Combine
import Foundation

@MainActor
final class SpacedController: ObservableObject {
    let settings: AppSettings
    let identityStore: IdentityStore

    @Published private(set) var currentSpaceID: Int?
    @Published var selectedSpaceID: Int?
    @Published private(set) var launchAtLoginSnapshot: LaunchAtLoginSnapshot
    @Published private(set) var transientNotice: String?

    private let launchAtLoginManager: LaunchAtLoginManager
    private let spaceObserver: SpaceObserver
    private let hudWindowController: HUDWindowController
    private var menuBarController: MenuBarController?
    private var settingsPanelController: SettingsPanelController?
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: AppSettings = AppSettings(),
        identityStore: IdentityStore = IdentityStore(),
        spaceObserver: SpaceObserver = SpaceObserver(),
        hudWindowController: HUDWindowController = HUDWindowController(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager()
    ) {
        self.settings = settings
        self.identityStore = identityStore
        self.spaceObserver = spaceObserver
        self.hudWindowController = hudWindowController
        self.launchAtLoginManager = launchAtLoginManager
        self.launchAtLoginSnapshot = LaunchAtLoginSnapshot(
            isEnabled: false,
            isSupported: false,
            detail: "Launch at login has not been checked yet."
        )

        bindModelChanges()
    }

    var sortedIdentities: [SpaceIdentity] {
        identityStore.sortedIdentities
    }

    var currentIdentity: SpaceIdentity? {
        guard let currentSpaceID else {
            return sortedIdentities.first
        }

        return identityStore.identity(for: currentSpaceID) ?? sortedIdentities.first
    }

    var selectedIdentity: SpaceIdentity? {
        if let selectedSpaceID, let identity = identityStore.identity(for: selectedSpaceID) {
            return identity
        }

        return currentIdentity
    }

    func start() {
        settingsPanelController = SettingsPanelController(model: self)
        menuBarController = MenuBarController(model: self)
        refreshLaunchAtLoginState()

        spaceObserver.onInitialSpaceID = { [weak self] spaceID in
            self?.handleInitialSpace(spaceID)
        }
        spaceObserver.onSpaceChange = { [weak self] spaceID in
            self?.handleSpaceChange(spaceID)
        }
        spaceObserver.start()

        syncMenuBarVisibility(showPanelWhenHidden: false)

        if !settings.menuBarIconEnabled {
            showSettingsPanel()
        }
    }

    func identity(for spaceID: Int) -> SpaceIdentity? {
        identityStore.identity(for: spaceID)
    }

    func selectSpace(_ spaceID: Int) {
        selectedSpaceID = spaceID
    }

    func updateName(for spaceID: Int, name: String) {
        identityStore.updateName(for: spaceID, name: name)
    }

    func updateColor(for spaceID: Int, colorHex: String) {
        identityStore.updateColor(for: spaceID, colorHex: colorHex)
    }

    func updateSymbol(for spaceID: Int, symbolName: String) {
        identityStore.updateSymbol(for: spaceID, symbolName: symbolName)
    }

    func moveIdentities(from source: IndexSet, to destination: Int) {
        identityStore.moveIdentity(from: source, to: destination)
    }

    func showSettingsPanel() {
        settingsPanelController?.show()
    }

    func refreshCurrentSpace() {
        let spaceID = spaceObserver.currentSpaceID()
        let identity = recordCurrentSpace(spaceID)
        selectedSpaceID = selectedSpaceID ?? identity.id
    }

    func refreshLaunchAtLoginState() {
        launchAtLoginSnapshot = launchAtLoginManager.snapshot()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLoginRequested = enabled

        if let error = launchAtLoginManager.setEnabled(enabled) {
            transientNotice = error
        } else {
            transientNotice = nil
        }

        refreshLaunchAtLoginState()
    }

    private func bindModelChanges() {
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        identityStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$menuBarIconEnabled
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncMenuBarVisibility(showPanelWhenHidden: true)
            }
            .store(in: &cancellables)
    }

    private func handleInitialSpace(_ spaceID: Int) {
        let identity = recordCurrentSpace(spaceID)
        selectedSpaceID = selectedSpaceID ?? identity.id
    }

    private func handleSpaceChange(_ spaceID: Int) {
        let identity = recordCurrentSpace(spaceID)
        selectedSpaceID = identity.id

        if settings.hudEnabled {
            hudWindowController.show(identity: identity, holdDuration: settings.hudHoldDuration)
        }
    }

    private func recordCurrentSpace(_ spaceID: Int) -> SpaceIdentity {
        let identity = identityStore.recordSeen(spaceID: spaceID)
        identityStore.pruneOrphanedIdentities()
        currentSpaceID = identity.id
        return identity
    }

    private func syncMenuBarVisibility(showPanelWhenHidden: Bool) {
        if settings.menuBarIconEnabled {
            menuBarController?.setVisible(true)
        } else {
            if showPanelWhenHidden {
                showSettingsPanel()
            }

            menuBarController?.setVisible(false)
        }
    }
}
