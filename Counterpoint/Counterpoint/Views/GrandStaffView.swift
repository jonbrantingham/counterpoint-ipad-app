//
//  GrandStaffView.swift
//  Counterpoint
//
//  Renders a grand staff with treble and bass clefs using SMuFL-compliant fonts
//  https://www.smufl.org/
//  https://w3c.github.io/smufl/latest/index.html
//

import SwiftUI

struct GrandStaffView: View {
    let bassNotes: [Note]
    let sopranoNotes: [Note]
    let placedNotes: [PlacedNoteDisplay]
    let key: Key
    let showSoprano: Bool
    let onTapPosition: ((Int, Pitch) -> Void)?  // (beatIndex, pitch)
    var scale: CGFloat = 1.0  // Scale factor for staff size (0.8 to 2.0)
    var figuredBass: [String]? = nil  // Optional figured bass notation (e.g., ["8", "7", "8"])
    var hintNote: Note? = nil  // Optional starting note hint
    var hintBeatIndex: Int = 0

    // Layout constants - base values before scaling
    private let baseStaffLineSpacing: CGFloat = 16  // Base spacing for touch targets
    private let staffLineCount = 5
    private let baseStaffGap: CGFloat = 70  // Gap between treble and bass staves
    private let baseClefWidth: CGFloat = 50
    private let baseKeySignatureWidth: CGFloat = 50
    private let baseLeftMargin: CGFloat = 15
    private let rightMargin: CGFloat = 25

    // Computed scaled values
    private var staffLineSpacing: CGFloat { baseStaffLineSpacing * scale }
    private var staffGap: CGFloat { baseStaffGap * scale }
    private var clefWidth: CGFloat { baseClefWidth * scale }
    private var keySignatureWidth: CGFloat { baseKeySignatureWidth * scale }
    private var leftMargin: CGFloat {
        if scale >= 2.0 {
            return -4  // Slight overhang at largest size
        }
        return baseLeftMargin
    }

    // SMuFL font sizing - the font size should be 4x the staff line spacing
    // per SMuFL specification for proper glyph scaling
    private var smuflFontSize: CGFloat { staffLineSpacing * 4 }

    struct PlacedNoteDisplay: Identifiable {
        let id: UUID
        let pitch: Pitch
        let beatIndex: Int
        var state: NoteState

        enum NoteState {
            case normal
            case correct
            case incorrect(interval: String)
            case fading
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let totalNotes = max(bassNotes.count, sopranoNotes.count, 1)
            let availableWidth = geometry.size.width - leftMargin - clefWidth - keySignatureWidth - rightMargin
            let noteSpacing = max(staffLineSpacing * 3, availableWidth / CGFloat(totalNotes))

