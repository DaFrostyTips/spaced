import Foundation
import XCTest
@testable import Spaced

@MainActor
final class SpacedTests: XCTestCase {
    func testDefaultIdentitiesUseRequestedColorAndSymbolRamp() {
        let store = IdentityStore(defaults: makeDefaults())

        let first = store.recordSeen(spaceID: 100)
        let second = store.recordSeen(spaceID: 200)
        _ = store.recordSeen(spaceID: 300)
        _ = store.recordSeen(spaceID: 400)
        _ = store.recordSeen(spaceID: 500)
        let sixth = store.recordSeen(spaceID: 600)

        XCTAssertEqual(first.name, "Space 1")
        XCTAssertEqual(first.colorHex, "#7F77DD")
        XCTAssertEqual(first.symbolName, "laptopcomputer")
        XCTAssertEqual(second.colorHex, "#35C2B1")
        XCTAssertEqual(second.symbolName, "paintbrush.fill")
        XCTAssertEqual(sixth.colorHex, "#7F77DD")
        XCTAssertEqual(sixth.symbolName, "music.note")
    }

    func testIdentityStorePersistsJSONAndRestoresEdits() {
        let defaults = makeDefaults()
        let store = IdentityStore(defaults: defaults)

        _ = store.recordSeen(spaceID: 42)
        store.updateName(for: 42, name: "Design")
        store.updateColor(for: 42, colorHex: "#35c2b1")
        store.updateSymbol(for: 42, symbolName: "paintbrush.fill")

        let restored = IdentityStore(defaults: defaults)
        let identity = restored.identity(for: 42)

        XCTAssertEqual(identity?.name, "Design")
        XCTAssertEqual(identity?.colorHex, "#35C2B1")
        XCTAssertEqual(identity?.symbolName, "paintbrush.fill")
        XCTAssertEqual(identity?.order, 1)
    }

    func testIdentityStoreReordersDisplayOrderOnly() {
        let store = IdentityStore(defaults: makeDefaults())

        _ = store.recordSeen(spaceID: 1)
        _ = store.recordSeen(spaceID: 2)
        _ = store.recordSeen(spaceID: 3)

        store.reorder(ids: [3, 1, 2])

        XCTAssertEqual(store.sortedIdentities.map(\.id), [3, 1, 2])
        XCTAssertEqual(store.sortedIdentities.map(\.order), [1, 2, 3])
    }

    func testIdentityStorePrunesSpacesNotSeenForSevenDays() {
        let store = IdentityStore(defaults: makeDefaults())
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        _ = store.recordSeen(spaceID: 1, at: now.addingTimeInterval(-IdentityStore.orphanInterval - 1))
        _ = store.recordSeen(spaceID: 2, at: now)

        store.pruneOrphanedIdentities(at: now)

        XCTAssertEqual(store.sortedIdentities.map(\.id), [2])
        XCTAssertEqual(store.sortedIdentities.first?.order, 1)
    }

    func testInvalidHexFallsBackToDefaultAccent() {
        let store = IdentityStore(defaults: makeDefaults())
        _ = store.recordSeen(spaceID: 7)

        XCTAssertNil(ColorHex.normalized("not-a-color"))
        XCTAssertEqual(ColorHex.validated("not-a-color"), DefaultIdentities.fallbackColorHex)

        store.updateColor(for: 7, colorHex: "not-a-color")
        XCTAssertEqual(store.identity(for: 7)?.colorHex, DefaultIdentities.fallbackColorHex)
    }

    func testControllerEditsIdentityWithoutMissionControlSync() {
        let defaults = makeDefaults()
        let store = IdentityStore(defaults: defaults)
        _ = store.recordSeen(spaceID: 12)

        let controller = SpacedController(
            settings: AppSettings(defaults: defaults),
            identityStore: store,
            spaceObserver: SpaceObserver(
                provider: StubSpaceIDProvider(spaceID: 12),
                notificationCenter: NotificationCenter(),
                debounceNanoseconds: 0
            )
        )

        controller.selectSpace(12)
        controller.updateName(for: 12, name: "Design")
        controller.updateColor(for: 12, colorHex: "#35c2b1")
        controller.updateSymbol(for: 12, symbolName: "paintbrush.fill")

        XCTAssertEqual(controller.identity(for: 12)?.name, "Design")
        XCTAssertEqual(controller.identity(for: 12)?.colorHex, "#35C2B1")
        XCTAssertEqual(controller.identity(for: 12)?.symbolName, "paintbrush.fill")
        XCTAssertEqual(controller.selectedIdentity?.name, "Design")
    }

