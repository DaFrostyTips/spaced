import Foundation

protocol SpaceIDProviding {
    func currentSpaceID() -> Int
}

struct CGSSpaceIDProvider: SpaceIDProviding {
    func currentSpaceID() -> Int {
        CGSGetActiveSpace(CGSMainConnectionID())
    }
}

struct SpaceIDChangeTracker {
    private(set) var previousSpaceID: Int?

    mutating func recordInitial(_ spaceID: Int) {
        previousSpaceID = spaceID
    }

    mutating func changedSpaceID(from currentSpaceID: Int) -> Int? {
        defer {
            previousSpaceID = currentSpaceID
        }

        guard let previousSpaceID else {
            return nil
        }

        return previousSpaceID == currentSpaceID ? nil : currentSpaceID
    }
}
