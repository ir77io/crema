# Crema

A macOS menu bar app that turns the notch into a lively space: music controls, calendar, a file shelf with AirDrop, and a HUD replacement.

Crema is a fork of [Boring Notch](https://github.com/TheBoredTeam/boring.notch) by TheBoredTeam and is licensed under the **GNU GPL v3** (see `LICENSE`). Third-party licenses are in `THIRD_PARTY_LICENSES`.

## Requirements
- macOS 14 Sonoma or later

## Build
```bash
xcodebuild -project Crema.xcodeproj -scheme Crema -destination "platform=macOS" build
```

Brand assets (app icon, logos) are generated: `swift scripts/make_brand.swift`.