            ZStack {
                // Staff lines
                staffLines(in: geometry)

                // Clefs (using SMuFL)
                clefs(in: geometry)

                // Key signature (using SMuFL)
                keySignature(in: geometry)

                // Bass notes (always visible)
                ForEach(Array(bassNotes.enumerated()), id: \.offset) { index, note in
                    noteHead(
                        for: note,
                        at: index,
                        isBass: true,
                        noteSpacing: noteSpacing,
                        in: geometry
                    )
                }

                // Figured bass notation (above bass notes)
                if let figures = figuredBass {
                    figuredBassNotation(figures: figures, noteSpacing: noteSpacing, in: geometry)
                }

                // Starting note hint (light gray)
                if let hintNote = hintNote {
                    hintNoteHead(
                        hintNote,
                        at: hintBeatIndex,
                        noteSpacing: noteSpacing,
                        in: geometry
                    )
                }

                // Soprano notes (conditionally visible)
                if showSoprano {
                    ForEach(Array(sopranoNotes.enumerated()), id: \.offset) { index, note in
                        noteHead(
                            for: note,
                            at: index,
                            isBass: false,
                            noteSpacing: noteSpacing,
                            in: geometry
                        )
                    }
                }

                // Placed notes from user
                ForEach(placedNotes) { placedNote in
                    placedNoteHead(
                        placedNote,
                        noteSpacing: noteSpacing,
                        in: geometry
                    )
                }

                // Touch target overlay
                if onTapPosition != nil {
                    touchOverlay(noteSpacing: noteSpacing, totalNotes: totalNotes, in: geometry)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Staff Lines

    private func staffLines(in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)

        return ZStack {
            // Treble staff lines
            ForEach(0..<staffLineCount, id: \.self) { line in
                Path { path in
                    let y = trebleTop + CGFloat(line) * staffLineSpacing
                    path.move(to: CGPoint(x: leftMargin, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width - rightMargin, y: y))
                }
                .stroke(Color.primary.opacity(0.7), lineWidth: 1)
            }

            // Bass staff lines
            ForEach(0..<staffLineCount, id: \.self) { line in
                Path { path in
                    let y = bassTop + CGFloat(line) * staffLineSpacing
                    path.move(to: CGPoint(x: leftMargin, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width - rightMargin, y: y))
                }
                .stroke(Color.primary.opacity(0.7), lineWidth: 1)
            }

            // Bar line at start (connecting both staves)
            Path { path in
                path.move(to: CGPoint(x: leftMargin, y: trebleTop))
                path.addLine(to: CGPoint(x: leftMargin, y: bassTop + CGFloat(staffLineCount - 1) * staffLineSpacing))
            }
            .stroke(Color.primary.opacity(0.7), lineWidth: 1.5)

            // Final bar line at end
            Path { path in
                let x = geometry.size.width - rightMargin
                path.move(to: CGPoint(x: x, y: trebleTop))
                path.addLine(to: CGPoint(x: x, y: bassTop + CGFloat(staffLineCount - 1) * staffLineSpacing))
            }
            .stroke(Color.primary.opacity(0.7), lineWidth: 2)
        }
    }

    // MARK: - Figured Bass Notation

    private func figuredBassNotation(figures: [String], noteSpacing: CGFloat, in geometry: GeometryProxy) -> some View {
        let bassTop = bassStaffTop(in: geometry)
        // Position figures above the bass staff (between treble and bass)
        let figureY = bassTop - staffGap / 2

        return ForEach(Array(figures.enumerated()), id: \.offset) { index, figure in
            Text(figure)
                .font(.system(size: staffLineSpacing * 1.2, weight: .medium, design: .serif))
                .foregroundColor(.secondary)
                .position(
                    x: noteXPosition(at: index, noteSpacing: noteSpacing),
                    y: figureY
                )
        }
    }

    // MARK: - Clefs (SMuFL)

    private func clefs(in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)

        return ZStack {
            // Treble clef (G clef) - baseline is on the G line (2nd line from bottom)
            // In SMuFL, the G clef's origin point is at the G line
            Text(SMuFL.gClef)
                .font(.custom(SMuFL.fontName, size: smuflFontSize))
                .foregroundColor(.primary)
                .position(x: leftMargin + 25, y: trebleTop + staffLineSpacing * 3)

            // Bass clef (F clef) - baseline is on the F line (2nd line from top)
            // In SMuFL, the F clef's origin point is at the F line
            Text(SMuFL.fClef)
                .font(.custom(SMuFL.fontName, size: smuflFontSize))
                .foregroundColor(.primary)
                .position(x: leftMargin + 25, y: bassTop + staffLineSpacing)
        }
    }

    // MARK: - Key Signature (SMuFL)

    private func keySignature(in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)
        let baseX = leftMargin + clefWidth + 5
        let fifths = key.fifths
        let accidentalSpacing: CGFloat = staffLineSpacing * 0.8

        // Sharp positions on staff (relative to staff position system)
        // Treble: F5, C5, G5, D5, A4, E5, B4
        let trebleSharpsPositions = [10, 7, 11, 8, 5, 9, 6]
        // Bass: F3, C3, G3, D3, A2, E3, B2
        let bassSharpsPositions = [-4, -7, -3, -6, -9, -5, -8]

