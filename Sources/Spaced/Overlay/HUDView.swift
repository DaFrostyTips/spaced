@preconcurrency import AppKit
import SwiftUI

struct HUDView: View {
    let identity: SpaceIdentity

    private var accent: Color {
        ColorHex.color(from: identity.colorHex)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: identity.symbolName)
                .font(.system(size: 28, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(accent)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(identity.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(Self.subtitle(for: identity))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: HUDWindowController.hudSize.width, height: HUDWindowController.hudSize.height)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    static func subtitle(for identity: SpaceIdentity) -> String {
        "Desktop \(identity.order)"
    }
}
