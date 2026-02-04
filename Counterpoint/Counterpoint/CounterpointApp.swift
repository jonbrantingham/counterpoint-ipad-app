//
//  CounterpointApp.swift
//  Counterpoint
//
//  Counterpoint Training App - Learn two-part counterpoint through pattern recognition
//

import SwiftUI

@main
struct CounterpointApp: App {
    @StateObject private var progressManager = ProgressManager()
    @StateObject private var audioEngine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressManager)
                .environmentObject(audioEngine)
        }
    }
}
