import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var model: SpacedController

    var body: some View {
        SettingsView(model: model)
        .frame(width: 480)
        .onAppear {
            model.refreshCurrentSpace()
        }
    }
}
