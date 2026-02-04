# Architecture & Design Decisions

## Framework Choices

### SMuFL / Bravura Font for Music Notation
- **Why**: Industry standard for music notation; ensures cross-platform compatibility and proper rendering
- **Font**: Bravura (reference implementation for SMuFL, SIL Open Font License)
- **Specification**: https://www.smufl.org/, https://w3c.github.io/smufl/latest/
- **Tradeoff**: Requires bundling font file (~500KB), depends on font loading
- **Alternative considered**: Custom Shape drawings (used previously, but looked amateur)
- **Key codepoints used**:
  - Clefs: U+E050 (G clef), U+E062 (F clef)
  - Noteheads: U+E0A2 (whole), U+E0A3 (half), U+E0A4 (black)
  - Accidentals: U+E260 (flat), U+E262 (sharp)

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
- **Key reference positions**:
  - Treble clef bottom line: E4 = position 2
  - Bass clef bottom line: G2 = position -10 (G=4, octave 2: 4+(2-4)*7 = -10)
  - Bass clef top line: A3 = position -2 (A=5, octave 3: 5+(3-4)*7 = -2)

### Octave Numbering
- Using scientific pitch notation (C4 = middle C)
- MIDI note calculation: `(octave + 1) * 12 + noteIndex`

### Transposition Keys
- Circle of fourths includes naturals and flats: C, F, B♭, E♭, A♭, D♭, G♭/F♯, B, E, A, D, G
- Enharmonic handling for 6 accidentals

### Key Signature Application
- Key signatures are drawn using staffPosition mappings for each clef
- Playback applies key signature accidentals to diatonic notes (no per-note accidentals displayed)

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

### Interval Training Modules
- Separate cards for Perfect Consonances, Imperfect Consonances, and Dissonances
- Each exercise uses a single bass note with one target interval
- Transposition practice steps through keys for the same interval
- Intervals are diatonic to the major key (no chromatic accidentals in v1)

### Figured Bass Notation
- Shows actual intervals from bass to soprano (e.g., "8", "3", "8" for octave-third-octave)
- Calculated dynamically from transposed notes via `ExerciseViewModel.figuredBass`
- Unisons are displayed as `8` (octave) rather than `1` in figured bass
- **Why**: Helps user understand the harmonic relationship (not just melodic contour)
- **Note**: Pattern name "8-7-8" refers to soprano scale degrees, but figured bass "8-3-8" shows intervals above bass
- **Position**: Centered horizontally above each bass note, vertically between staves

### Staff Size Controls
- +/- buttons allow scaling from 0.8x to 2.0x
- Scale factor affects staff line spacing, clef sizes, note sizes proportionally
- **Why**: Accommodates different iPad sizes and user preferences for touch targets
- **Default**: 2.0x scale

### Tempo Range
- Slider range: 30-360 BPM (step: 10)
- **Why**: Higher tempos (200+ BPM) useful for advanced practice and pattern internalization
- **Default**: 215 BPM
