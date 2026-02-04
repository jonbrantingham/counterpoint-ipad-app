//
//  ExerciseView.swift
//  Counterpoint
//
//  Main view for practicing a counterpoint exercise
//

import SwiftUI

struct ExerciseView: View {
    @StateObject private var viewModel: ExerciseViewModel
    @EnvironmentObject var audioEngine: AudioEngine
    private let minStaffScale: CGFloat = 0.8
    private let maxStaffScale: CGFloat = 2.0
    private let staffScaleStep: CGFloat = 0.1

    @State private var staffScale: CGFloat = 2.0  // Staff size multiplier (0.8 to 2.0)
    @State private var accidentalChoice: AccidentalChoice = .key

    let onDismiss: () -> Void
    let onComplete: () -> Void

    init(exercise: Exercise, onDismiss: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: ExerciseViewModel(
            exercise: exercise,
            audioEngine: AudioEngine()
        ))
        self.onDismiss = onDismiss
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top toolbar
                exerciseToolbar

                Divider()

                // Main staff area
                staffArea(in: geometry)

                Divider()

                // Bottom controls
                bottomControls
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startStudy()
        }
    }

    // MARK: - Toolbar

    private var exerciseToolbar: some View {
        HStack {
            Button(action: { onDismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            .padding()

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.exercise.name)
                    .font(.headline)
                Text(viewModel.exercise.patternName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Key indicator
            keySelector
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var keySelector: some View {
        HStack(spacing: 16) {
            // Staff size controls
            HStack(spacing: 4) {
                Button(action: {
                    staffScale = max(minStaffScale, staffScale - staffScaleStep)
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }
                .disabled(staffScale <= minStaffScale)

                Text("Size")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: {
                    staffScale = min(maxStaffScale, staffScale + staffScaleStep)
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .disabled(staffScale >= maxStaffScale)
            }

            Divider()
                .frame(height: 24)

            // Key selector
            HStack(spacing: 8) {
                Button(action: { viewModel.previousKey() }) {
                    Image(systemName: "chevron.left")
                }

                Button(action: { viewModel.toggleEnharmonic() }) {
                    Text(viewModel.currentKey.shortName)
                        .font(.headline)
                        .frame(minWidth: 60)
                }
                .disabled(viewModel.currentKey.enharmonicEquivalent() == nil)

                Button(action: { viewModel.nextKey() }) {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Staff Area

    private func staffArea(in geometry: GeometryProxy) -> some View {
        // Dynamic height based on scale factor
        let baseHeight: CGFloat = 350
        let staffHeight = min(geometry.size.height * 0.7, baseHeight * staffScale)

        return ZStack {
            GrandStaffView(
                bassNotes: viewModel.transposedBass,
                sopranoNotes: viewModel.transposedSoprano,
                placedNotes: viewModel.placedNotes,
                key: viewModel.currentKey,
                showSoprano: viewModel.showSoprano,
                onTapPosition: viewModel.phase == .practice ? { beatIndex, pitch in
                    let adjustedPitch = Pitch(
                        noteName: pitch.noteName,
                        octave: pitch.octave,
                        accidental: accidentalChoice.accidental
                    )
                    viewModel.placeNote(pitch: adjustedPitch, at: beatIndex)
                } : nil,
                scale: staffScale,
                figuredBass: viewModel.figuredBass,
                hintNote: viewModel.startingHintNote
            )
            .frame(height: staffHeight)

            // Phase indicator overlay
            if viewModel.phase == .review {
                completionOverlay
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var completionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text("Accuracy: \(Int(viewModel.accuracy * 100))%")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button("Practice Again") {
                    viewModel.startPractice()
                }
                .buttonStyle(.bordered)

                Button("Next Key") {
                    viewModel.nextKey()
                }
                .buttonStyle(.borderedProminent)

                Button("Done") {
                    onComplete()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Progress indicator
            if viewModel.phase == .practice {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
            }

            // Feedback message
            Text(viewModel.feedbackMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(height: 20)

            // Control buttons
            HStack(spacing: 30) {
                // Playback controls
                playbackControls

                Spacer()

                // Phase controls
                phaseControls
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)

            // Accidental controls
            accidentalControls
        }
        .padding(.top, 12)
        .background(Color(.systemBackground))
    }

    private var playbackControls: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.playBass() }) {
                VStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.title2)
                    Text("Bass")
                        .font(.caption)
                }
            }
            .disabled(viewModel.isPlaying)

            Button(action: {
                if viewModel.isPlaying {
                    viewModel.stopPlayback()
                } else {
                    viewModel.playExercise()
                }
            }) {
                VStack {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title)
                    Text(viewModel.isPlaying ? "Stop" : "Play")
                        .font(.caption)
                }
            }

            // Tempo control
            VStack(spacing: 4) {
                Text("\(Int(viewModel.tempo)) BPM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $viewModel.tempo, in: 30...360, step: 10)
                    .frame(width: 120)
            }
        }
    }

    private var phaseControls: some View {
        HStack(spacing: 20) {
            switch viewModel.phase {
            case .study:
                Button(action: { viewModel.startPractice() }) {
                    Label("Practice", systemImage: "pencil")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

            case .practice:
                Button(action: { viewModel.showHint() }) {
                    Label("Hint", systemImage: "eye")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.startStudy() }) {
                    Label("Study", systemImage: "book")
                }
                .buttonStyle(.bordered)

            case .review:
                EmptyView()
            }
        }
    }

    private var accidentalControls: some View {
        HStack(spacing: 12) {
            Text("Accidental")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Accidental", selection: $accidentalChoice) {
                ForEach(AccidentalChoice.allCases) { choice in
                    Text(choice.label)
                        .tag(choice)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
    }
}

private enum AccidentalChoice: String, CaseIterable, Identifiable {
    case key
    case flat
    case natural
    case sharp

    var id: String { rawValue }

    var label: String {
        switch self {
        case .key: return "Key"
        case .flat: return "♭"
        case .natural: return "♮"
        case .sharp: return "♯"
        }
    }

    var accidental: Accidental? {
        switch self {
        case .key: return nil
        case .flat: return .flat
        case .natural: return .natural
        case .sharp: return .sharp
        }
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        id: "test",
        name: "Test Exercise",
        basslineId: "bassline1",
        species: .first,
        key: .cMajor,
        bassLine: Voice(notes: [
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .g, octave: 3), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 8)
        ]),
        sopranoSolutions: [Voice(notes: [
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .b, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 8)
        ])],
        patternName: "8-7-8"
    )

    return ExerciseView(exercise: exercise, onDismiss: {}, onComplete: {})
        .environmentObject(AudioEngine())
}
