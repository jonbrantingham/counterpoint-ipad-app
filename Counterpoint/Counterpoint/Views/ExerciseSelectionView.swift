//
//  ExerciseSelectionView.swift
//  Counterpoint
//
//  Main view for selecting exercises and viewing progress
//

import SwiftUI

struct ExerciseSelectionView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @State private var exercises: [Exercise] = []
    @State private var selectedBassline: Bassline?
    @State private var selectedIntervalModule: IntervalModule?
    @State private var showingQuiz = false
    @State private var currentQuizItem: QuizItem?

    let onSelectExercise: (Exercise) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Quiz prompt if any are due
            if progressManager.shouldShowQuiz() {
                QuizPromptView(
                    quizCount: progressManager.quizQueue.count,
                    onStartQuiz: {
                        startQuiz()
                    },
                    onSkip: {
                        // Just dismiss, user can continue
                    }
                )
            }

            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Progress summary
                    progressSummary

                    // Bassline selection
                    basslineSection

                    // Interval modules
                    intervalModuleSection

                    // Exercises for selected bassline
                    if let bassline = selectedBassline {
                        exerciseList(for: bassline)
                    } else if let module = selectedIntervalModule {
                        intervalExerciseList(for: module)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadExercises()
            if selectedBassline == nil {
                selectedBassline = Bassline.v1Basslines.first
            }
            progressManager.refreshQuizQueue()
        }
        .sheet(isPresented: $showingQuiz) {
            if let quizItem = currentQuizItem,
               let exercise = exercises.first(where: { $0.id == quizItem.exerciseId }) {
                QuizView(quizItem: quizItem, exercise: exercise) { wasCorrect in
                    progressManager.completeQuiz(quizItem, wasCorrect: wasCorrect)
                    showingQuiz = false
                    currentQuizItem = nil
                }
            }
        }
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Your Progress")
                        .font(.headline)
                    Text("\(progressManager.totalCompleted) patterns learned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Overall progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }

            if progressManager.averageAccuracy > 0 {
                HStack {
                    Label("Average Accuracy", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progressManager.averageAccuracy * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var overallProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(progressManager.totalCompleted) / Double(exercises.count)
    }

    // MARK: - Bassline Section

    private var basslineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basslines")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Bassline.v1Basslines) { bassline in
                        BasslineCard(
                            bassline: bassline,
                            isSelected: selectedBassline?.id == bassline.id,
                            progress: progressManager.completionPercentage(
                                for: bassline.id,
                                exercises: exercises
                            )
                        )
                        .onTapGesture {
                            selectedBassline = bassline
                            selectedIntervalModule = nil
                        }
                    }
                }
            }
        }
    }

    private var intervalModuleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intervals")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(IntervalModule.allModules) { module in
                        IntervalModuleCard(
                            module: module,
                            isSelected: selectedIntervalModule?.id == module.id,
                            progress: progressManager.completionPercentage(
                                for: module.id,
                                exercises: exercises
                            )
                        )
                        .onTapGesture {
                            selectedIntervalModule = module
                            selectedBassline = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Exercise List

    private func exerciseList(for bassline: Bassline) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.headline)

            let basslineExercises = exercises.filter { $0.basslineId == bassline.id }

            ForEach(basslineExercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    progress: progressManager.getProgress(for: exercise.id)
                )
                .onTapGesture {
                    onSelectExercise(exercise)
                }
            }

            if basslineExercises.isEmpty {
                Text("No exercises available for this bassline")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    private func intervalExerciseList(for module: IntervalModule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(module.name)
                .font(.headline)

            let moduleExercises = exercises.filter { $0.basslineId == module.id }
            let basicExercises = moduleExercises.filter { !$0.id.contains("_adv_") }
            let advancedExercises = moduleExercises.filter { $0.id.contains("_adv_") }

            ForEach(basicExercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    progress: progressManager.getProgress(for: exercise.id)
                )
                .onTapGesture {
                    onSelectExercise(exercise)
                }
            }

            if !advancedExercises.isEmpty {
                Text("Advanced")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                ForEach(advancedExercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        progress: progressManager.getProgress(for: exercise.id)
                    )
                    .onTapGesture {
                        onSelectExercise(exercise)
                    }
                }
            }

            if moduleExercises.isEmpty {
                Text("No exercises available for this module")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Actions

    private func loadExercises() {
        exercises = ExerciseLoader.shared.loadAllExercises()
    }

    private func startQuiz() {
        if let quizItem = progressManager.getNextQuiz() {
            currentQuizItem = quizItem
            showingQuiz = true
        }
    }
}

// MARK: - Bassline Card

struct BasslineCard: View {
    let bassline: Bassline
    let isSelected: Bool
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bassline.name)
                    .font(.headline)
                Spacer()
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(bassline.description)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(progress >= 1.0 ? .green : .blue)
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Interval Module Card

struct IntervalModuleCard: View {
    let module: IntervalModule
    let isSelected: Bool
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(module.name)
                    .font(.headline)
                Spacer()
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(module.description)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(progress >= 1.0 ? .green : .blue)
        }
        .padding()
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: Exercise
    let progress: ExerciseProgress?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.patternName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicators
            HStack(spacing: 12) {
                if let progress = progress {
                    // Mastery level
                    HStack(spacing: 2) {
                        ForEach(0..<5) { level in
                            Circle()
                                .fill(level < progress.masteryLevel ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Completed keys
                    if !progress.completedKeys.isEmpty {
                        Text("\(progress.completedKeys.count) keys")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Completed indicator
                    if progress.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    Text("New")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    ExerciseSelectionView(onSelectExercise: { _ in })
        .environmentObject(ProgressManager())
        .environmentObject(AudioEngine())
}