        // Flat positions on staff
        // Treble: B4, E5, A4, D5, G4, C5, F4
        let trebleFlatsPositions = [6, 9, 5, 8, 4, 7, 3]
        // Bass: B2, E3, A2, D3, G2, C3, F2
        let bassFlatsPositions = [-8, -5, -9, -6, -10, -7, -11]

        return ZStack {
            if fifths > 0 {
                // Sharp key signature
                ForEach(0..<fifths, id: \.self) { index in
                    // Treble clef sharp
                    Text(SMuFL.accidentalSharp)
                        .font(.custom(SMuFL.fontName, size: smuflFontSize * 0.7))
                        .foregroundColor(.primary)
                        .position(
                            x: baseX + CGFloat(index) * accidentalSpacing,
                            y: yPositionForStaffPosition(trebleSharpsPositions[index], trebleTop: trebleTop)
                        )

                    // Bass clef sharp
                    Text(SMuFL.accidentalSharp)
                        .font(.custom(SMuFL.fontName, size: smuflFontSize * 0.7))
                        .foregroundColor(.primary)
                        .position(
                            x: baseX + CGFloat(index) * accidentalSpacing,
                            y: yPositionForStaffPosition(bassSharpsPositions[index], bassTop: bassTop)
                        )
                }
            } else if fifths < 0 {
                // Flat key signature
                let numFlats = abs(fifths)
                ForEach(0..<numFlats, id: \.self) { index in
                    // Treble clef flat
                    Text(SMuFL.accidentalFlat)
                        .font(.custom(SMuFL.fontName, size: smuflFontSize * 0.7))
                        .foregroundColor(.primary)
                        .position(
                            x: baseX + CGFloat(index) * accidentalSpacing,
                            y: yPositionForStaffPosition(trebleFlatsPositions[index], trebleTop: trebleTop)
                        )

                    // Bass clef flat
                    Text(SMuFL.accidentalFlat)
                        .font(.custom(SMuFL.fontName, size: smuflFontSize * 0.7))
                        .foregroundColor(.primary)
                        .position(
                            x: baseX + CGFloat(index) * accidentalSpacing,
                            y: yPositionForStaffPosition(bassFlatsPositions[index], bassTop: bassTop)
                        )
                }
            }
        }
    }

    /// Calculate Y position for a staff position on the treble clef
    private func yPositionForStaffPosition(_ position: Int, trebleTop: CGFloat) -> CGFloat {
        let trebleBottom = trebleTop + CGFloat(staffLineCount - 1) * staffLineSpacing
        let e4Position = 2  // E4 is on the bottom line of treble clef
        return trebleBottom - CGFloat(position - e4Position) * (staffLineSpacing / 2)
    }

    /// Calculate Y position for a staff position on the bass clef
    private func yPositionForStaffPosition(_ position: Int, bassTop: CGFloat) -> CGFloat {
        let bassBottom = bassTop + CGFloat(staffLineCount - 1) * staffLineSpacing
        let g2Position = -10  // G2 is on the bottom line of bass clef (G=4, octave 2: 4+(2-4)*7 = -10)
        return bassBottom - CGFloat(position - g2Position) * (staffLineSpacing / 2)
    }

    // MARK: - Note Heads (SMuFL)

    private func noteHead(for note: Note, at index: Int, isBass: Bool, noteSpacing: CGFloat, in geometry: GeometryProxy) -> some View {
        let xPosition = noteXPosition(at: index, noteSpacing: noteSpacing)
        let yPosition = noteYPosition(for: note.pitch, isBass: isBass, in: geometry)

        return ZStack {
            // Ledger lines if needed
            ledgerLines(for: note.pitch, isBass: isBass, at: xPosition, in: geometry)

            // Note head using SMuFL glyph
            Text(SMuFL.notehead(for: note.duration))
                .font(.custom(SMuFL.fontName, size: smuflFontSize))
                .foregroundColor(.primary)
                .position(x: xPosition, y: yPosition)
        }
    }

