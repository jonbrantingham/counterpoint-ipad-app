//
//  ContentView.swift
//  Counterpoint
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @State private var showingExercise = false
    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HeaderView()

                // Main content
                if let exercise = selectedExercise {
                    ExerciseView(
                        exercise: exercise,
                        onDismiss: {
                            selectedExercise = nil
                        },
                        onComplete: {
                            handleExerciseComplete()
                        }
                    )
                } else {
                    ExerciseSelectionView(onSelectExercise: { exercise in
                        selectedExercise = exercise
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }

    private func handleExerciseComplete() {
        if let exercise = selectedExercise {
            progressManager.markExerciseCompleted(exercise.id)
        }
        selectedExercise = nil
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Counterpoint")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(ProgressManager())
        .environmentObject(AudioEngine())
}
