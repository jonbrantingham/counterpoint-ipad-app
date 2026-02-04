# Progress Log

## Session 8 - Chromatic Interval Lessons (2026-02-04)

### Added
- [x] **Accidental input + rendering** - Added accidental picker and note accidentals (flat/natural/sharp) for practice
- [x] **Advanced chromatic interval lessons** - Added chromatic lessons within each interval module (shown under Advanced)

## Session 9 - Build Fix (2026-02-04)

### Fixed Issues
- [x] **GrandStaffView argument order** - Fixed initializer argument order to match Swift's expected parameter sequence

## Session 10 - Build Fix (2026-02-04)

### Fixed Issues
- [x] **GrandStaffView argument order (scale/hintNote)** - Reordered arguments to satisfy Swift parameter ordering

## Session 7 - Interval Modules (2026-02-04)

### Added
- [x] **Interval training modules** - Added Perfect Consonances, Imperfect Consonances, and Dissonances cards
- [x] **Single-note interval exercises** - Each interval is a one-bass-note exercise with key transposition practice

## Session 6 - UX Defaults and Transposition Hint (2026-02-04)

### Fixed Issues
- [x] **Largest staff size default + larger sizes** - Staff size now defaults to the largest setting with additional size steps
- [x] **Default tempo set to 215 BPM** - Playback defaults to a faster practice tempo
- [x] **Next-key starting note hint** - Advancing keys shows the starting soprano note in light gray during practice

## Session 5 - Transposition Practice Flow (2026-02-04)

### Fixed Issues
- [x] **Next key now starts in practice mode** - Advancing to the next key hides the soprano so transposition is recalled from memory

## Session 2 - Bug Fixes and Improvements (2024-02-04)

### Fixed Issues
- [x] **AudioEngine compilation error** - Fixed `loadSoundBankInstrument` method call that had incorrect parameters
- [x] **Blank screen on launch** - Fixed `@Published` property being modified during view body evaluation in `ProgressManager.shouldShowQuiz()`
- [x] **Music notation rendering** - Unicode musical symbols weren't displaying (showing as ? boxes). Replaced with custom SwiftUI Shape drawings for:
  - Treble clef (TrebleClefShape)
  - Bass clef (BassClefShape)
  - Whole notes (WholeNoteShape)
- [x] **Back/dismiss navigation** - X button wasn't working because `dismiss()` was used outside of modal presentation. Added `onDismiss` callback parameter
- [x] **Playback timing** - Notes were playing simultaneously instead of sequentially. Rewrote playback scheduling using `DispatchWorkItem` with proper time offsets
- [x] **Triangle wave synthesizer** - Replaced organ/sampler with custom triangle wave synthesis using `AVAudioSourceNode`
- [x] **Circle of fourths** - Updated to correct progression: C-F-B♭-E♭-A♭-D♭-G♭-B-E-A-D-G
- [x] **Enharmonic key support** - Added `Accidental` enum (natural, sharp, flat) and `enharmonicEquivalent()` method
- [x] **Tempo control** - Added `setTempo()` method to AudioEngine with clamping (30-240 BPM)
- [x] **Key display** - Added `displayName` and `shortName` computed properties to Key struct

### Architecture Changes
- AudioEngine now uses pure triangle wave synthesis instead of AVAudioUnitSampler
- ProgressManager now has `refreshQuizQueue()` method to separate state mutation from body evaluation
- GrandStaffView uses custom Shape structs instead of Unicode characters
- Key struct now includes `accidental` property for flat/sharp keys

---

## Session 1 - Initial Implementation

### Completed

- [x] Created complete Xcode project structure for iPad app
- [x] Implemented core music models (Pitch, Key, Note, Voice, Interval)
- [x] Built MusicXML parser for importing exercises
- [x] Created ExerciseLoader with 7 built-in exercises
- [x] Implemented GrandStaffView notation renderer
  - Treble and bass clef display
  - Note heads with ledger lines
  - Key signature display
  - Touch input with pitch detection
- [x] Built AudioEngine for playback
  - Exercise playback (both voices)
  - Touch feedback (plays interval)
  - Correct/incorrect sound feedback
- [x] Implemented exercise flow in ExerciseView
  - Study phase (view complete exercise)
  - Practice phase (recreate soprano from memory)
  - Review phase (completion summary)
- [x] Added correct/incorrect feedback system
  - Green highlight for correct notes
  - Red highlight + interval display for incorrect
  - Auto-fade and removal after 2 seconds
- [x] Implemented transposition practice
  - Circle of fourths key progression (now with all 12 keys)
  - Key selector in UI
- [x] Created ProgressManager for local storage
  - Exercise completion tracking
  - Accuracy recording
  - Mastery levels (0-5)
- [x] Implemented spaced repetition quiz system
  - Interval-based scheduling (1, 3, 7, 14, 30, 60 days)
  - Quiz prompt between exercises
  - QuizView for review sessions
- [x] Built exercise selection UI
  - Bassline cards with progress
  - Exercise list with mastery indicators
  - Overall progress summary
- [x] Created 2 sample MusicXML exercise files
- [x] Set up Xcode project configuration (pbxproj)
- [x] Created asset catalog structure

## Next Up

1. Add tempo control UI (slider or stepper)
2. Add button to switch enharmonic key spelling (G♭ ↔ F♯)
3. Verify touch input accuracy on iPad simulator
4. Add unit tests for core models
5. Add more exercises for both basslines
6. Add undo gesture for placed notes
7. Test on physical iPad device
