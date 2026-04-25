import Combine
import Foundation

@MainActor
final class IdentityStore: ObservableObject {
    struct Snapshot: Codable, Equatable {
        var version: Int
        var identities: [SpaceIdentity]
        var lastSeenByID: [String: Date]
    }

    enum DefaultsKeys {
        static let snapshot = "Spaced.identitySnapshot"
    }

    static let snapshotVersion = 1
    static let orphanInterval: TimeInterval = 7 * 24 * 60 * 60

    @Published private(set) var identities: [SpaceIdentity]

    private var lastSeenByID: [String: Date]
    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now

        if let snapshot = Self.loadSnapshot(defaults: defaults) {
            identities = snapshot.identities.sorted { $0.order < $1.order }
            lastSeenByID = snapshot.lastSeenByID
        } else {
            identities = []
            lastSeenByID = [:]
        }
    }

    var sortedIdentities: [SpaceIdentity] {
        identities.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.id < rhs.id
            }
            return lhs.order < rhs.order
        }
    }

    func identity(for spaceID: Int) -> SpaceIdentity? {
        identities.first { $0.id == spaceID }
    }

    @discardableResult
    func recordSeen(spaceID: Int, at date: Date? = nil) -> SpaceIdentity {
        let seenAt = date ?? now()
        lastSeenByID[key(for: spaceID)] = seenAt

        if let existing = identity(for: spaceID) {
            persist()
            return existing
        }

        let identity = DefaultIdentities.make(spaceID: spaceID, order: nextOrder())
        identities.append(identity)
        identities = sortedIdentities
        persist()
        return identity
    }

    func pruneOrphanedIdentities(at date: Date? = nil) {
        let cutoff = (date ?? now()).addingTimeInterval(-Self.orphanInterval)
        let originalCount = identities.count

        identities.removeAll { identity in
            guard let lastSeen = lastSeenByID[key(for: identity.id)] else {
                return false
            }

            return lastSeen < cutoff
        }

        if identities.count != originalCount {
            let retainedIDs = Set(identities.map(\.id))
            lastSeenByID = lastSeenByID.filter { retainedIDs.contains(Int($0.key) ?? .min) }
            normalizeOrders()
            persist()
        }
    }

    func updateName(for spaceID: Int, name: String) {
        update(spaceID: spaceID) { identity in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            identity.name = trimmed.isEmpty ? "Space \(identity.order)" : trimmed
        }
    }

    func updateColor(for spaceID: Int, colorHex: String) {
        update(spaceID: spaceID) { identity in
            identity.colorHex = ColorHex.validated(colorHex)
        }
    }

    func updateSymbol(for spaceID: Int, symbolName: String) {
        update(spaceID: spaceID) { identity in
            identity.symbolName = DefaultIdentities.curatedSymbols.contains(symbolName)
                ? symbolName
                : DefaultIdentities.fallbackSymbolName
        }
    }

    func moveIdentity(from source: IndexSet, to destination: Int) {
        var sorted = sortedIdentities
        let moving = source.sorted().map { sorted[$0] }

        for index in source.sorted(by: >) {
            sorted.remove(at: index)
        }

        let removedBeforeDestination = source.filter { $0 < destination }.count
        let insertionIndex = max(0, min(destination - removedBeforeDestination, sorted.count))
        sorted.insert(contentsOf: moving, at: insertionIndex)

        reorder(ids: sorted.map(\.id))
    }

    func reorder(ids: [Int]) {
        var byID = Dictionary(uniqueKeysWithValues: identities.map { ($0.id, $0) })

        for (offset, id) in ids.enumerated() {
            byID[id]?.order = offset + 1
        }

        identities = byID.values.sorted { $0.order < $1.order }
        normalizeOrders()
        persist()
    }

    private func update(spaceID: Int, edit: (inout SpaceIdentity) -> Void) {
        guard let index = identities.firstIndex(where: { $0.id == spaceID }) else {
            return
        }

        edit(&identities[index])
        identities = sortedIdentities
        persist()
    }

    private func nextOrder() -> Int {
        (identities.map(\.order).max() ?? 0) + 1
    }

    private func normalizeOrders() {
        identities = sortedIdentities.enumerated().map { offset, identity in
            var updated = identity
            updated.order = offset + 1
            return updated
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            version: Self.snapshotVersion,
            identities: sortedIdentities,
            lastSeenByID: lastSeenByID
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: DefaultsKeys.snapshot)
    }

    private static func loadSnapshot(defaults: UserDefaults) -> Snapshot? {
        guard let data = defaults.data(forKey: DefaultsKeys.snapshot) else {
            return nil
        }

        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private func key(for spaceID: Int) -> String {
        String(spaceID)
    }
}