    private func hintNoteHead(_ note: Note, at index: Int, noteSpacing: CGFloat, in geometry: GeometryProxy) -> some View {
        let xPosition = noteXPosition(at: index, noteSpacing: noteSpacing)
        let yPosition = noteYPosition(for: note.pitch, isBass: false, in: geometry)
        let hintColor = Color.secondary.opacity(0.4)

        return ZStack {
            // Ledger lines if needed
            ledgerLines(for: note.pitch, isBass: false, at: xPosition, in: geometry, color: hintColor)

            // Note head using SMuFL glyph
            Text(SMuFL.notehead(for: note.duration))
                .font(.custom(SMuFL.fontName, size: smuflFontSize))
                .foregroundColor(hintColor)
                .position(x: xPosition, y: yPosition)
        }
    }

    private func placedNoteHead(_ placedNote: PlacedNoteDisplay, noteSpacing: CGFloat, in geometry: GeometryProxy) -> some View {
        let xPosition = noteXPosition(at: placedNote.beatIndex, noteSpacing: noteSpacing)
        let yPosition = noteYPosition(for: placedNote.pitch, isBass: false, in: geometry)

        let color: Color
        let opacity: Double

        switch placedNote.state {
        case .normal:
            color = .blue
            opacity = 1.0
        case .correct:
            color = .green
            opacity = 1.0
        case .incorrect:
            color = .red
            opacity = 1.0
        case .fading:
            color = .red
            opacity = 0.3
        }

        return ZStack {
            // Ledger lines if needed
            ledgerLines(for: placedNote.pitch, isBass: false, at: xPosition, in: geometry)

            // Note head using SMuFL glyph
            Text(SMuFL.noteheadWhole)
                .font(.custom(SMuFL.fontName, size: smuflFontSize))
                .foregroundColor(color)
                .opacity(opacity)
                .position(x: xPosition, y: yPosition)

            // Show interval for incorrect notes
            if case .incorrect(let interval) = placedNote.state {
                Text(interval)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .position(x: xPosition, y: yPosition - staffLineSpacing * 1.8)
            }
        }
    }

    // MARK: - Ledger Lines

    private func ledgerLines(
        for pitch: Pitch,
        isBass: Bool,
        at xPosition: CGFloat,
        in geometry: GeometryProxy,
        color: Color = Color.primary.opacity(0.7)
    ) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)
        let staffBottom = { (top: CGFloat) in top + CGFloat(staffLineCount - 1) * staffLineSpacing }
        let ledgerLineWidth: CGFloat = staffLineSpacing * 1.8

        let position = pitch.staffPosition
        var ledgerLineYPositions: [CGFloat] = []

