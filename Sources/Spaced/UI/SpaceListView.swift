import SwiftUI

struct SpaceListView: View {
    @ObservedObject var model: SpacedController

    static let rowHeight: CGFloat = 36
    static let maxListHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Spaces")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text("\(model.sortedIdentities.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            if model.sortedIdentities.isEmpty {
                Text("No spaces detected")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        Color.primary.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(model.sortedIdentities) { identity in
                            SpaceRowView(model: model, identity: identity)
                        }
                    }
                }
                .frame(height: Self.listHeight(for: model.sortedIdentities.count))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    static func listHeight(for rowCount: Int) -> CGFloat {
        min(maxListHeight, max(rowHeight, CGFloat(rowCount) * rowHeight))
    }
}
