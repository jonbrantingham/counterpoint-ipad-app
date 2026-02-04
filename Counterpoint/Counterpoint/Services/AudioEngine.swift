//
//  AudioEngine.swift
//  Counterpoint
//
//  Low-latency audio engine for playback and touch feedback using triangle wave synthesis
//

import Foundation
import AVFoundation
import Combine

class AudioEngine: ObservableObject {

    // MARK: - Properties

    private var audioEngine: AVAudioEngine?
    private var mixerNode: AVAudioMixerNode?
    private var sourceNodes: [Int: AVAudioSourceNode] = [:]  // MIDI note -> source node
    private var activeNotes: Set<Int> = []
    private var noteAmplitudes: [Int: Float] = [:]  // For envelope control

    @Published var isPlaying = false
    @Published var currentBeat: Int = 0
    @Published var tempo: Double = 215  // BPM

    private var scheduledEvents: [DispatchWorkItem] = []
    private let sampleRate: Double = 44100

    // MARK: - Initialization

    init() {
        setupAudioEngine()
    }

    deinit {
        stopPlayback()
        audioEngine?.stop()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()

        guard let engine = audioEngine, let mixer = mixerNode else { return }

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        // Set a reasonable volume
        mixer.outputVolume = 0.5

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    // MARK: - Triangle Wave Generation

    private func createTriangleWaveNode(frequency: Float, amplitude: Float = 0.3) -> AVAudioSourceNode {
        var phase: Float = 0.0
        let phaseIncrement = frequency / Float(sampleRate)

        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard self != nil else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                // Triangle wave: rises from -1 to 1, then falls from 1 to -1
                let triangleValue = 2.0 * abs(2.0 * (phase - floor(phase + 0.5))) - 1.0
                let value = triangleValue * amplitude

                phase += phaseIncrement
                if phase >= 1.0 {
                    phase -= 1.0
                }

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = value
                }
            }

