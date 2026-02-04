//
//  Exercise.swift
//  Counterpoint
//
//  Exercise model representing a counterpoint exercise
//

import Foundation

/// A counterpoint exercise with bass line and soprano solution(s)
struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let basslineId: String
    let species: Species
    let key: Key
    let bassLine: Voice
    let sopranoSolutions: [Voice]  // Multiple valid soprano solutions
    let patternName: String  // e.g., "8-7-8" for soprano pattern

    /// The primary soprano solution (first one)
    var primarySoprano: Voice {
        sopranoSolutions.first ?? Voice(notes: [])
    }

    enum Species: String, Codable {
        case first = "1:1"
        case second = "2:1"
        case third = "3:1"
        case fourth = "syncopated"
        case fifth = "florid"
    }
}

/// Progress information for an exercise
struct ExerciseProgress: Codable, Identifiable {
    let id: String  // Matches exercise ID
    var completed: Bool
    var accuracy: Double  // 0.0 to 1.0
    var lastPracticed: Date?
    var masteryLevel: Int  // 0-5 for spaced repetition
    var nextReviewDate: Date?
    var completedKeys: Set<String>  // Keys that have been successfully completed

    init(id: String) {
        self.id = id
        self.completed = false
        self.accuracy = 0
        self.lastPracticed = nil
        self.masteryLevel = 0
        self.nextReviewDate = nil
        self.completedKeys = []
    }
}

/// Represents a user's attempt at recreating a soprano line
struct ExerciseAttempt {
    let exerciseId: String
    let key: Key
    var placedNotes: [PlacedNote]
    let startTime: Date

    struct PlacedNote: Identifiable {
        let id: UUID
        let pitch: Pitch
        let beatPosition: Int  // Which beat/position this note is at
        var isCorrect: Bool?
        var fadeStartTime: Date?
    }
}

/// Result of checking a placed note against the solution
struct NoteCheckResult {
    let isCorrect: Bool
    let expectedPitch: Pitch?
    let actualPitch: Pitch
    let interval: Interval?  // Interval with bass note

    var feedbackMessage: String {
        if isCorrect {
            return "Correct!"
        } else if let expected = expectedPitch {
            return "Expected \(expected.noteName.rawValue)\(expected.octave)"
        } else {
            return "Incorrect"
        }
    }
}
