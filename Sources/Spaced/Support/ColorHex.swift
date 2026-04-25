@preconcurrency import AppKit
import Foundation
import SwiftUI

enum ColorHex {
    static func validated(_ value: String, fallback: String = DefaultIdentities.fallbackColorHex) -> String {
        normalized(value) ?? fallback
    }

    static func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed

        guard raw.count == 6, UInt32(raw, radix: 16) != nil else {
            return nil
        }

        return "#\(raw.uppercased())"
    }

    static func nsColor(from value: String, fallback: String = DefaultIdentities.fallbackColorHex) -> NSColor {
        let hex = validated(value, fallback: fallback)
        let raw = String(hex.dropFirst())
        let scanner = Scanner(string: raw)
        var number: UInt64 = 0
        scanner.scanHexInt64(&number)

        return NSColor(
            calibratedRed: CGFloat((number >> 16) & 0xFF) / 255.0,
            green: CGFloat((number >> 8) & 0xFF) / 255.0,
            blue: CGFloat(number & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    static func color(from value: String) -> Color {
        Color(nsColor: nsColor(from: value))
    }

    static func hex(from color: NSColor) -> String {
        let converted = color.usingColorSpace(.sRGB) ?? color
        let red = Int((converted.redComponent * 255.0).rounded())
        let green = Int((converted.greenComponent * 255.0).rounded())
        let blue = Int((converted.blueComponent * 255.0).rounded())

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