        if !isBass {
            // Treble clef positions
            let staffBottomPosition = 2  // E4
            let staffTopPosition = 10    // G5

            if position <= staffBottomPosition - 2 {
                var linePosition = staffBottomPosition - 2  // D4 (middle C is C4 = 0)
                while linePosition >= position {
                    let y = staffBottom(trebleTop) + CGFloat(staffBottomPosition - linePosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition -= 2
                }
            } else if position >= staffTopPosition + 2 {
                var linePosition = staffTopPosition + 2
                while linePosition <= position {
                    let y = trebleTop - CGFloat(linePosition - staffTopPosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition += 2
                }
            }
        } else {
            // Bass clef positions
            // Top line (A3): A=5, octave 3: 5+(3-4)*7 = -2
            // Bottom line (G2): G=4, octave 2: 4+(2-4)*7 = -10
            let staffTopPosition = -2    // A3 on top line
            let staffBottomPosition = -10 // G2 on bottom line

            if position >= staffTopPosition + 2 {
                var linePosition = staffTopPosition + 2  // C4 (middle C) = position 0
                while linePosition <= position {
                    let y = bassTop - CGFloat(linePosition - staffTopPosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition += 2
                }
            } else if position <= staffBottomPosition - 2 {
                var linePosition = staffBottomPosition - 2
                while linePosition >= position {
                    let y = staffBottom(bassTop) + CGFloat(staffBottomPosition - linePosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition -= 2
                }
            }
        }

        return ForEach(ledgerLineYPositions, id: \.self) { y in
            Path { path in
                path.move(to: CGPoint(x: xPosition - ledgerLineWidth / 2, y: y))
                path.addLine(to: CGPoint(x: xPosition + ledgerLineWidth / 2, y: y))
            }
            .stroke(color, lineWidth: 1)
        }
    }

    // MARK: - Touch Overlay

    private func touchOverlay(noteSpacing: CGFloat, totalNotes: Int, in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)

        return Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location

                        // Expanded touch area for treble staff (for soprano input)
                        // Allow touches above and below the staff for ledger line notes
                        if location.y >= trebleTop - staffLineSpacing * 4 &&
                           location.y <= bassTop - staffGap / 2 {

                            // Calculate beat index from x position
                            let noteStartX = leftMargin + clefWidth + keySignatureWidth + 10
                            let beatIndex = Int((location.x - noteStartX) / noteSpacing)

                            if beatIndex >= 0 && beatIndex < totalNotes {
                                let pitch = pitchFromYPosition(location.y, in: geometry)
                                onTapPosition?(beatIndex, pitch)
                            }
                        }
                    }
            )
    }

    // MARK: - Position Calculations

    private func trebleStaffTop(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.height / 2 - staffGap / 2 - CGFloat(staffLineCount - 1) * staffLineSpacing
    }

    private func bassStaffTop(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.height / 2 + staffGap / 2
    }

    private func noteXPosition(at index: Int, noteSpacing: CGFloat) -> CGFloat {
        leftMargin + clefWidth + keySignatureWidth + 15 + CGFloat(index) * noteSpacing + noteSpacing / 2
    }

    private func noteYPosition(for pitch: Pitch, isBass: Bool, in geometry: GeometryProxy) -> CGFloat {
        let position = pitch.staffPosition

        if !isBass {
            // Treble clef: E4 (position 2) is on the bottom line
            let trebleBottom = trebleStaffTop(in: geometry) + CGFloat(staffLineCount - 1) * staffLineSpacing
            let e4Position = 2
            return trebleBottom - CGFloat(position - e4Position) * (staffLineSpacing / 2)
        } else {
            // Bass clef: G2 (position -10) is on the bottom line
            // G2 = noteIndex 4 (G) + (2-4)*7 = 4 - 14 = -10
            let bassBottom = bassStaffTop(in: geometry) + CGFloat(staffLineCount - 1) * staffLineSpacing
            let g2Position = -10
            return bassBottom - CGFloat(position - g2Position) * (staffLineSpacing / 2)
        }
    }

    /// Convert a y position to a pitch (for touch input)
    func pitchFromYPosition(_ y: CGFloat, in geometry: GeometryProxy) -> Pitch {
        let trebleBottom = trebleStaffTop(in: geometry) + CGFloat(staffLineCount - 1) * staffLineSpacing
        let e4Position = 2

        // Calculate staff position from y
        let staffPosition = e4Position + Int(round((trebleBottom - y) / (staffLineSpacing / 2)))

        return Pitch.fromStaffPosition(staffPosition)
    }
}

// MARK: - Preview

#Preview {
    GrandStaffView(
        bassNotes: [
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .g, octave: 3), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 3), duration: .whole, beatPosition: 8)
        ],
        sopranoNotes: [
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 0),
            Note(pitch: Pitch(noteName: .b, octave: 4), duration: .whole, beatPosition: 4),
            Note(pitch: Pitch(noteName: .c, octave: 5), duration: .whole, beatPosition: 8)
        ],
        placedNotes: [],
        key: Key(tonic: .f, accidental: .natural, mode: .major),
        showSoprano: true,
        onTapPosition: nil,
        scale: 1.0
    )
    .frame(height: 350)
    .padding()
}
