# Spaced

**Make macOS Spaces feel designed.**

Spaced gives every macOS Space a visual identity: a name, a color, an SF Symbol,
and a clean Liquid Glass HUD that appears when you switch desktops.

It is the missing aesthetic layer for Spaces. Not a window manager. Not a
workspace automation tool. Just a small native Mac app that makes switching
desktops feel intentional.

## Why Spaced?

macOS Spaces are powerful, but they all look the same. Spaced makes them easier
to recognize at a glance:

- **Name each Space** for how you use it: Design, Code, Focus, Chat, Music.
- **Give each Space a color and icon** so it has a visual personality.
- **See a brief HUD when you switch** instead of guessing where you landed.
- **Keep an optional menu bar icon** that reflects the current Space.

Spaced is built to sit alongside the tools you already use. It does not replace
FlashSpace, Spaceman, WhichSpace, SpaceCommand, yabai, or spaces-renamer.

## What Spaced Does

- Shows a native macOS 26 Liquid Glass overlay when you switch Spaces.
- Lets you customize each detected Space with a name, color, and SF Symbol.
- Shows a compact settings popover from the menu bar.
- Can hide its menu bar icon if you already use another Space indicator.
- Supports launch at login.
- Auto-discovers Spaces as you visit them.
- Does not require disabling SIP.

## What Spaced Does Not Do

Spaced is deliberately not a Space manager.

- It does not switch Spaces for you.
- It does not assign apps to Spaces.
- It does not move or tile windows.
- It does not intercept keyboard shortcuts.
- It does not rename Mission Control's built-in "Desktop 1" labels.

Spaced names are local to Spaced. They appear in Spaced's HUD, menu bar popover, and
settings panel. Mission Control labels remain controlled by macOS.

## Requirements

- macOS 26 Tahoe or later
- Xcode 26 or later to build from source

Spaced targets macOS 26 because it uses native SwiftUI Liquid Glass APIs such as
`glassEffect` and `GlassEffectContainer`.

## Build and Run

Spaced is currently published as source while the app is still early. To try it,
clone the repository and run:

```bash
swift test
./script/build_and_run.sh
```

The run script stages a local app bundle at `dist/Spaced.app` and launches that
bundle instead of running the SwiftPM binary directly.

Useful commands:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --debug
```

## How Space Detection Works

Spaced listens for
[`NSWorkspace.activeSpaceDidChangeNotification`](https://developer.apple.com/documentation/appkit/nsworkspace/activespacedidchangenotification),
which is public and does not require SIP changes.

To identify the current Space, Spaced uses the minimal private CoreGraphics
symbols `CGSMainConnectionID` and `CGSGetActiveSpace`. The returned Space ID is
stable during a login session but can reset after reboot.

Spaced intentionally does not use private APIs to enumerate every Mission Control
Space. On first launch it knows the current Space; additional Spaces are added
as you visit them.

## Privacy and Safety

Spaced is local-only. It does not send your Space names, colors, icons, or usage
data anywhere.

Spaced also avoids invasive Space customization techniques. It does not inject
into Dock or Mission Control, does not install SIMBL or MacForge plugins, does
not run `defaults write` hacks, and does not require disabling SIP.

## Project Status

Spaced is early and intentionally focused. The core idea is working, but the app
will improve over time through real use:

- better defaults
- richer icon choices
- smoother onboarding
- packaged downloads
- visual polish
- compatibility notes for future macOS updates

If you try Spaced and something feels off, open an issue. Small workflow details
matter for a tool that lives in your menu bar all day.

## Contributing

Contributions are welcome. Good first areas:

- testing on different multi-monitor setups
- improving the settings popover
- expanding the curated SF Symbol list
- polishing README screenshots or demo clips
- tightening launch-at-login and packaging behavior

Please keep Spaced's scope narrow: it is a visual identity layer for Spaces, not
a workspace manager.

## References

- [`NSWorkspace.activeSpaceDidChangeNotification`](https://developer.apple.com/documentation/appkit/nsworkspace/activespacedidchangenotification)
- [`glassEffect(_:in:)`](https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29)
- [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [`SMAppService.mainApp`](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)
- [`SMAppService.register()`](https://developer.apple.com/documentation/servicemanagement/smappservice/register%28%29)

## License

MIT
