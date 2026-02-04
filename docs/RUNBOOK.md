# Runbook

## Prerequisites

- macOS with Xcode 15.0 or later
- iPad Simulator (iOS 17.0+) or physical iPad device
- Apple Developer account (for device testing)

## Setup

```bash
# Clone/copy the project
cd counterpoint-ipad-app/Counterpoint

# Open in Xcode
open Counterpoint.xcodeproj
```

No external dependencies - pure Swift/SwiftUI project.

## Run

### In Xcode (Recommended)
1. Open `Counterpoint.xcodeproj`
2. Select target device: iPad Pro (12.9-inch) simulator or connected iPad
3. Press `Cmd+R` or click Run button

### Command Line
```bash
# Build only
xcodebuild -project Counterpoint.xcodeproj \
  -scheme Counterpoint \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' \
  build

# Build and run in simulator
xcodebuild -project Counterpoint.xcodeproj \
  -scheme Counterpoint \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' \
  build

# Then launch simulator manually
xcrun simctl boot "iPad Pro (12.9-inch)"
xcrun simctl install booted ./build/Debug-iphonesimulator/Counterpoint.app
xcrun simctl launch booted com.counterpoint.training
```

## Test

```bash
# Run unit tests (when added)
xcodebuild -project Counterpoint.xcodeproj \
  -scheme Counterpoint \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' \
  test
```

**Manual Testing Checklist:**
- [ ] App launches without crash
- [ ] Exercise selection screen shows 2 basslines
- [ ] Tapping exercise opens ExerciseView
- [ ] Staff renders correctly (treble + bass clefs, 5 lines each)
- [ ] Play button produces audio
- [ ] Practice button hides soprano
- [ ] Tapping staff places notes that snap to lines/spaces
- [ ] Correct notes turn green
- [ ] Incorrect notes turn red, show interval, then fade
- [ ] Key selector changes transposition
- [ ] Progress persists after app restart

## Build for Release

```bash
# Archive for App Store
xcodebuild -project Counterpoint.xcodeproj \
  -scheme Counterpoint \
  -destination generic/platform=iOS \
  -archivePath ./Counterpoint.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./Counterpoint.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build
```

Note: Requires valid signing identity and provisioning profile.

## Troubleshoot

### Build Errors

**"No such module 'SwiftUI'"**
- Ensure deployment target is iOS 17.0+
- Check Xcode version is 15.0+

**Signing errors**
- Open project in Xcode
- Go to Signing & Capabilities
- Set Team to your Apple Developer account or "None" for simulator-only

### Runtime Issues

**No audio**
- Check device/simulator is not muted
- Audio engine may fail to load DLS instruments on some simulators
- Fallback: SimpleOscillator class exists but needs integration

**Touch not registering**
- Verify tapping in treble staff area (upper staff)
- Check console for tap coordinate logs
- Touch overlay may need geometry adjustment

**Progress not saving**
- UserDefaults may be sandboxed differently in simulator
- Check `progressKey` and `quizQueueKey` in ProgressManager

### Reset App State

```swift
// Add to any view for testing
Button("Reset Progress") {
    progressManager.resetAllProgress()
}
```

Or delete app from simulator and reinstall.
