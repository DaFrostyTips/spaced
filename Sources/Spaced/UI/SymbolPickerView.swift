import SwiftUI

struct SymbolPickerView: View {
    @Binding var symbolName: String
    @State private var query = ""

    private var filteredSymbols: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return DefaultIdentities.curatedSymbols
        }

        return DefaultIdentities.curatedSymbols.filter {
            $0.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 42), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Search symbols", text: $query)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            symbolName = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 38, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(symbol == symbolName ? Color.primary : Color.secondary)
                        .help(symbol)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
