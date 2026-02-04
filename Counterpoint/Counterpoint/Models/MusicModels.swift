//
//  MusicModels.swift
//  Counterpoint
//
//  Core music theory models for the counterpoint app
//

import Foundation

// MARK: - Pitch

/// Represents a musical pitch with note name and octave
struct Pitch: Equatable, Hashable, Codable {
    let noteName: NoteName
    let octave: Int

    /// MIDI note number (C4 = 60)
    var midiNote: Int {
        let baseNote: Int
        switch noteName {
        case .c: baseNote = 0
        case .d: baseNote = 2
        case .e: baseNote = 4
        case .f: baseNote = 5
        case .g: baseNote = 7
        case .a: baseNote = 9
        case .b: baseNote = 11
        }
        return baseNote + (octave + 1) * 12
    }

    /// MIDI note number adjusted for key signature accidentals
    func midiNote(in key: Key) -> Int {
        let accidental = key.accidental(for: noteName)
        return midiNote + accidental.semitoneOffset
    }

    /// Staff position relative to middle C (C4 = 0, D4 = 1, etc.)
    var staffPosition: Int {
        let noteIndex: Int
        switch noteName {
        case .c: noteIndex = 0
        case .d: noteIndex = 1
        case .e: noteIndex = 2
        case .f: noteIndex = 3
        case .g: noteIndex = 4
        case .a: noteIndex = 5
        case .b: noteIndex = 6
        }
        return noteIndex + (octave - 4) * 7
    }

    /// Create pitch from staff position (relative to middle C)
    static func fromStaffPosition(_ position: Int) -> Pitch {
        let octaveOffset = position >= 0 ? position / 7 : (position - 6) / 7
        var noteIndex = position % 7
        if noteIndex < 0 { noteIndex += 7 }

        let noteName: NoteName
        switch noteIndex {
        case 0: noteName = .c
        case 1: noteName = .d
        case 2: noteName = .e
        case 3: noteName = .f
        case 4: noteName = .g
        case 5: noteName = .a
        case 6: noteName = .b
        default: noteName = .c
        }

        return Pitch(noteName: noteName, octave: 4 + octaveOffset)
    }

    /// Transpose by a number of scale degrees in a given key
    func transposed(by interval: Int, in key: Key) -> Pitch {
        let newPosition = staffPosition + interval
        let newPitch = Pitch.fromStaffPosition(newPosition)

        // Apply key signature accidentals
        // For major keys, this is handled by the key's scale degrees
        return newPitch
    }
}

/// Note name without accidental
enum NoteName: String, Codable, CaseIterable {
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case a = "A"
    case b = "B"
}

/// Accidental type
enum Accidental: String, Codable {
    case natural = ""
    case sharp = "♯"
    case flat = "♭"

    var displayString: String {
        switch self {
        case .natural: return ""
        case .sharp: return "♯"
        case .flat: return "♭"
        }
    }

    /// Semitone offset
    var semitoneOffset: Int {
        switch self {
        case .natural: return 0
        case .sharp: return 1
        case .flat: return -1
        }
    }
}

// MARK: - Key

/// Represents a musical key with support for accidentals
struct Key: Equatable, Codable {
    let tonic: NoteName
    let accidental: Accidental
    let mode: Mode

    enum Mode: String, Codable {
        case major
        case minor
    }

    init(tonic: NoteName, accidental: Accidental = .natural, mode: Mode = .major) {
        self.tonic = tonic
        self.accidental = accidental
        self.mode = mode
    }

    /// Display name like "C major" or "B♭ major"
    var displayName: String {
        "\(tonic.rawValue)\(accidental.displayString) \(mode.rawValue)"
    }

    /// Short display name like "C" or "B♭"
    var shortName: String {
        "\(tonic.rawValue)\(accidental.displayString)"
    }

    /// Number of sharps (positive) or flats (negative) in the key signature
    var fifths: Int {
        switch (tonic, accidental, mode) {
        // Major keys
        case (.c, .natural, .major): return 0
        case (.g, .natural, .major): return 1
        case (.d, .natural, .major): return 2
        case (.a, .natural, .major): return 3
        case (.e, .natural, .major): return 4
        case (.b, .natural, .major): return 5
        case (.f, .sharp, .major), (.g, .flat, .major): return 6  // Enharmonic
        case (.c, .sharp, .major), (.d, .flat, .major): return 7  // Enharmonic (theoretical)
        case (.f, .natural, .major): return -1
        case (.b, .flat, .major): return -2
        case (.e, .flat, .major): return -3
        case (.a, .flat, .major): return -4
        case (.d, .flat, .major): return -5
        case (.g, .flat, .major): return -6
        case (.c, .flat, .major): return -7  // Theoretical
        // Minor keys
        case (.a, .natural, .minor): return 0
        case (.e, .natural, .minor): return 1
        case (.b, .natural, .minor): return 2
        case (.f, .sharp, .minor): return 3
        case (.c, .sharp, .minor): return 4
        case (.g, .sharp, .minor): return 5
        case (.d, .natural, .minor): return -1
        case (.g, .natural, .minor): return -2
        case (.c, .natural, .minor): return -3
        case (.f, .natural, .minor): return -4
        case (.b, .flat, .minor): return -5
        case (.e, .flat, .minor): return -6
        default: return 0
        }
    }

