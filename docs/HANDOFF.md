# Counterpoint Training App - Handoff Document

## Objective

An iPad app for learning two-part counterpoint through pattern recognition and recall, using exercises from the Italian partimenti tradition. Users study soprano patterns over bass lines, then recreate them from memory with immediate feedback.

## What Is Working Right Now

- Complete SwiftUI project structure targeting iPad (iOS 17+)
- Grand staff notation renderer with treble/bass clefs
- 7 built-in exercises across 2 basslines (1-5-1 and 1-2-3-4-5-6-5-1)
- Touch input with note snapping to staff lines/spaces
- Audio engine for playback and touch feedback (AVAudioEngine + sampler)
- Study/Practice/Review exercise flow
- Correct (green) / Incorrect (red + interval) feedback with auto-fade
- Transposition through circle of fourths (C, F, G, D, A, E major)
- Local progress storage via UserDefaults
- Spaced repetition quiz system with interval-based scheduling
- MusicXML parser for importing external exercises
- 2 sample MusicXML exercise files

## Build & Run Commands

```bash
# Navigate to project
cd Counterpoint

# Open in Xcode (macOS only)
open Counterpoint.xcodeproj

# Build via command line (requires Xcode)
xcodebuild -project Counterpoint.xcodeproj -scheme Counterpoint -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' build

# Run tests (when tests are added)
xcodebuild -project Counterpoint.xcodeproj -scheme Counterpoint -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' test
```

## Project Structure

```
counterpoint-ipad-app/
├── counterpoint-app-prd.md          # Product requirements document
├── docs/                            # Handoff documentation
└── Counterpoint/                    # Xcode project
    ├── Counterpoint.xcodeproj/      # Xcode project file
    └── Counterpoint/
        ├── CounterpointApp.swift    # @main entry point
        ├── ContentView.swift        # Root view container
        ├── Models/
        │   ├── MusicModels.swift    # Pitch, Key, Note, Voice, Interval
        │   └── Exercise.swift       # Exercise, ExerciseProgress, ExerciseAttempt
        ├── Views/
        │   ├── GrandStaffView.swift       # Staff notation rendering
        │   ├── ExerciseView.swift         # Main practice screen
        │   ├── ExerciseSelectionView.swift # Exercise browser
        │   └── QuizView.swift             # Spaced repetition quizzes
        ├── ViewModels/
        │   └── ExerciseViewModel.swift    # Exercise state & logic
        ├── Services/
        │   ├── AudioEngine.swift          # Sound playback
        │   ├── ExerciseLoader.swift       # Load exercises (built-in + XML)
        │   ├── MusicXMLParser.swift       # Parse MusicXML files
        │   └── ProgressManager.swift      # Progress & spaced repetition
        └── Resources/
            ├── Assets.xcassets/           # App icons, colors
            └── Exercises/                 # MusicXML files
                ├── bassline1_878.musicxml
                └── bassline2_contrary.musicxml
```

## Next 3 Tasks (In Order)

1. **Test on actual iPad simulator** - Open project in Xcode, build for iPad simulator, verify touch input works correctly and notes snap to proper positions
2. **Add sound font or fallback audio** - Current audio depends on system DLS; bundle a simple sound font or implement sine wave fallback for consistent audio
3. **Add unit tests for core models** - Test `Pitch.fromStaffPosition()`, `Interval.between()`, transposition logic, and MusicXML parsing

## Where to Start Reading Code

1. **Entry point**: `CounterpointApp.swift` → creates `ProgressManager` and `AudioEngine` as environment objects
2. **Main flow**: `ContentView.swift` → shows either `ExerciseSelectionView` or `ExerciseView`
3. **Core interaction**: `ExerciseView.swift` + `ExerciseViewModel.swift` → handles study/practice/review flow
4. **Notation rendering**: `GrandStaffView.swift` → draws staff lines, clefs, notes, handles touch input
5. **Data models**: `MusicModels.swift` → understand `Pitch`, `Note`, `Voice`, `Interval` before modifying anything
