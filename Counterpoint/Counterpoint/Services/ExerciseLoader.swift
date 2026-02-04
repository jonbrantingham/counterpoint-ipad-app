//
//  ExerciseLoader.swift
//  Counterpoint
//
//  Loads exercises from bundled MusicXML files or built-in data
//

import Foundation

class ExerciseLoader {

    // MARK: - Singleton

    static let shared = ExerciseLoader()
    private init() {}

    // MARK: - Properties

    private var loadedExercises: [Exercise] = []
    private let parser = MusicXMLParser()

    // MARK: - Public Methods

    /// Load all exercises (from MusicXML files or built-in)
    func loadAllExercises() -> [Exercise] {
        if loadedExercises.isEmpty {
            loadedExercises = loadBuiltInExercises()
            loadedExercises += loadMusicXMLExercises()
        }
        return loadedExercises
    }

    /// Get exercises for a specific bassline
    func exercises(forBassline basslineId: String) -> [Exercise] {
        loadAllExercises().filter { $0.basslineId == basslineId }
    }

    /// Get all available basslines
    func availableBasslines() -> [Bassline] {
        return Bassline.v1Basslines
    }

    // MARK: - Private Methods

    /// Load MusicXML files from the Resources/Exercises directory
    private func loadMusicXMLExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        guard let exercisesURL = Bundle.main.resourceURL?.appendingPathComponent("Exercises") else {
            return exercises
        }

        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: exercisesURL, includingPropertiesForKeys: nil) else {
            return exercises
        }

        for file in files where file.pathExtension == "xml" || file.pathExtension == "musicxml" {
            let filename = file.deletingPathExtension().lastPathComponent
            // Parse filename for metadata: bassline_pattern.xml
            let components = filename.split(separator: "_")
            let basslineId = components.first.map(String.init) ?? "bassline1"
            let patternName = components.dropFirst().joined(separator: "_")

            if let exercise = parser.parse(
                url: file,
                exerciseId: filename,
                basslineId: basslineId,
                patternName: patternName
            ) {
                exercises.append(exercise)
            }
        }

        return exercises
    }

    /// Built-in exercises for v1 (no external files needed)
    private func loadBuiltInExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // Bassline 1: 1-5-1 (C-G-C)
        let bassline1 = createBassline1Exercises()
        exercises.append(contentsOf: bassline1)

        // Bassline 2: 1-2-3-4-5-6-5-1 (C-D-E-F-G-A-G-C)
        let bassline2 = createBassline2Exercises()
        exercises.append(contentsOf: bassline2)

        // Interval training modules (single bass note)
        let intervalModules = createIntervalModuleExercises()
        exercises.append(contentsOf: intervalModules)

        return exercises
    }

    // MARK: - Bassline 1: 1-5-1

    private func createBassline1Exercises() -> [Exercise] {
        // Bass: C3-G3-C3
        let bassNotes = [
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .g, octave: 3), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 8)
        ]
        let bassLine = Voice(notes: bassNotes)

        var exercises: [Exercise] = []

        // Pattern 8-7-8 (C5-B4-C5)
        let soprano878 = Voice(notes: [
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .b, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 8)
        ])
        exercises.append(Exercise(
            id: "bassline1_878",
            name: "Pattern 8-7-8",
            basslineId: "bassline1",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [soprano878],
            patternName: "8-7-8"
        ))

        // Pattern 5-4-3 (G4-F4-E4)
        let soprano543 = Voice(notes: [
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .f, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 8)
        ])
        exercises.append(Exercise(
            id: "bassline1_543",
            name: "Pattern 5-4-3",
            basslineId: "bassline1",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [soprano543],
            patternName: "5-4-3"
        ))

        // Pattern 3-2-3 (E4-D4-E4)
        let soprano323 = Voice(notes: [
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .d, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 8)
        ])
        exercises.append(Exercise(
            id: "bassline1_323",
            name: "Pattern 3-2-3",
            basslineId: "bassline1",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [soprano323],
            patternName: "3-2-3"
        ))

        // Pattern 5-5-5 (G4-G4-G4) - sustained fifth
        let soprano555 = Voice(notes: [
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 8)
        ])
        exercises.append(Exercise(
            id: "bassline1_555",
            name: "Pattern 5-5-5",
            basslineId: "bassline1",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [soprano555],
            patternName: "5-5-5"
        ))

        return exercises
    }

    // MARK: - Bassline 2: 1-2-3-4-5-6-5-1

    private func createBassline2Exercises() -> [Exercise] {
        // Bass: C3-D3-E3-F3-G3-A3-G3-C3
        let bassNotes = [
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .d, octave: 3), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .e, octave: 3), duration: .whole, beatPosition: 8),
            Note(pitch: Pitch(noteName: .f, octave: 3), duration: .whole, beatPosition: 12),
            Note(pitch: Pitch(noteName: .g, octave: 3), duration: .whole, beatPosition: 16),
            Note(pitch: Pitch(noteName: .a, octave: 3), duration: .whole, beatPosition: 20),
            Note(pitch: Pitch(noteName: .g, octave: 3), duration: .whole, beatPosition: 24),
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 28)
        ]
        let bassLine = Voice(notes: bassNotes)

        var exercises: [Exercise] = []

        // Pattern: 8-7-6-5-4-3-4-8 (contrary motion)
        // C5-B4-A4-G4-F4-E4-F4-C5
        let sopranoContrary = Voice(notes: [
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .b, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 8),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 12),
            Note(pitch: Pitch(noteName: .f, octave: 4), duration: .whole, beatPosition: 16),
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 20),
            Note(pitch: Pitch(noteName: .f, octave: 4), duration: .whole, beatPosition: 24),
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 28)
        ])
        exercises.append(Exercise(
            id: "bassline2_contrary",
            name: "Contrary Motion",
            basslineId: "bassline2",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [sopranoContrary],
            patternName: "8-7-6-5-4-3-4-8"
        ))

        // Pattern: 3-4-5-6-5-6-5-3 (parallel tenths/thirds)
        // E4-F4-G4-A4-G4-A4-G4-E4
        let sopranoThirds = Voice(notes: [
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .f, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 8),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 12),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 16),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 20),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 24),
            Note(pitch: Pitch(noteName: .e, octave: 4), duration: .whole, beatPosition: 28)
        ])
        exercises.append(Exercise(
            id: "bassline2_thirds",
            name: "Parallel Thirds",
            basslineId: "bassline2",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [sopranoThirds],
            patternName: "3-4-5-6-5-6-5-3"
        ))

        // Pattern: 5-6-5-6-5-6-5-5 (alternating sixths and fifths)
        // G4-A4-G4-A4-G4-A4-G4-G4
        let sopranoAlternating = Voice(notes: [
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 8),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 12),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 16),
            Note(pitch: Pitch(noteName: .a, octave: 4), duration: .whole, beatPosition: 20),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 24),
            Note(pitch: Pitch(noteName: .g, octave: 4), duration: .whole, beatPosition: 28)
        ])
        exercises.append(Exercise(
            id: "bassline2_alternating",
            name: "5-6 Alternating",
            basslineId: "bassline2",
            species: .first,
            key: .cMajor,
            bassLine: bassLine,
            sopranoSolutions: [sopranoAlternating],
            patternName: "5-6-5-6-5-6-5-5"
        ))

        return exercises
    }

    // MARK: - Interval Modules (Single Bass Note)

    private func createIntervalModuleExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        let bassNote = Note(pitch: Pitch(noteName: .c, octave: 4), duration: .whole, beatPosition: 0)
        let bassLine = Voice(notes: [bassNote])

        for module in IntervalModule.allModules {
            for interval in module.intervals {
                let sopranoPitch = Pitch.fromStaffPosition(bassNote.pitch.staffPosition + (interval.size - 1))
                let sopranoNote = Note(pitch: sopranoPitch, duration: .whole, beatPosition: 0)
                let sopranoLine = Voice(notes: [sopranoNote])

                exercises.append(Exercise(
                    id: "\(module.id)_\(interval.id)",
                    name: "\(module.name) \(interval.displayName)",
                    basslineId: module.id,
                    species: .first,
                    key: .cMajor,
                    bassLine: bassLine,
                    sopranoSolutions: [sopranoLine],
                    patternName: interval.displayName
                ))
            }
        }

        return exercises
    }
}