            return noErr
        }

        return sourceNode
    }

    /// Convert MIDI note to frequency
    private func midiToFrequency(_ midiNote: Int) -> Float {
        return 440.0 * pow(2.0, Float(midiNote - 69) / 12.0)
    }

    /// Resolve MIDI note for a pitch with optional key signature
    private func midiNote(for pitch: Pitch, in key: Key?) -> Int {
        if let key = key {
            return pitch.midiNote(in: key)
        }
        return pitch.midiNote
    }

    // MARK: - Note Playback

    /// Play a single note immediately (for touch feedback)
    func playNote(_ pitch: Pitch, key: Key? = nil, velocity: UInt8 = 80, duration: Double = 0.3) {
        let midiNote = midiNote(for: pitch, in: key)
        startNoteInternal(midiNote: midiNote, velocity: velocity)

        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopNoteInternal(midiNote: midiNote)
        }
    }

    /// Play two notes simultaneously (bass + soprano interval)
    func playInterval(bass: Pitch, soprano: Pitch, key: Key? = nil, velocity: UInt8 = 80, duration: Double = 0.5) {
        let bassMidi = midiNote(for: bass, in: key)
        let sopranoMidi = midiNote(for: soprano, in: key)

        startNoteInternal(midiNote: bassMidi, velocity: velocity)
        startNoteInternal(midiNote: sopranoMidi, velocity: velocity)

        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopNoteInternal(midiNote: bassMidi)
            self?.stopNoteInternal(midiNote: sopranoMidi)
        }
    }

    /// Start a note (internal implementation)
    private func startNoteInternal(midiNote: Int, velocity: UInt8 = 80) {
        guard let engine = audioEngine, let mixer = mixerNode else { return }

        // Stop if already playing
        if activeNotes.contains(midiNote) {
            stopNoteInternal(midiNote: midiNote)
        }

        let frequency = midiToFrequency(midiNote)
        let amplitude = Float(velocity) / 127.0 * 0.25  // Scale amplitude

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let sourceNode = createTriangleWaveNode(frequency: frequency, amplitude: amplitude)

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)

        sourceNodes[midiNote] = sourceNode
        activeNotes.insert(midiNote)
    }

    /// Stop a note (internal implementation)
    private func stopNoteInternal(midiNote: Int) {
        guard let engine = audioEngine else { return }

        if let sourceNode = sourceNodes[midiNote] {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
            sourceNodes.removeValue(forKey: midiNote)
            activeNotes.remove(midiNote)
        }
    }

    /// Play a note and sustain until stopNote is called
    func startNote(_ pitch: Pitch, key: Key? = nil, velocity: UInt8 = 80) {
        startNoteInternal(midiNote: midiNote(for: pitch, in: key), velocity: velocity)
    }

    /// Stop a sustained note
    func stopNote(_ pitch: Pitch, key: Key? = nil) {
        stopNoteInternal(midiNote: midiNote(for: pitch, in: key))
    }

    /// Stop all notes
    func stopAllNotes() {
        for midiNote in Array(activeNotes) {
            stopNoteInternal(midiNote: midiNote)
        }
    }

    // MARK: - Exercise Playback

    /// Play an entire exercise (both voices)
    func playExercise(bass: Voice, soprano: Voice, key: Key? = nil, tempo: Double? = nil) {
        guard !isPlaying else { return }

        let playbackTempo = tempo ?? self.tempo
        isPlaying = true
        currentBeat = 0

        let beatDuration = 60.0 / playbackTempo  // Seconds per beat

        // Cancel any existing scheduled events
        cancelScheduledEvents()

        // Collect all events with their times
        var events: [(time: Double, pitch: Pitch, duration: Double, isStart: Bool)] = []

        // Add bass notes
        for note in bass.notes {
            let startTime = note.beatPosition * beatDuration
            let noteDuration = note.duration.beats * beatDuration * 0.9  // Slight gap between notes
            events.append((time: startTime, pitch: note.pitch, duration: noteDuration, isStart: true))
        }

        // Add soprano notes
        for note in soprano.notes {
            let startTime = note.beatPosition * beatDuration
            let noteDuration = note.duration.beats * beatDuration * 0.9
            events.append((time: startTime, pitch: note.pitch, duration: noteDuration, isStart: true))
        }

        // Sort by time
        events.sort { $0.time < $1.time }

        // Schedule each event
        let startInstant = DispatchTime.now()

        for event in events {
            // Schedule note on
            let noteOnWork = DispatchWorkItem { [weak self] in
                guard let self = self, self.isPlaying else { return }
                self.startNote(event.pitch, key: key)
            }
            scheduledEvents.append(noteOnWork)
            DispatchQueue.main.asyncAfter(deadline: startInstant + event.time, execute: noteOnWork)

            // Schedule note off
            let noteOffWork = DispatchWorkItem { [weak self] in
                self?.stopNote(event.pitch, key: key)
            }
            scheduledEvents.append(noteOffWork)
            DispatchQueue.main.asyncAfter(deadline: startInstant + event.time + event.duration, execute: noteOffWork)
        }

        // Schedule end of playback
        let lastEventTime = events.map { $0.time + $0.duration }.max() ?? 0
        let endWork = DispatchWorkItem { [weak self] in
            self?.isPlaying = false
            self?.currentBeat = 0
        }
        scheduledEvents.append(endWork)
        DispatchQueue.main.asyncAfter(deadline: startInstant + lastEventTime + 0.5, execute: endWork)
    }

    /// Play just the bass line
    func playBassLine(_ bass: Voice, key: Key? = nil, tempo: Double? = nil) {
        playExercise(bass: bass, soprano: Voice(notes: []), key: key, tempo: tempo)
    }

    /// Cancel all scheduled playback events
    private func cancelScheduledEvents() {
        for event in scheduledEvents {
            event.cancel()
        }
        scheduledEvents.removeAll()
    }

    /// Stop current playback
    func stopPlayback() {
        isPlaying = false
        currentBeat = 0
        cancelScheduledEvents()
        stopAllNotes()
    }

    // MARK: - Touch Feedback

    /// Play feedback when user taps to place a note
    /// Plays the tapped pitch along with the corresponding bass note
    func playTouchFeedback(tappedPitch: Pitch, bassNote: Note?, key: Key? = nil) {
        if let bass = bassNote {
            playInterval(bass: bass.pitch, soprano: tappedPitch, key: key)
        } else {
            playNote(tappedPitch, key: key)
        }
    }

    /// Play a correct answer sound (major chord arpeggio)
    func playCorrectSound() {
        let notes = [60, 64, 67]  // C major chord
        for (index, midiNote) in notes.enumerated() {
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.startNoteInternal(midiNote: midiNote, velocity: 60)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            for midiNote in notes {
                self?.stopNoteInternal(midiNote: midiNote)
            }
        }
    }

    /// Play an incorrect answer sound (minor second)
    func playIncorrectSound() {
        let notes = [60, 61]  // C and C#
        for midiNote in notes {
            startNoteInternal(midiNote: midiNote, velocity: 50)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            for midiNote in notes {
                self?.stopNoteInternal(midiNote: midiNote)
            }
        }
    }

    // MARK: - Tempo Control

    func setTempo(_ newTempo: Double) {
        tempo = max(30, min(240, newTempo))  // Clamp between 30 and 240 BPM
    }
}
