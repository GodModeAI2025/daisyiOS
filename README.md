# daisyiOS

Storage analyzer for iOS 27 — an iOS companion to [OpenDisk](https://github.com/137137137/OpenDisk), with a sunburst-style drill-down into what's eating your storage.

Work in progress (walking skeleton).

## What it does

- **Übersicht**: total / used / free / purgeable capacity of the device volume (matches the numbers in Settings → General → Storage).
- **Scannen**: scans the app's own data container or any folder you pick via the Files picker ("On My iPhone", iCloud Drive, USB, network) and shows a sunburst with drill-down.

Because of the iOS sandbox, whole-device scanning is not possible — the app works with the three access sources above.

## Build

Requires Xcode 26+ (iOS 27 SDK) and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open daisyiOS.xcodeproj
```

Run the `daisyiOS` scheme on a simulator or device (iOS 27).

## Structure

```
Sources/daisyiOS/
├── daisyiOSApp.swift      # App entry
├── Models/                # FileNode, VolumeInfo, ScanProgress
├── Services/              # ScanEngine (actor), VolumeStatsService, AccessStore (bookmarks)
├── Views/                 # RootView, OverviewView, ScanPickerView, SunburstChart
└── Utilities/             # Formatters
Sources/daisyiOSTests/     # Unit tests (scan engine, volume stats)
```

## Roadmap

- [x] Phase 0 — walking skeleton (this state)
- [ ] Phase 1 — storage overview polish
- [ ] Phase 2 — incremental rescans (mtime + entry-hash cache in SwiftData), parallel tuning
- [ ] Phase 3 — full sunburst port from OpenDisk (hit-testing, zoom, breadcrumb)
- [ ] Phase 4 — photo library analysis + Collector deletion
- [ ] Phase 5 — Liquid Glass polish, localization (DE/EN), App Store prep

## License

TBD
