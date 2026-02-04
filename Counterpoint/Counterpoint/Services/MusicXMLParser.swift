//
//  MusicXMLParser.swift
//  Counterpoint
//
//  Parses MusicXML files to extract exercise content
//

import Foundation

class MusicXMLParser: NSObject, XMLParserDelegate {

    // MARK: - Properties

    private var currentElement = ""
    private var currentText = ""

    // Parsing state
    private var currentPitch: (step: String?, octave: Int?, alter: Int?) = (nil, nil, nil)
    private var currentDuration: Int = 4
    private var currentDivisions: Int = 1
    private var currentStaff: Int = 1
    private var currentVoice: Int = 1

    // Key signature
    private var fifths: Int = 0

    // Collected notes
    private var trebleNotes: [Note] = []
    private var bassNotes: [Note] = []
    private var currentBeatPosition: Double = 0

    // Metadata
    private var workTitle: String = ""
    private var partName: String = ""

    // MARK: - Public Methods

    /// Parse MusicXML data and return an Exercise
    func parse(data: Data, exerciseId: String, basslineId: String, patternName: String) -> Exercise? {
        // Reset state
        resetState()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard !bassNotes.isEmpty else {
            print("No bass notes found in MusicXML")
            return nil
        }

        let key = keyFromFifths(fifths)

        return Exercise(
            id: exerciseId,
            name: workTitle.isEmpty ? patternName : workTitle,
            basslineId: basslineId,
            species: .first,
            key: key,
            bassLine: Voice(notes: bassNotes),
            sopranoSolutions: [Voice(notes: trebleNotes)],
            patternName: patternName
        )
    }

    /// Parse MusicXML from a file URL
    func parse(url: URL, exerciseId: String, basslineId: String, patternName: String) -> Exercise? {
        guard let data = try? Data(contentsOf: url) else {
            print("Could not read file at \(url)")
            return nil
        }
        return parse(data: data, exerciseId: exerciseId, basslineId: basslineId, patternName: patternName)
    }

    // MARK: - Private Methods

    private func resetState() {
        currentElement = ""
        currentText = ""
        currentPitch = (nil, nil, nil)
        currentDuration = 4
        currentDivisions = 1
        currentStaff = 1
        currentVoice = 1
        fifths = 0
        trebleNotes = []
        bassNotes = []
        currentBeatPosition = 0
        workTitle = ""
        partName = ""
    }

    private func keyFromFifths(_ fifths: Int) -> Key {
        switch fifths {
        case 0: return Key(tonic: .c, mode: .major)
        case 1: return Key(tonic: .g, mode: .major)
        case 2: return Key(tonic: .d, mode: .major)
        case 3: return Key(tonic: .a, mode: .major)
        case 4: return Key(tonic: .e, mode: .major)
        case 5: return Key(tonic: .b, mode: .major)
        case -1: return Key(tonic: .f, mode: .major)
        default: return Key(tonic: .c, mode: .major)
        }
    }

    private func noteNameFromStep(_ step: String) -> NoteName? {
        switch step.uppercased() {
        case "C": return .c
        case "D": return .d
        case "E": return .e
        case "F": return .f
        case "G": return .g
        case "A": return .a
        case "B": return .b
        default: return nil
        }
    }

    private func durationFromDivisions(_ duration: Int, divisions: Int) -> NoteDuration {
        let beats = Double(duration) / Double(divisions)
        switch beats {
        case 4.0...: return .whole
        case 2.0..<4.0: return .half
        case 1.0..<2.0: return .quarter
        default: return .eighth
        }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""

        if elementName == "note" {
            // Reset note state
            currentPitch = (nil, nil, nil)
            currentStaff = 1
            currentVoice = 1
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "work-title":
            workTitle = text

        case "part-name":
            partName = text

        case "divisions":
            currentDivisions = Int(text) ?? 1

        case "fifths":
            fifths = Int(text) ?? 0

        case "step":
            currentPitch.step = text

        case "octave":
            currentPitch.octave = Int(text)

        case "alter":
            currentPitch.alter = Int(text)

        case "duration":
            currentDuration = Int(text) ?? currentDivisions

        case "staff":
            currentStaff = Int(text) ?? 1

        case "voice":
            currentVoice = Int(text) ?? 1

        case "note":
            // Create note if we have valid pitch info
            if let step = currentPitch.step,
               let octave = currentPitch.octave,
               let noteName = noteNameFromStep(step) {

                let pitch = Pitch(noteName: noteName, octave: octave)
                let duration = durationFromDivisions(currentDuration, divisions: currentDivisions)
                let note = Note(pitch: pitch, duration: duration, beatPosition: currentBeatPosition)

                // Staff 1 is typically treble, staff 2 is bass in grand staff
                // But we also check voice: voice 1 is usually soprano, voice 2+ can be bass
                if currentStaff == 2 || (currentStaff == 1 && currentVoice >= 2) {
                    bassNotes.append(note)
                } else {
                    trebleNotes.append(note)
                }

                currentBeatPosition += duration.beats
            }

        case "forward":
            // Move forward in time (for rests, etc.)
            let forwardBeats = Double(currentDuration) / Double(currentDivisions)
            currentBeatPosition += forwardBeats

        case "backup":
            // Move backward in time
            let backupBeats = Double(currentDuration) / Double(currentDivisions)
            currentBeatPosition -= backupBeats

        case "measure":
            // Reset beat position for each measure (simplified)
            // In a real implementation, we'd track measure numbers
            break

        default:
            break
        }

        currentElement = ""
    }
}