// MARK: - Bassline Model

struct Bassline: Identifiable {
    let id: String
    let name: String
    let description: String
    let scaleDegrees: [Int]  // e.g., [1, 5, 1] for 1-5-1

    static let v1Basslines: [Bassline] = [
        Bassline(
            id: "bassline1",
            name: "Bassline 1",
            description: "1-5-1 (C-G-C)",
            scaleDegrees: [1, 5, 1]
        ),
        Bassline(
            id: "bassline2",
            name: "Bassline 2",
            description: "1-2-3-4-5-6-5-1",
            scaleDegrees: [1, 2, 3, 4, 5, 6, 5, 1]
        )
    ]
}

// MARK: - Interval Module Model

struct IntervalModule: Identifiable {
    struct IntervalSpec: Identifiable {
        let id: String
        let displayName: String
        let size: Int
    }

    let id: String
    let name: String
    let description: String
    let intervals: [IntervalSpec]

    static let perfect = IntervalModule(
        id: "intervals_perfect",
        name: "Perfect Consonances",
        description: "P1, P5, P8",
        intervals: [
            IntervalSpec(id: "p1", displayName: "P1", size: 1),
            IntervalSpec(id: "p5", displayName: "P5", size: 5),
            IntervalSpec(id: "p8", displayName: "P8", size: 8)
        ]
    )

    static let imperfect = IntervalModule(
        id: "intervals_imperfect",
        name: "Imperfect Consonances",
        description: "M3, M6",
        intervals: [
            IntervalSpec(id: "m3", displayName: "M3", size: 3),
            IntervalSpec(id: "m6", displayName: "M6", size: 6)
        ]
    )

    static let dissonant = IntervalModule(
        id: "intervals_dissonant",
        name: "Dissonances",
        description: "M2, P4, M7",
        intervals: [
            IntervalSpec(id: "m2", displayName: "M2", size: 2),
            IntervalSpec(id: "p4", displayName: "P4", size: 4),
            IntervalSpec(id: "m7", displayName: "M7", size: 7)
        ]
    )

    static let allModules: [IntervalModule] = [perfect, imperfect, dissonant]
}
