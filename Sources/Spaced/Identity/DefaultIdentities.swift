import Foundation

enum DefaultIdentities {
    static let colors = [
        "#7F77DD",
        "#35C2B1",
        "#F5B84B",
        "#F27059",
        "#4A90E2"
    ]

    static let curatedSymbols = [
        "laptopcomputer",
        "paintbrush.fill",
        "terminal.fill",
        "message.fill",
        "book.fill",
        "music.note",
        "film.fill",
        "folder.fill",
        "gamecontroller.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "bolt.fill",
        "leaf.fill",
        "flame.fill",
        "person.fill",
        "globe",
        "camera.fill",
        "waveform",
        "headphones",
        "cup.and.saucer.fill",
        "briefcase.fill",
        "calendar",
        "pencil.and.outline",
        "hammer.fill",
        "wrench.and.screwdriver.fill",
        "wand.and.stars",
        "sparkles",
        "doc.text.fill",
        "chart.bar.fill",
        "network",
        "lock.fill",
        "shield.fill",
        "mail.fill",
        "phone.fill",
        "video.fill",
        "mic.fill",
        "shippingbox.fill",
        "cart.fill",
        "house.fill",
        "desktopcomputer"
    ]

    static var fallbackColorHex: String {
        colors[0]
    }

    static var fallbackSymbolName: String {
        curatedSymbols[0]
    }

    static func make(spaceID: Int, order: Int) -> SpaceIdentity {
        SpaceIdentity(
            id: spaceID,
            name: "Space \(order)",
            colorHex: color(for: order),
            symbolName: symbol(for: order),
            order: order
        )
    }

    static func color(for order: Int) -> String {
        colors[index(for: order, count: colors.count)]
    }

    static func symbol(for order: Int) -> String {
        curatedSymbols[index(for: order, count: curatedSymbols.count)]
    }

    private static func index(for order: Int, count: Int) -> Int {
        max(order - 1, 0) % count
    }
}
