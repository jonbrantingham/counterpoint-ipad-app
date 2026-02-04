//
//  QuizView.swift
//  Counterpoint
//
//  Spaced repetition quiz view for reviewing previously learned patterns
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var audioEngine: AudioEngine

    let quizItem: QuizItem
    let exercise: Exercise
    let onComplete: (Bool) -> Void

    @StateObject private var viewModel: ExerciseViewModel
    @State private var quizStarted = false
    @State private var showingResult = false
    @State private var wasCorrect = false

    init(quizItem: QuizItem, exercise: Exercise, onComplete: @escaping (Bool) -> Void) {
        self.quizItem = quizItem
        self.exercise = exercise
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: ExerciseViewModel(
            exercise: exercise,
            audioEngine: AudioEngine()
        ))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Quiz header
            quizHeader

            if !quizStarted {
                // Pre-quiz prompt
                preQuizPrompt
            } else if showingResult {
                // Results
                resultView
            } else {
                // Quiz content
                quizContent
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            setupQuiz()
        }
    }

    // MARK: - Subviews

    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.orange)

                Text("Review Time!")
                    .font(.title)
                    .fontWeight(.bold)
            }

            Text("Test your memory of: \(exercise.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var preQuizPrompt: some View {
        VStack(spacing: 24) {
            Text("Can you remember the soprano line for this pattern?")
                .font(.headline)
                .multilineTextAlignment(.center)

            // Show the bass line with figured bass (actual intervals)
            GrandStaffView(
                bassNotes: viewModel.transposedBass,
                sopranoNotes: [],
                placedNotes: [],
                key: viewModel.currentKey,
                showSoprano: false,
                onTapPosition: nil,
                scale: 1.0,
                figuredBass: viewModel.figuredBass
            )
            .frame(height: 250)
            .padding()

            HStack(spacing: 20) {
                Button(action: { playBass() }) {
                    Label("Hear Bass", systemImage: "speaker.wave.2")
                }
                .buttonStyle(.bordered)

                Button(action: { startQuiz() }) {
                    Label("Start Quiz", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Skip for now") {
                onComplete(false)
            }
            .foregroundColor(.secondary)
        }
    }

    private var quizContent: some View {
        VStack(spacing: 16) {
            Text("Recreate the soprano line from memory")
                .font(.headline)

            GrandStaffView(
                bassNotes: viewModel.transposedBass,
                sopranoNotes: viewModel.transposedSoprano,
                placedNotes: viewModel.placedNotes,
                key: viewModel.currentKey,
                showSoprano: false,
                onTapPosition: { beatIndex, pitch in
                    viewModel.placeNote(pitch: pitch, at: beatIndex)
                },
                scale: 1.0,
                figuredBass: viewModel.figuredBass
            )
            .frame(height: 250)

            // Progress
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .padding(.horizontal)

            Text(viewModel.feedbackMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button(action: { playBass() }) {
                    Label("Bass", systemImage: "speaker.wave.2")
                }
                .buttonStyle(.bordered)

                Button(action: { giveUp() }) {
                    Label("Show Answer", systemImage: "eye")
                }
                .buttonStyle(.bordered)
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                evaluateResult()
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            if wasCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Excellent!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your accuracy: \(Int(viewModel.accuracy * 100))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                Text("Keep Practicing")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Review the pattern and try again soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // Show the complete solution
            GrandStaffView(
                bassNotes: viewModel.transposedBass,
                sopranoNotes: viewModel.transposedSoprano,
                placedNotes: [],
                key: viewModel.currentKey,
                showSoprano: true,
                onTapPosition: nil,
                scale: 1.0,
                figuredBass: viewModel.figuredBass
            )
            .frame(height: 200)

            Button(action: { playExercise() }) {
                Label("Play Solution", systemImage: "play.fill")
            }
            .buttonStyle(.bordered)

            Button("Continue") {
                onComplete(wasCorrect)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func setupQuiz() {
        // Set the key for the quiz (may be transposed)
        if let keyNote = NoteName(rawValue: quizItem.keyToQuiz) {
            let key = Key(tonic: keyNote, mode: .major)
            viewModel.setKey(key)
        }
    }

    private func startQuiz() {
        quizStarted = true
        viewModel.startPractice()
    }

    private func playBass() {
        viewModel.playBass()
    }

    private func playExercise() {
        viewModel.showSoprano = true
        viewModel.playExercise()
    }

    private func giveUp() {
        wasCorrect = false
        showingResult = true
    }

    private func evaluateResult() {
        // Consider it correct if accuracy is above 70%
        wasCorrect = viewModel.accuracy >= 0.7
        showingResult = true
    }
}

// MARK: - Quiz Prompt View

/// A small prompt that appears between exercises to suggest a quiz
struct QuizPromptView: View {
    let quizCount: Int
    let onStartQuiz: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.orange)
                Text("Time for Review!")
                    .font(.headline)
            }

            Text("You have \(quizCount) pattern\(quizCount == 1 ? "" : "s") to review")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Later") {
                    onSkip()
                }
                .buttonStyle(.bordered)

                Button("Review Now") {
                    onStartQuiz()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding()
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

    let quizItem = QuizItem(id: "1", exerciseId: "test", dueDate: Date(), keyToQuiz: "C")

    return QuizView(quizItem: quizItem, exercise: exercise, onComplete: { _ in })
        .environmentObject(ProgressManager())
        .environmentObject(AudioEngine())
}
