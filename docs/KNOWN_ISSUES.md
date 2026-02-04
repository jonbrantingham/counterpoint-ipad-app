# Known Issues & Incomplete Items

## Fixed in Session 2

- [x] **Build errors** - AudioEngine had incorrect method call for loading sound bank
- [x] **Blank screen on launch** - @Published property mutation during view body evaluation
- [x] **Musical symbols not rendering** - Unicode glyphs replaced with custom Shape drawings
- [x] **X button not working** - Changed from dismiss() to callback pattern
- [x] **Audio timing issues** - Rewrote playback scheduler
- [x] **Circle of fourths incorrect** - Now includes all 12 keys with proper order

## Remaining Issues

### Audio
- [ ] No tempo control UI exposed (backend support added, needs UI slider)
- [ ] Sound can be abrupt (no attack/release envelope on triangle wave)
- [ ] iOS Simulator audio warnings (EcammAudioLoader, HALC_ProxyIOContext) are normal and don't affect functionality

### Notation Rendering
- [ ] Ledger line logic may be incorrect for extreme pitches
- [ ] Key signature only shows key name text, not proper sharps/flats on staff
- [ ] No accidentals display (all notes assumed diatonic to key)
- [ ] Clef shapes are simplified approximations

### Touch Input
- [ ] No undo gesture for placed notes
- [ ] Cannot erase/replace correct notes (only incorrect ones fade)
- [ ] Touch target area may need adjustment for different iPad sizes
- [ ] Y-position to pitch calculation accuracy not fully tested

### Exercises
- [ ] Only 7 exercises total (4 for bassline 1, 3 for bassline 2)
- [ ] MusicXML files not automatically discovered from bundle
- [ ] No exercise metadata validation

### Progress & Quizzes
- [ ] Spaced repetition algorithm is basic (fixed intervals, not adaptive)
- [ ] Quiz key selection is random from completed keys, may repeat
- [ ] No way to manually trigger quiz or skip exercises

### UI/UX
- [ ] No app icon designed (placeholder in asset catalog)
- [ ] No onboarding or tutorial
- [ ] No settings screen
- [ ] No tempo control slider in UI
- [ ] No enharmonic toggle button (e.g., G♭ ↔ F♯)
- [ ] Completion overlay may overlap with controls on smaller iPads

## Potential Bugs

1. **ExerciseViewModel audio dependency** - Creates its own `AudioEngine` instance instead of using environment object; may cause audio conflicts
2. **Transposition calculation** - Simple interval math may not handle all key signatures correctly
3. **Beat position tracking** - MusicXML parser resets beat position per measure but doesn't track measure numbers
4. **Memory leak risk** - Timer references in `ExerciseViewModel.fadeTimers` may not be cleaned up properly

## Technical Debt

- No unit tests
- No UI tests
- No SwiftLint or code formatting
- Some views have `#Preview` but not all edge cases covered
- Error handling is minimal (many `guard` statements just return silently)

## Out of Scope for v1 (per PRD)

- Second species and beyond (2:1, 4:1, etc.)
- Minor keys
- C clefs (alto, tenor)
- Voice/pitch recognition
- Cross-device sync
- Content authoring tools
- Stylistic feedback (hidden fifths, etc.)

## Console Warnings (Ignorable)

These warnings appear in the Xcode console but don't affect app functionality:

```
AddInstanceForFactory: No factory registered for id...
Error loading /Library/Audio/Plug-Ins/HAL/EcammAudioLoader.plugin...
HALC_ProxyIOContext.cpp: skipping cycle due to overload
Could not get trait set for device iPad14,5 with version 17.2
```

These are related to macOS audio plugins not being compatible with iOS simulator and missing device trait sets in older Xcode versions.
