//
//  ExerciseViewModel.swift
//  Counterpoint
//
//  View model for exercise interaction and state management
//

import Foundation
import SwiftUI
import Combine

class ExerciseViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var exercise: Exercise
    @Published var currentKey: Key
    @Published var phase: ExercisePhase = .study
    @Published var showSoprano: Bool = true
    @Published var placedNotes: [GrandStaffView.PlacedNoteDisplay] = []
    @Published var feedbackMessage: String = ""
    @Published var isComplete: Bool = false
    @Published var accuracy: Double = 0.0

    // Transposition
    @Published var transpositionIndex: Int = 0
    @Published var availableKeys: [Key] = Key.circleOfFourths

    // Audio
    @Published var tempo: Double = 60 {
        didSet {
            audioEngine.setTempo(tempo)
        }
    }
    @Published var isPlaying: Bool = false

    // MARK: - Dependencies

    private let audioEngine: AudioEngine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Properties

    private var correctNotes: Int = 0
    private var totalAttempts: Int = 0
    private var fadeTimers: [UUID: Timer] = [:]

    // MARK: - Types

    enum ExercisePhase {
        case study      // User sees complete exercise
        case practice   // Soprano hidden, user places notes
        case review     // Exercise complete, showing results
    }

    // MARK: - Initialization

    init(exercise: Exercise, audioEngine: AudioEngine) {
        self.exercise = exercise
        self.currentKey = exercise.key
        self.audioEngine = audioEngine
        self.tempo = audioEngine.tempo

        // Subscribe to audio engine's isPlaying state
        audioEngine.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
    }

    // MARK: - Computed Properties

    /// Bass notes transposed to current key
    var transposedBass: [Note] {
        transposeVoice(exercise.bassLine, from: exercise.key, to: currentKey).notes
    }

    /// Soprano notes transposed to current key (solution)
    var transposedSoprano: [Note] {
        transposeVoice(exercise.primarySoprano, from: exercise.key, to: currentKey).notes
    }

    /// Number of notes the user needs to place
    var noteCount: Int {
        exercise.primarySoprano.notes.count
    }

    /// Current progress (notes placed / total notes)
    var progress: Double {
        guard noteCount > 0 else { return 0 }
        return Double(placedNotes.count) / Double(noteCount)
    }

    /// Figured bass notation - intervals from bass to soprano
    /// Returns array like ["8", "3", "8"] for octave-third-octave
    var figuredBass: [String] {
        let bass = transposedBass
        let soprano = transposedSoprano
        var figures: [String] = []

        for i in 0..<min(bass.count, soprano.count) {
            let interval = Interval.between(bass[i].pitch, soprano[i].pitch)
            // Use simple interval size (1-8), not compound
            let simpleSize = ((interval.size - 1) % 7) + 1
            figures.append("\(simpleSize)")
        }

        return figures
    }

    // MARK: - Actions

    /// Start studying the exercise (show everything)
    func startStudy() {
        phase = .study
        showSoprano = true
        placedNotes = []
        feedbackMessage = ""
        isComplete = false
    }

    /// Begin practice (hide soprano, let user recreate)
    func startPractice() {
        phase = .practice
        showSoprano = false
        placedNotes = []
        correctNotes = 0
        totalAttempts = 0
        feedbackMessage = "Tap to place notes"
    }

    /// Show the solution temporarily (hint)
    func showHint() {
        showSoprano = true

        // Hide again after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.phase == .practice {
                self?.showSoprano = false
            }
        }
    }

    /// Play the entire exercise
    func playExercise() {
        let bass = Voice(notes: transposedBass)
        let soprano = showSoprano ? Voice(notes: transposedSoprano) : Voice(notes: [])
        audioEngine.playExercise(bass: bass, soprano: soprano)
    }

    /// Play just the bass line
    func playBass() {
        audioEngine.playBassLine(Voice(notes: transposedBass))
    }

    /// Stop playback
    func stopPlayback() {
        audioEngine.stopPlayback()
    }

    /// Handle tap to place a note at a beat position
    func placeNote(pitch: Pitch, at beatIndex: Int) {
        guard phase == .practice else { return }
        guard beatIndex < noteCount else { return }

        // Check if this position already has a correct note
        if let existing = placedNotes.first(where: { $0.beatIndex == beatIndex }),
           case .correct = existing.state {
            return
        }

        // Remove any existing incorrect note at this position
        placedNotes.removeAll { $0.beatIndex == beatIndex }

        // Play feedback
        let bassNote = beatIndex < transposedBass.count ? transposedBass[beatIndex] : nil
        audioEngine.playTouchFeedback(tappedPitch: pitch, bassNote: bassNote)

        // Check if correct
        let expectedPitch = transposedSoprano[beatIndex].pitch
        let isCorrect = pitch == expectedPitch

        totalAttempts += 1

        let noteId = UUID()
        let state: GrandStaffView.PlacedNoteDisplay.NoteState

        if isCorrect {
            correctNotes += 1
            state = .correct
        } else {
            let interval = bassNote.map { Interval.between($0.pitch, pitch) }
            state = .incorrect(interval: interval?.displayName ?? "")
            scheduleFade(for: noteId)
        }

        let placedNote = GrandStaffView.PlacedNoteDisplay(
            id: noteId,
            pitch: pitch,
            beatIndex: beatIndex,
            state: state
        )
        placedNotes.append(placedNote)

        checkCompletion()
    }

    // MARK: - Transposition

    /// Move to next key in circle of fourths
    func nextKey() {
        stopPlayback()  // Stop any current playback
        transpositionIndex = (transpositionIndex + 1) % availableKeys.count
        currentKey = availableKeys[transpositionIndex]
        startStudy()
    }

    /// Move to previous key
    func previousKey() {
        stopPlayback()  // Stop any current playback
        transpositionIndex = (transpositionIndex - 1 + availableKeys.count) % availableKeys.count
        currentKey = availableKeys[transpositionIndex]
        startStudy()
    }

    /// Set a specific key
    func setKey(_ key: Key) {
        stopPlayback()  // Stop any current playback
        if let index = availableKeys.firstIndex(where: { $0 == key }) {
            transpositionIndex = index
            currentKey = key
            startStudy()
        }
    }

    // MARK: - Private Methods

    private func scheduleFade(for noteId: UUID) {
        // Start fading after 2 seconds
        let fadeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.fadeNote(noteId)
        }
        fadeTimers[noteId] = fadeTimer
    }

    private func fadeNote(_ noteId: UUID) {
        if let index = placedNotes.firstIndex(where: { $0.id == noteId }) {
            placedNotes[index].state = .fading

            // Remove after fade animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.placedNotes.removeAll { $0.id == noteId }
            }
        }
        fadeTimers.removeValue(forKey: noteId)
    }

    private func checkCompletion() {
        // Count correct notes at each position
        let correctPositions = Set(placedNotes.filter {
            if case .correct = $0.state { return true }
            return false
        }.map { $0.beatIndex })

        if correctPositions.count == noteCount {
            phase = .review
            isComplete = true
            accuracy = totalAttempts > 0 ? Double(correctNotes) / Double(totalAttempts) : 1.0
            feedbackMessage = "Excellent! Accuracy: \(Int(accuracy * 100))%"
        }
    }

    private func transposeVoice(_ voice: Voice, from originalKey: Key, to targetKey: Key) -> Voice {
        // Calculate the interval between keys in semitones
        let originalSemitones = semitoneValue(for: originalKey.tonic, accidental: originalKey.accidental)
        let targetSemitones = semitoneValue(for: targetKey.tonic, accidental: targetKey.accidental)
        let semitoneInterval = targetSemitones - originalSemitones

        // Calculate the staff position interval (number of scale degrees)
        let noteOrder: [NoteName] = [.c, .d, .e, .f, .g, .a, .b]
        let originalIndex = noteOrder.firstIndex(of: originalKey.tonic) ?? 0
        let targetIndex = noteOrder.firstIndex(of: targetKey.tonic) ?? 0
        var staffInterval = targetIndex - originalIndex

        // Adjust staff interval to stay within a reasonable range
        // If semitone interval is positive but large (going up more than tritone),
        // we might need to adjust octave
        if semitoneInterval > 6 {
            staffInterval -= 7  // Go down an octave in staff position
        } else if semitoneInterval < -6 {
            staffInterval += 7  // Go up an octave in staff position
        }

        // Transpose each note
        let transposedNotes = voice.notes.map { note -> Note in
            let newPosition = note.pitch.staffPosition + staffInterval
            let newPitch = Pitch.fromStaffPosition(newPosition)
            return Note(
                id: note.id,
                pitch: newPitch,
                duration: note.duration,
                beatPosition: note.beatPosition
            )
        }

        return Voice(notes: transposedNotes)
    }

    /// Get semitone value for a note name (C=0, C#/Db=1, D=2, etc.)
    private func semitoneValue(for noteName: NoteName, accidental: Accidental) -> Int {
        let baseValue: Int
        switch noteName {
        case .c: baseValue = 0
        case .d: baseValue = 2
        case .e: baseValue = 4
        case .f: baseValue = 5
        case .g: baseValue = 7
        case .a: baseValue = 9
        case .b: baseValue = 11
        }
        return (baseValue + accidental.semitoneOffset + 12) % 12
    }
}
