# Architecture & Design Decisions

## Framework Choices

### SwiftUI (not UIKit)
- **Why**: PRD recommended SwiftUI for modern iPad development
- **Tradeoff**: Less control over low-level touch handling, but simpler code
- **Alternative considered**: UIKit would give finer gesture control

### AVAudioEngine with AVAudioUnitSampler
- **Why**: Low-latency audio is critical for responsive touch feedback (per PRD)
- **Tradeoff**: Depends on system sound fonts; may need bundled sounds
- **Fallback**: `SimpleOscillator` class implemented for sine wave generation

### UserDefaults for Storage (not Core Data)
- **Why**: Progress data is simple key-value pairs; Core Data is overkill for v1
- **Tradeoff**: No complex queries, no sync capability
- **Alternative considered**: Core Data for future cross-device sync

### Built-in Exercises + MusicXML
- **Why**: Exercises bundled for offline use; MusicXML allows external authoring
- **Tradeoff**: MusicXML parser is basic, may not handle all edge cases
- **Decision**: Parser handles grand staff with 2 voices, which is all we need

## Architecture

### MVVM Pattern
- **Views**: SwiftUI views (GrandStaffView, ExerciseView, etc.)
- **ViewModels**: ExerciseViewModel manages exercise state
- **Models**: MusicModels (Pitch, Note, etc.), Exercise, ExerciseProgress
- **Services**: AudioEngine, ProgressManager, ExerciseLoader

### Environment Objects for Global State
- `ProgressManager`: Injected at app root, available everywhere
- `AudioEngine`: Shared audio instance to avoid multiple engine conflicts

### GeometryReader for Staff Layout
- **Why**: Staff dimensions must be dynamic based on available space
- **Tradeoff**: More complex than fixed layout, but responsive to iPad orientations

## Music Theory Decisions

### Staff Position System
- Middle C (C4) = position 0
- Each step up = +1 (D4=1, E4=2, etc.)
- Negative positions for bass clef notes
- **Why**: Simplifies transposition and interval calculations

### Octave Numbering
- Using scientific pitch notation (C4 = middle C)
- MIDI note calculation: `(octave + 1) * 12 + noteIndex`

### Transposition Keys
- Limited to keys without accidentals in tonic for v1
- Circle of fourths: C, F, G, D, A, E
- **Why**: Avoids complexity of Bb, Eb, etc. for initial release

## UI/UX Decisions

### Touch Target = Treble Staff Only
- Bass notes are given; user only enters soprano
- **Why**: Simplifies interaction, matches PRD "recreate soprano" flow

### Note Auto-Removal on Incorrect
- Red note + interval shown, then fades after 2 seconds
- **Why**: PRD specifies "fades and disappears" without manual erasure

### No Explicit Undo
- User can tap same position again to replace note (if incorrect)
- **Why**: Simplifies v1; undo gesture can be added later

### Study → Practice → Review Flow
- Fixed sequence per PRD
- User must study before practicing
- **Why**: Ensures pattern is seen before recall attempt
