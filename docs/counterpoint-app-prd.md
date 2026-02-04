# Counterpoint Training App PRD

## 1. Product Overview and Vision

A focused iPad application for learning two-part counterpoint through pattern recognition, memorization, and recall. The app presents contrapuntal exercises drawn from the Italian partimenti tradition (Durante, Fenaroli) and trains users to internalize these patterns through active engagement: seeing, copying, playing, and transposing.

The core insight driving this product is that counterpoint becomes intuitive through repeated, hands-on engagement with the same basslines across multiple soprano solutions and species progressions. Existing counterpoint apps miss this by treating exercises as isolated problems rather than interconnected patterns to be memorized and recalled.

The app is not a notation program. It prioritizes fluency and feel over precision editing.

## 2. Target User

Musicians who want to internalize the foundations of counterpoint, likely with some basic music theory knowledge (intervals, scales, clefs). They may be composers, arrangers, or instrumentalists who want deeper fluency in voice leading. They are willing to practice deliberately and value mastery over quick results.

## 3. Core User Flow

1. **See the pattern**: User views a complete exercise (bass and soprano) on a grand staff
2. **Study**: User can play the exercise back, listen to the intervals, observe the voice leading
3. **Hide**: User hides the soprano line
4. **Recreate**: User touches the staff to place notes from memory
5. **Feedback**: App shows which notes are correct (green) or incorrect (red with interval shown), incorrect notes fade after a few seconds
6. **Review**: Upon completion, app shows analysis with suggestions if needed
7. **Transpose**: User practices the same pattern in new keys (circle of fourths progression)
8. **Progress**: Move to next soprano pattern over the same bass, or advance to next species/bassline
9. **Quiz**: Periodic spaced repetition quizzes prompt recall of previously learned patterns

## 4. MVP Feature Set

### Included in v1

- Grand staff display, centered on screen, notation as large as comfortably fits
- Bass clef for bottom line, treble clef for top line
- Two basslines: 1-5-1 and 1-2-3-4-5-6-5-1
- Multiple soprano solutions per bassline
- First species (1:1) counterpoint only
- Major keys only (starting in C major)
- Key signature display
- Touch input to place notes with snapping to nearest line/space
- Audio playback of exercises (simple, pleasant synth: sine/triangle wave or organ-like)
- Audio feedback on touch: plays the touched note plus the bass note simultaneously
- Hide/reveal soprano line
- Correct/incorrect feedback (green/red), incorrect notes show interval and fade after a few seconds
- Transposition practice (circle of fourths)
- Linear progression through exercises
- Local progress storage
- Basic spaced repetition: periodic quizzes between exercises to reinforce previously learned patterns
- MusicXML import for exercise content (bundled with app, created externally in Sibelius)

### Not in v1 (future considerations)

- Species beyond first (2:1, 4:1, free counterpoint)
- Minor keys
- C clefs
- Additional basslines beyond the initial two
- Voice/pitch recognition for singing along
- Cross-device sync
- Content authoring tools within the app
- App Store release and paid content expansions
- Stylistic feedback (orange states for technically legal but stylistically questionable choices)

## 5. Content Structure

### Basslines

Exercises are organized around basslines. Users complete all soprano patterns and species for one bassline before advancing to the next.

**v1 Basslines:**
- Bassline 1: 1-5-1 (C-G-C in C major)
- Bassline 2: 1-2-3-4-5-6-5-1 (C-D-E-F-G-A-G-C in C major)

### Soprano Patterns

Each bassline has multiple soprano solutions demonstrating different intervallic relationships. Examples for 1-5-1: 8-7-8, 5-4-3, 5-5-5, 3-2-3, etc.

### Species Progression

For each bassline, users progress through species in order (v1 is first species only):
1. First species (1:1)
2. Second species (2:1) - future
3. Fourth species (syncopation) - future
4. Free counterpoint - future

