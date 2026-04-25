@preconcurrency import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SpacedController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            previewSection
            Divider()
            displayControlsSection
            Divider()
            SpaceListView(model: model)
            footer
        }
    }

    private var currentSpace: SpaceIdentity? {
        model.currentIdentity ?? model.sortedIdentities.first
    }

    private var previewSpace: SpaceIdentity? {
        model.selectedIdentity ?? currentSpace
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: currentSpace?.symbolName ?? DefaultIdentities.fallbackSymbolName)
                .foregroundStyle(ColorHex.color(from: currentSpace?.colorHex ?? DefaultIdentities.fallbackColorHex))
                .font(.system(size: 18))
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("Spaced")
                    .font(.system(size: 15, weight: .semibold))

                Text(currentSpace?.name ?? "No Space detected")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding([.horizontal, .top], 16)
        .padding(.bottom, 8)
    }

    private var previewSection: some View {
        HUDPreviewView(identity: previewSpace)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
    }

    private var displayControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("HUD overlay", isOn: Binding(
                get: { model.settings.hudEnabled },
                set: { model.settings.hudEnabled = $0 }
            ))

            if model.settings.hudEnabled {
                HStack(spacing: 10) {
                    Text("Duration")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))

                    Slider(
                        value: Binding(
                            get: { model.settings.hudHoldDuration },
                            set: { model.settings.hudHoldDuration = $0 }
                        ),
                        in: AppSettings.hudHoldDurationRange
                    )

                    Text("\(model.settings.hudHoldDuration.formatted(.number.precision(.fractionLength(1))))s")
                        .monospacedDigit()
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
            }

            Toggle("Menu bar icon", isOn: Binding(
                get: { model.settings.menuBarIconEnabled },
                set: { model.settings.menuBarIconEnabled = $0 }
            ))

            Toggle("Launch at login", isOn: Binding(
                get: { model.launchAtLoginSnapshot.isEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))
            .disabled(!model.launchAtLoginSnapshot.isSupported)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spaced names appear in the HUD and menu bar.")
                Text(model.launchAtLoginSnapshot.isSupported
                    ? "Launch at login requires Spaced to be signed."
                    : model.launchAtLoginSnapshot.detail)
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            HStack {
                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding([.horizontal, .bottom], 12)
            .padding(.top, 10)
        }
    }
}