    func testControllerRefreshCurrentSpaceRecordsEmptyStore() {
        let defaults = makeDefaults()
        let store = IdentityStore(defaults: defaults)
        let provider = StubSpaceIDProvider(spaceID: 77)
        let controller = SpacedController(
            settings: AppSettings(defaults: defaults),
            identityStore: store,
            spaceObserver: SpaceObserver(
                provider: provider,
                notificationCenter: NotificationCenter(),
                debounceNanoseconds: 0
            )
        )

        XCTAssertTrue(controller.sortedIdentities.isEmpty)

        controller.refreshCurrentSpace()

        XCTAssertEqual(controller.sortedIdentities.map(\.id), [77])
        XCTAssertEqual(controller.currentSpaceID, 77)
        XCTAssertEqual(controller.selectedSpaceID, 77)
    }

    func testHUDSubtitleUsesDesktopOrdinal() {
        let identity = SpaceIdentity(
            id: 2,
            name: "Space 2",
            colorHex: "#7F77DD",
            symbolName: "laptopcomputer",
            order: 2
        )

        XCTAssertEqual(HUDView.subtitle(for: identity), "Desktop 2")
    }

    func testSpaceListHeightReservesVisibleRows() {
        XCTAssertEqual(SpaceListView.listHeight(for: 0), 36, accuracy: 0.001)
        XCTAssertEqual(SpaceListView.listHeight(for: 4), 144, accuracy: 0.001)
        XCTAssertEqual(SpaceListView.listHeight(for: 100), 260, accuracy: 0.001)
    }

    func testSettingsClampAndPersistDefaultsBackedValues() {
        let defaults = makeDefaults()
        defaults.set(99.0, forKey: AppSettings.DefaultsKeys.hudHoldDuration)
        defaults.set(false, forKey: AppSettings.DefaultsKeys.hudEnabled)
        defaults.set(false, forKey: AppSettings.DefaultsKeys.menuBarIconEnabled)

        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.hudHoldDuration, 3.0, accuracy: 0.001)
        XCTAssertFalse(settings.hudEnabled)
        XCTAssertFalse(settings.menuBarIconEnabled)

        settings.hudHoldDuration = -1
        settings.hudEnabled = true
        settings.menuBarIconEnabled = true
        settings.launchAtLoginRequested = true

        let restored = AppSettings(defaults: defaults)
        XCTAssertEqual(restored.hudHoldDuration, 0.8, accuracy: 0.001)
        XCTAssertTrue(restored.hudEnabled)
        XCTAssertTrue(restored.menuBarIconEnabled)
        XCTAssertTrue(restored.launchAtLoginRequested)
    }

    func testSpaceChangeTrackerSkipsInitialAndSameSpaceChecks() {
        var tracker = SpaceIDChangeTracker()

        tracker.recordInitial(10)

        XCTAssertNil(tracker.changedSpaceID(from: 10))
        XCTAssertEqual(tracker.changedSpaceID(from: 11), 11)
        XCTAssertNil(tracker.changedSpaceID(from: 11))
    }

    func testSpaceObserverUsesInjectedProviderAndSkipsSameSpace() {
        let provider = StubSpaceIDProvider(spaceID: 10)
        let observer = SpaceObserver(
            provider: provider,
            notificationCenter: NotificationCenter(),
            debounceNanoseconds: 0
        )
        var initialIDs: [Int] = []
        var changedIDs: [Int] = []

        observer.onInitialSpaceID = { initialIDs.append($0) }
        observer.onSpaceChange = { changedIDs.append($0) }
        observer.start()

        provider.spaceID = 10
        observer.processSpaceCheckForTesting()

        provider.spaceID = 12
        observer.processSpaceCheckForTesting()

        XCTAssertEqual(initialIDs, [10])
        XCTAssertEqual(changedIDs, [12])
    }

    func testHUDFrameCentersHorizontallyAndSitsTwentyPercentFromTop() {
        let frame = HUDWindowController.frame(for: CGRect(x: 0, y: 0, width: 1440, height: 900))

        XCTAssertEqual(frame.width, 280, accuracy: 0.001)
        XCTAssertEqual(frame.height, 80, accuracy: 0.001)
        XCTAssertEqual(frame.minX, 580, accuracy: 0.001)
        XCTAssertEqual(frame.minY, 680, accuracy: 0.001)

        let offsetFrame = HUDWindowController.frame(for: CGRect(x: 100, y: 200, width: 1200, height: 900))
        XCTAssertEqual(offsetFrame.midX, 700, accuracy: 0.001)
        XCTAssertEqual(offsetFrame.midY, 920, accuracy: 0.001)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SpacedTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

private final class StubSpaceIDProvider: SpaceIDProviding {
    var spaceID: Int

    init(spaceID: Int) {
        self.spaceID = spaceID
    }

    func currentSpaceID() -> Int {
        spaceID
    }
}