This structure reveals the relationship between species and builds understanding progressively.

### Data Format

Exercises will be authored in Sibelius and exported as MusicXML. The app will parse and display these files. Each exercise file contains:
- Bass line
- One or more valid soprano solutions
- Metadata: species type, bassline identifier, pattern name

## 6. Interaction Design

### Display

- Grand staff centered on iPad screen
- Notation sized as large as comfortably fits for touch interaction
- Key signature shown
- Clean, minimal interface; the music is the focus

### Touch Input

- Tap on staff to place a note
- Snapping: notes snap to nearest line or space
- Note duration determined automatically based on species and beat position
- No duration shorter than eighth notes
- For v1 (first species), all notes are whole notes, simplifying input

### Audio

- Playback sound: pleasant, peaceful timbre (sine/triangle wave or simple organ)
- On touch: immediately plays the placed pitch plus the corresponding bass note, so user hears the interval
- Full playback: plays entire exercise, both voices together
- Tempo control would be useful but not required for v1

### Error States

- Correct note: highlighted green
- Incorrect note: highlighted red, shows the interval, fades and disappears after a few seconds
- This provides quick reinforcement without requiring manual erasure

### Gestures

- Tap: place note
- Additional gestures (erase, undo) can be added as needed during development

## 7. Progression and Mastery System

### Linear Curriculum

Users progress through exercises in a fixed order:
1. Complete all soprano patterns for Bassline 1, first species
2. Complete all soprano patterns for Bassline 2, first species
3. (Future: progress to second species, repeating basslines)

### Transposition Practice

After successfully recreating a pattern in C major:
- App presents the same pattern transposed (circle of fourths: C, F, Bb, Eb, etc.)
- User recreates from memory in the new key
- Hints available: can reveal the transposed solution temporarily, then hide again

### Spaced Repetition

- App tracks mastery per exercise
- Periodic quizzes appear between new exercises
- Quizzes ask user to fill in a previously learned pattern from memory
- Quizzes may present patterns in the original key or transposed
- Specific algorithm TBD; could use a simple interval-based system (quiz after 1 day, 3 days, 7 days, etc.)

### Progress Tracking

- Local storage on iPad
- Tracks: exercises completed, accuracy, last practiced date, mastery level per pattern

## 8. Technical Considerations

### Platform

- iPad only for v1
- Native app (Swift/SwiftUI recommended for best touch interaction and audio performance)

### Data Storage

- Local storage (Core Data or similar)
- Exercise content bundled with app
- Progress data stored locally

### Audio

- Low-latency audio essential for responsive touch feedback
- Simple synthesis or sampled sounds
- AVAudioEngine or similar framework

### MusicXML Parsing

- App must parse MusicXML files to extract:
  - Note pitches and durations
  - Clefs and key signatures
  - Staff assignments (which notes belong to bass vs soprano)
- Libraries exist for MusicXML parsing in Swift; evaluate options during development

### Content Bundling

- Exercise files bundled in app package
- Future versions could support downloading additional content packs

## 9. Future Considerations

These are noted for context but explicitly out of scope for v1:

- **Additional species**: 2:1, 4:1, syncopation, free counterpoint
- **Minor keys**: Adds accidentals, different intervallic patterns
- **More basslines**: Expanding the curriculum with progressively complex basses
- **C clefs**: Alto, tenor clefs for historical authenticity
- **Voice recognition**: Sing along with solfege, app recognizes pitch and syllables
- **Play along**: Piano/keyboard input recognition
- **Cross-device sync**: iCloud or account-based progress sync
- **App Store release**: Paid app or freemium with content packs
- **Hexachordal solfege**: Support for the historical system (ut-re-mi-fa-sol-la only)
- **Content authoring**: In-app tools for creating exercises
- **Stylistic feedback**: Orange states for technically correct but stylistically questionable choices (hidden fifths, direct motion to perfect consonances, etc.)
