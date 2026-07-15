# RotaryDraw Handoff Document

**Last updated:** 2026-07-15  
**Current version:** 1.4 (build 4)  
**Status:** Production TestFlight (macOS + iOS)

## Quick Status

- ✅ Multiplatform (macOS 26.5 + iPadOS 26.0) reverse-drawing lottery app for Rotary Club events
- ✅ Unit tests (15 tests, Swift Testing framework) covering game logic and Codable compatibility
- ✅ iPad split-screen layout + external display (TV/projector) support via AppDelegate
- ✅ Session-restore alert bug fixed (no longer re-fires on tab switch)
- ✅ TestFlight automation via `./scripts/release.sh`
- ⚠️ External display mirroring not yet tested on real iPad hardware

## Project Structure

```
RotaryDraw/
├── RotaryDraw/                           # App source
│   ├── EventState.swift                  # Core game logic (@Observable)
│   ├── EventPhase.swift, EventArchive.swift, Snapshot.swift
│   ├── Ticket.swift, GuestInfo.swift
│   ├── RotaryDrawApp.swift               # Entry point (macOS Window + iOS WindowGroup)
│   ├── ContentView.swift                 # Setup/Operator routing
│   ├── SetupView.swift                   # Event config UI
│   ├── OperatorView.swift                # Draw controls + history
│   ├── AudienceView.swift                # Ticket grid / winner screens
│   ├── FinalTenView.swift                # Final Ten elimination UI
│   ├── RevealOverlay.swift               # Draw reveal modal + confetti
│   ├── ConfettiView.swift                # SpriteKit particles (NSViewRepresentable macOS / UIViewRepresentable iOS)
│   ├── PersistenceManager.swift          # File I/O (injectable for tests)
│   ├── WindowManager.swift               # macOS second NSWindow (Audience)
│   ├── ExternalDisplayManager.swift      # iOS external display UIWindow + AppDelegate
│   └── [UI views: DrawingView, BonusDrawView, etc.]
├── RotaryDrawTests/                      # Unit tests
│   ├── EventStateTests.swift             # 11 tests covering draw/elimination/split/undo
│   └── CodableCompatibilityTests.swift   # 4 tests for JSON decode compatibility
├── scripts/
│   ├── release.sh                        # Archive + TestFlight upload (macOS only; iOS uploaded separately)
│   └── ExportOptions.plist               # Export config (app-store-connect method)
├── RotaryDraw.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/RotaryDraw.xcscheme
├── CLAUDE.md                             # Development guide (xcodebuild commands, architecture, build settings)
├── .gitignore
└── HANDOFF.md                            # This file
```

## Key Architecture

### State Management
- **EventState** (@Observable singleton) injected via SwiftUI environment
- Phases: `.setup` → `.drawing` → `.finalTen` → `.bonusDraw` → `.complete`
- **PersistenceManager** handles autosave + event archives (injectable for test isolation)

### Drawing Flow
1. **Setup**: Event name, ticket count, special prizes, Final Ten threshold, bonus amount
2. **Drawing**: Random draws, Special prizes at configured positions, Not Present redraw (carryover)
3. **Final Ten**: Auto-triggers at threshold; random eliminations until Split Pot called
4. **Split Pot**: Divides pot evenly among remaining contestants (required before bonus draw)
5. **Bonus Draw**: Final grand prize draw from ALL original tickets
6. **Archive**: Permanent JSON saved to `~/Library/Application Support/RotaryDraw/Events/<name>_<timestamp>.json`

### Platform-Specific Code
- **macOS**: `WindowManager.swift` opens second `NSWindow` for Audience (full-screen if external display present, otherwise right half)
- **iOS**: 
  - `iPadRootView` shows Operator | Audience in `HStack` (split-screen, 420pt left column)
  - `ExternalDisplayManager.swift` + `AppDelegate` detects external display via `UIScreen.didConnectNotification` → mirrors Audience to separate `UIWindow`

### Persistence
- **Session**: `session.json` autosave after every action + 5-min backups (last 10 kept)
- **Guest list**: `guestlist.json` (CSV: TicketNumber, Name, SponsorLevel)
- **Event archive**: Timestamped JSON with full draw order, special prize winners, Final Ten split winners, grand winner

## Build & Release

### Local Build
```bash
# macOS debug
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project RotaryDraw.xcodeproj \
  -scheme RotaryDraw \
  -destination 'platform=macOS,arch=arm64' \
  build

# iOS Simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project RotaryDraw.xcodeproj \
  -scheme RotaryDraw \
  -destination 'generic/platform=iOS Simulator' \
  build

# Run tests
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test \
  -project RotaryDraw.xcodeproj \
  -scheme RotaryDraw \
  -destination 'platform=macOS,arch=arm64'
```

