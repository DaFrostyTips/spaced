import Foundation

struct SpaceIdentity: Codable, Identifiable, Equatable {
    var id: Int
    var name: String
    var colorHex: String
    var symbolName: String
    var order: Int
}
