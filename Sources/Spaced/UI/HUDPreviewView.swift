import SwiftUI

struct HUDPreviewView: View {
    let identity: SpaceIdentity?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let identity {
                HUDView(identity: identity)
                    .scaleEffect(0.8)
                    .frame(
                        width: HUDWindowController.hudSize.width * 0.8,
                        height: HUDWindowController.hudSize.height * 0.8
                    )
                    .frame(maxWidth: .infinity)
            } else {
                Text("Switch Spaces once to create an identity.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
        }
    }
}