### TestFlight Upload
```bash
export APP_STORE_CONNECT_KEY_ID="S5UL2CGVYV"
export APP_STORE_CONNECT_ISSUER_ID="e3cf470c-e724-4d62-ad9b-e76cbd0b316d"
export APP_STORE_CONNECT_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_S5UL2CGVYV.p8"

# macOS (handled by script)
./scripts/release.sh 1.4

# iOS (manual for now — archive separately, then export/upload)
xcodebuild archive -project RotaryDraw.xcodeproj -scheme RotaryDraw \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/RotaryDraw-iOS.xcarchive
xcodebuild -exportArchive -archivePath build/RotaryDraw-iOS.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export-ios \
  [auth key flags...]
```

**Note**: Both platforms upload to the same app (bundle ID `com.joelconn.RotaryDraw`). Provisioning profiles bootstrapped once via Xcode Organizer → Distribute App (needed to sync server-side). After that, CLI API key works for both platforms.

## Test Suite

**Framework**: Swift Testing (`@Test`, `#expect` — not XCTest)

**Coverage** (15 tests):
- Drawing: mark drawn, ignore while revealing, special prize assignment, threshold transition
- Not Present: carryover special prize to next draw
- Final Ten: elimination stops at 1, split pot divides evenly
- Bonus: requires split done, completes event, writes archive
- Undo/Reset: state restoration
- Codable: decode compatibility for old JSON (missing bonusDrawAmount, potSplitDone, eventName)

**Key detail**: Tests use isolated temp directories (`PersistenceManager(directoryOverride:)`) — never touches real saved sessions.

**Run**:
```bash
xcodebuild test -project RotaryDraw.xcodeproj -scheme RotaryDraw \
  -destination 'platform=macOS,arch=arm64'
```

## Recent Changes (v1.4 / build 4)

### Bug Fixes
- **Session-restore alert re-firing**: Added `hasCheckedForSession` guard to `ContentView.onAppear` — alert now fires once per app lifetime, not on every view reappear
- **iPad TabView crash**: Replaced `TabView` with real split-screen `HStack` (420pt Operator | Audience); eliminated alert-spam bug as side effect

### New Features
- **External display support (iOS)**: `ExternalDisplayManager.swift` + `AppDelegate` detects connected TV/projector via `UIScreen.didConnectNotification` and mirrors Audience onto it (matching macOS two-window behavior)
- **Unit tests**: 15 tests covering game logic, undo/reset, Codable compatibility
- **PersistenceManager injection**: `EventState(persistence:)` init parameter enables test isolation

### Architecture Updates
- Split Pot mandatory gate on bonus draw
- Event naming required at setup
- Automatic timestamped event archives
- App Store compliance: `ITSAppUsesNonExemptEncryption=NO`, `UILaunchScreen_Generation=YES`, `UISupportedInterfaceOrientations` all four

## Known Limitations / Next Steps

- **iPad external display**: Logic complete; not yet tested on real iPad + TV (simulator can't fully test this path)
- **iOS release automation**: Still requires manual `xcodebuild archive` for iOS; macOS uses `./scripts/release.sh`
- **UI polish**: No dark mode support for Operator screen; Audience already has dark theme

## Important Build Settings

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types implicitly @MainActor
- `ENABLE_APP_SANDBOX = YES` → file access needs `fileImporter` or security scopes
- Deployment: macOS 26.5 (Tahoe), iOS 26.0
- Bundle ID: `com.joelconn.RotaryDraw`
- Team ID: `7K3WL7G8T4`

## Handoff Tips for Future Sessions

1. **Start here**: Read this file + CLAUDE.md for architecture and build commands
2. **Check git log**: `git log --oneline -10` for recent work
3. **Run tests first**: `xcodebuild test ...` confirms no regressions
4. **iPad testing**: External display behavior still needs real hardware verification
5. **App Store Connect**: Check https://appstoreconnect.apple.com for TestFlight builds and processing status

## Contact / Reference

- **App Store Connect API key**: Already stored at `$HOME/.appstoreconnect/private_keys/AuthKey_S5UL2CGVYV.p8` (valid, reusable for all apps under team 7K3WL7G8T4)
- **GitHub**: Not applicable (local git only, no remote)
- **Devices tested**: macOS Sonoma (arm64), iOS Simulator (iPad Pro 13-inch M5), iPhone Simulator
