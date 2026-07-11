# AppClaw

A lightweight macOS menu bar utility that catches the leftover files an app
leaves behind when you delete it. When you drag an application to the Trash,
AppClaw detects it, searches the system for the app's related support files
(preferences, caches, containers, application support, logs), and offers to
move them to the Trash as well.

Built for Apple Silicon (and Intel) Macs running **macOS 13 Ventura or later**.

## Features

- Runs quietly in the background as a menu bar item (no Dock icon, no window).
- Launches automatically at login (via `SMAppService`).
- Watches the Trash with FSEvents and reacts as soon as an app is trashed.
- Lets you pick exactly which leftover files to remove before deleting.
- No auto-updater, no telemetry, no third-party dependencies.

## Requirements

- macOS 13.0+
- Xcode 15 or later

## Building

1. Open the project:
   ```bash
   open AppClaw/AppClaw.xcodeproj
   ```
2. Select the **AppClaw** scheme and **My Mac**, then Build & Run (⌘R).
3. In **Signing & Capabilities**, pick your team (a free personal Apple ID
   works) so the app gets a stable signature — this keeps its Full Disk
   Access grant across rebuilds.

The built product is `AppClaw.app`. For daily use, copy it to
`/Applications` and launch it from there.

## Permissions

On first launch AppClaw asks for **Full Disk Access**, which it needs to find
support files in protected Library locations. Enable it under
**System Settings → Privacy & Security → Full Disk Access**, then relaunch.

## Icons

App and menu bar icons live in `AppClaw/Assets.xcassets`. To regenerate every
required size from two source PNGs (a 1024×1024 app icon and a monochrome
menu bar glyph):

```bash
./Scripts/generate-icons.sh path/to/appicon.png path/to/menubar.png
```

## License

See [LICENSE](LICENSE).
