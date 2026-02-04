//
//  ProgressManager.swift
//  Counterpoint
//
//  Manages user progress tracking and local storage
//

import Foundation
import Combine

class ProgressManager: ObservableObject {

    // MARK: - Published Properties

    @Published var exerciseProgress: [String: ExerciseProgress] = [:]
    @Published var quizQueue: [QuizItem] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let progressKey = "exerciseProgress"
    private let quizQueueKey = "quizQueue"
    private let lastQuizDateKey = "lastQuizDate"

    // Spaced repetition intervals (in days)
    private let reviewIntervals: [Int] = [1, 3, 7, 14, 30, 60]

    // MARK: - Initialization

    init() {
        loadProgress()
    }

    // MARK: - Public Methods

    /// Mark an exercise as completed
    func markExerciseCompleted(_ exerciseId: String, accuracy: Double = 1.0, key: Key = .cMajor) {
        var progress = exerciseProgress[exerciseId] ?? ExerciseProgress(id: exerciseId)

        progress.completed = true
        progress.lastPracticed = Date()
        progress.accuracy = max(progress.accuracy, accuracy)
        progress.completedKeys.insert(key.tonic.rawValue)

        // Update mastery level based on accuracy
        if accuracy >= 0.9 {
            progress.masteryLevel = min(progress.masteryLevel + 1, 5)
        } else if accuracy < 0.5 {
            progress.masteryLevel = max(progress.masteryLevel - 1, 0)
        }

        // Schedule next review
        let intervalIndex = min(progress.masteryLevel, reviewIntervals.count - 1)
        let daysUntilReview = reviewIntervals[intervalIndex]
        progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: daysUntilReview, to: Date())

        exerciseProgress[exerciseId] = progress
        saveProgress()

