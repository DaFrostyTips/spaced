import SwiftUI

struct SpaceRowView: View {
    @ObservedObject var model: SpacedController
    let identity: SpaceIdentity

    @State private var symbolPickerPresented = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .font(.system(size: 12))
                .frame(width: 14)
                .help("Display order")

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ColorSwatchButton(colorHex: Binding(
                        get: { currentIdentity.colorHex },
                        set: {
                            model.selectSpace(identity.id)
                            model.updateColor(for: identity.id, colorHex: $0)
                        }
                    ))

                    Button {
                        model.selectSpace(identity.id)
                        symbolPickerPresented.toggle()
                    } label: {
                        Image(systemName: currentIdentity.symbolName)
                            .font(.system(size: 14))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ColorHex.color(from: currentIdentity.colorHex))
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .help("Change Space icon")
                    .popover(isPresented: $symbolPickerPresented) {
                        SymbolPickerView(symbolName: Binding(
                            get: { currentIdentity.symbolName },
                            set: {
                                model.selectSpace(identity.id)
                                model.updateSymbol(for: identity.id, symbolName: $0)
                            }
                        ))
                        .frame(width: 320, height: 360)
                        .padding(12)
                    }
                }
            }

            TextField(
                "Name",
                text: Binding(
                    get: { currentIdentity.name },
                    set: {
                        model.selectSpace(identity.id)
                        model.updateName(for: identity.id, name: $0)
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .focused($nameFocused)
            .onSubmit {
                model.selectSpace(identity.id)
            }
            .help("Edit Spaced's Space name")

            Spacer(minLength: 0)

            Text("\(currentIdentity.order)")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
                .frame(width: 16, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            (isActive ? Color.primary.opacity(0.06) : Color.clear),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .onChange(of: nameFocused) { _, isFocused in
            if isFocused {
                model.selectSpace(identity.id)
            }
        }
    }

    private var currentIdentity: SpaceIdentity {
        model.identity(for: identity.id) ?? identity
    }

    private var isActive: Bool {
        model.currentSpaceID == identity.id
    }
}