    /// Key signature accidental for a given note name (diatonic only)
    func accidental(for noteName: NoteName) -> Accidental {
        let sharpOrder: [NoteName] = [.f, .c, .g, .d, .a, .e, .b]
        let flatOrder: [NoteName] = [.b, .e, .a, .d, .g, .c, .f]

        if fifths > 0 {
            return sharpOrder.prefix(fifths).contains(noteName) ? .sharp : .natural
        }
        if fifths < 0 {
            return flatOrder.prefix(-fifths).contains(noteName) ? .flat : .natural
        }
        return .natural
    }

    /// Circle of fourths: C-F-B♭-E♭-A♭-D♭-G♭/F♯-B-E-A-D-G
    static let circleOfFourths: [Key] = [
        Key(tonic: .c, accidental: .natural, mode: .major),
        Key(tonic: .f, accidental: .natural, mode: .major),
        Key(tonic: .b, accidental: .flat, mode: .major),
        Key(tonic: .e, accidental: .flat, mode: .major),
        Key(tonic: .a, accidental: .flat, mode: .major),
        Key(tonic: .d, accidental: .flat, mode: .major),
        Key(tonic: .g, accidental: .flat, mode: .major),  // or F♯
        Key(tonic: .b, accidental: .natural, mode: .major),
        Key(tonic: .e, accidental: .natural, mode: .major),
        Key(tonic: .a, accidental: .natural, mode: .major),
        Key(tonic: .d, accidental: .natural, mode: .major),
        Key(tonic: .g, accidental: .natural, mode: .major),
    ]

    /// Enharmonic equivalents for keys with 6 sharps/flats
    static let enharmonicPairs: [(Key, Key)] = [
        (Key(tonic: .g, accidental: .flat, mode: .major), Key(tonic: .f, accidental: .sharp, mode: .major)),
        (Key(tonic: .d, accidental: .flat, mode: .major), Key(tonic: .c, accidental: .sharp, mode: .major)),
    ]

    /// Get enharmonic equivalent if one exists
    func enharmonicEquivalent() -> Key? {
        for (key1, key2) in Key.enharmonicPairs {
            if self == key1 { return key2 }
            if self == key2 { return key1 }
        }
        return nil
    }

    static let cMajor = Key(tonic: .c, accidental: .natural, mode: .major)
}

// MARK: - Note

/// A note with pitch and duration
struct Note: Equatable, Codable, Identifiable {
    let id: UUID
    let pitch: Pitch
    let duration: NoteDuration
    let beatPosition: Double  // Position in beats from start of measure

    init(id: UUID = UUID(), pitch: Pitch, duration: NoteDuration, beatPosition: Double = 0) {
        self.id = id
        self.pitch = pitch
        self.duration = duration
        self.beatPosition = beatPosition
    }
}

enum NoteDuration: Double, Codable {
    case whole = 4.0
    case half = 2.0
    case quarter = 1.0
    case eighth = 0.5

    var beats: Double { rawValue }
}

// MARK: - Voice

/// A melodic line (soprano or bass)
struct Voice: Codable {
    var notes: [Note]

    var duration: Double {
        notes.reduce(0) { $0 + $1.duration.beats }
    }
}

// MARK: - Interval

/// Interval between two pitches
struct Interval {
    let semitones: Int
    let quality: Quality
    let size: Int  // 1 = unison, 2 = second, etc.

    enum Quality: String {
        case perfect = "P"
        case major = "M"
        case minor = "m"
        case augmented = "A"
        case diminished = "d"
    }

    /// Calculate interval between two pitches
    static func between(_ lower: Pitch, _ upper: Pitch) -> Interval {
        let semitones = upper.midiNote - lower.midiNote
        let staffDistance = upper.staffPosition - lower.staffPosition
        let size = abs(staffDistance) + 1

        // Determine quality based on semitones and size
        let quality: Quality
        let normalizedSemitones = semitones % 12
        let normalizedSize = ((size - 1) % 7) + 1

        switch normalizedSize {
        case 1: // Unison
            quality = normalizedSemitones == 0 ? .perfect : .augmented
        case 2: // Second
            quality = normalizedSemitones == 2 ? .major : (normalizedSemitones == 1 ? .minor : .diminished)
        case 3: // Third
            quality = normalizedSemitones == 4 ? .major : (normalizedSemitones == 3 ? .minor : .diminished)
        case 4: // Fourth
            quality = normalizedSemitones == 5 ? .perfect : (normalizedSemitones == 6 ? .augmented : .diminished)
        case 5: // Fifth
            quality = normalizedSemitones == 7 ? .perfect : (normalizedSemitones == 6 ? .diminished : .augmented)
        case 6: // Sixth
            quality = normalizedSemitones == 9 ? .major : (normalizedSemitones == 8 ? .minor : .diminished)
        case 7: // Seventh
            quality = normalizedSemitones == 11 ? .major : (normalizedSemitones == 10 ? .minor : .diminished)
        default:
            quality = .perfect
        }

        return Interval(semitones: semitones, quality: quality, size: size)
    }

    /// Display name like "P5" or "M3"
    var displayName: String {
        "\(quality.rawValue)\(size)"
    }

    /// Whether this is a consonant interval in first species
    var isConsonant: Bool {
        let normalizedSize = ((size - 1) % 7) + 1
        switch (normalizedSize, quality) {
        case (1, .perfect): return true   // Unison
        case (3, .major), (3, .minor): return true  // Thirds
        case (5, .perfect): return true   // Fifth
        case (6, .major), (6, .minor): return true  // Sixths
        case (8, .perfect): return true   // Octave (size % 7 == 1)
        default: return false
        }
    }
}