        // Add to quiz queue if appropriate
        updateQuizQueue(for: progress)
    }

    /// Get progress for a specific exercise
    func getProgress(for exerciseId: String) -> ExerciseProgress? {
        return exerciseProgress[exerciseId]
    }

    /// Check if an exercise is completed
    func isCompleted(_ exerciseId: String) -> Bool {
        return exerciseProgress[exerciseId]?.completed ?? false
    }

    /// Get overall completion percentage for a bassline
    func completionPercentage(for basslineId: String, exercises: [Exercise]) -> Double {
        let basslineExercises = exercises.filter { $0.basslineId == basslineId }
        guard !basslineExercises.isEmpty else { return 0 }

        let completedCount = basslineExercises.filter { isCompleted($0.id) }.count
        return Double(completedCount) / Double(basslineExercises.count)
    }

    /// Get the next exercise to practice (considering spaced repetition)
    func nextExerciseToPractice(from exercises: [Exercise]) -> Exercise? {
        // First, check for exercises due for review
        let now = Date()
        for exercise in exercises {
            if let progress = exerciseProgress[exercise.id],
               let reviewDate = progress.nextReviewDate,
               reviewDate <= now {
                return exercise
            }
        }

        // Otherwise, return first incomplete exercise
        return exercises.first { !isCompleted($0.id) }
    }

    /// Get exercises that are due for quiz/review
    func exercisesDueForReview() -> [String] {
        let now = Date()
        return exerciseProgress.compactMap { (id, progress) in
            if let reviewDate = progress.nextReviewDate, reviewDate <= now {
                return id
            }
            return nil
        }
    }

    /// Reset all progress
    func resetAllProgress() {
        exerciseProgress = [:]
        quizQueue = []
        saveProgress()
    }

    // MARK: - Quiz Management

    /// Get the next quiz item if one is due
    func getNextQuiz() -> QuizItem? {
        updateQuizQueueForToday()
        return quizQueue.first
    }

    /// Complete a quiz item
    func completeQuiz(_ quizItem: QuizItem, wasCorrect: Bool) {
        quizQueue.removeAll { $0.id == quizItem.id }

        // Update the exercise progress
        if var progress = exerciseProgress[quizItem.exerciseId] {
            if wasCorrect {
                progress.masteryLevel = min(progress.masteryLevel + 1, 5)
            } else {
                progress.masteryLevel = max(progress.masteryLevel - 1, 0)
            }

            // Schedule next review
            let intervalIndex = min(progress.masteryLevel, reviewIntervals.count - 1)
            let daysUntilReview = reviewIntervals[intervalIndex]
            progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: daysUntilReview, to: Date())

            exerciseProgress[quizItem.exerciseId] = progress
        }

        saveProgress()
    }

    /// Check if user should take a quiz before continuing
    /// Note: Call refreshQuizQueue() in onAppear to update the queue first
    func shouldShowQuiz() -> Bool {
        return !quizQueue.isEmpty
    }

    /// Refresh the quiz queue - call this in onAppear, not during view body evaluation
    func refreshQuizQueue() {
        updateQuizQueueForToday()
    }

    // MARK: - Private Methods

    private func loadProgress() {
        if let data = userDefaults.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([String: ExerciseProgress].self, from: data) {
            exerciseProgress = decoded
        }

        if let queueData = userDefaults.data(forKey: quizQueueKey),
           let decodedQueue = try? JSONDecoder().decode([QuizItem].self, from: queueData) {
            quizQueue = decodedQueue
        }
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(exerciseProgress) {
            userDefaults.set(encoded, forKey: progressKey)
        }

        if let queueEncoded = try? JSONEncoder().encode(quizQueue) {
            userDefaults.set(queueEncoded, forKey: quizQueueKey)
        }
    }

    private func updateQuizQueue(for progress: ExerciseProgress) {
        // Add to quiz queue if mastery level is low enough to warrant review
        if progress.masteryLevel < 3 && !quizQueue.contains(where: { $0.exerciseId == progress.id }) {
            let quizItem = QuizItem(
                id: UUID().uuidString,
                exerciseId: progress.id,
                dueDate: progress.nextReviewDate ?? Date(),
                keyToQuiz: progress.completedKeys.randomElement() ?? "C"
            )
            quizQueue.append(quizItem)
            quizQueue.sort { $0.dueDate < $1.dueDate }
        }
    }

    private func updateQuizQueueForToday() {
        let now = Date()

        // Check for exercises due for review
        for (id, progress) in exerciseProgress {
            if let reviewDate = progress.nextReviewDate,
               reviewDate <= now,
               !quizQueue.contains(where: { $0.exerciseId == id }) {

                let quizItem = QuizItem(
                    id: UUID().uuidString,
                    exerciseId: id,
                    dueDate: reviewDate,
                    keyToQuiz: progress.completedKeys.randomElement() ?? "C"
                )
                quizQueue.append(quizItem)
            }
        }

        quizQueue.sort { $0.dueDate < $1.dueDate }
    }
}

// MARK: - Quiz Item Model

struct QuizItem: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let dueDate: Date
    let keyToQuiz: String  // Key to quiz in (may be transposed from original)
}

// MARK: - Statistics

extension ProgressManager {

    /// Total exercises completed
    var totalCompleted: Int {
        exerciseProgress.values.filter { $0.completed }.count
    }

    /// Average accuracy across all exercises
    var averageAccuracy: Double {
        let completedExercises = exerciseProgress.values.filter { $0.completed }
        guard !completedExercises.isEmpty else { return 0 }
        let totalAccuracy = completedExercises.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(completedExercises.count)
    }

    /// Number of exercises at each mastery level
    func exercisesAtMasteryLevel(_ level: Int) -> Int {
        exerciseProgress.values.filter { $0.masteryLevel == level }.count
    }

    /// Days since last practice
    var daysSinceLastPractice: Int? {
        let lastPracticed = exerciseProgress.values.compactMap { $0.lastPracticed }.max()
        guard let last = lastPracticed else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }
}
