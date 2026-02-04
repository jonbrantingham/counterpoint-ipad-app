//
//  GrandStaffView.swift
//  Counterpoint
//
//  Renders a grand staff with treble and bass clefs
//

import SwiftUI

struct GrandStaffView: View {
    let bassNotes: [Note]
    let sopranoNotes: [Note]
    let placedNotes: [PlacedNoteDisplay]
    let key: Key
    let showSoprano: Bool
    let onTapPosition: ((Int, Pitch) -> Void)?  // (beatIndex, pitch)

    // Layout constants
    private let staffLineSpacing: CGFloat = 12
    private let staffLineCount = 5
    private let staffGap: CGFloat = 50  // Gap between treble and bass staves
    private let noteWidth: CGFloat = 40
    private let clefWidth: CGFloat = 40
    private let keySignatureWidth: CGFloat = 30
    private let leftMargin: CGFloat = 20

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
            let availableWidth = geometry.size.width - leftMargin - clefWidth - keySignatureWidth - 40
            let noteSpacing = max(noteWidth, availableWidth / CGFloat(totalNotes))

            ZStack {
                // Staff lines
                staffLines(in: geometry)

                // Clefs
                clefs(in: geometry)

                // Key signature
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
                    path.addLine(to: CGPoint(x: geometry.size.width - leftMargin, y: y))
                }
                .stroke(Color.primary.opacity(0.6), lineWidth: 1)
            }

            // Bass staff lines
            ForEach(0..<staffLineCount, id: \.self) { line in
                Path { path in
                    let y = bassTop + CGFloat(line) * staffLineSpacing
                    path.move(to: CGPoint(x: leftMargin, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width - leftMargin, y: y))
                }
                .stroke(Color.primary.opacity(0.6), lineWidth: 1)
            }

            // Bar lines at start and end
            Path { path in
                path.move(to: CGPoint(x: leftMargin, y: trebleTop))
                path.addLine(to: CGPoint(x: leftMargin, y: bassTop + CGFloat(staffLineCount - 1) * staffLineSpacing))
            }
            .stroke(Color.primary.opacity(0.6), lineWidth: 1)

            Path { path in
                let x = geometry.size.width - leftMargin
                path.move(to: CGPoint(x: x, y: trebleTop))
                path.addLine(to: CGPoint(x: x, y: bassTop + CGFloat(staffLineCount - 1) * staffLineSpacing))
            }
            .stroke(Color.primary.opacity(0.6), lineWidth: 2)
        }
    }

    // MARK: - Clefs (drawn with paths)

    private func clefs(in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)

        return ZStack {
            // Treble clef - G clef wraps around the G line (2nd line from bottom)
            // The clef extends from below the staff to above
            TrebleClefShape()
                .stroke(Color.primary, lineWidth: 2.5)
                .frame(width: 28, height: staffLineSpacing * 6)
                .position(x: leftMargin + 20, y: trebleTop + staffLineSpacing * 2.5)

            // Bass clef - F clef with dots around the F line (2nd line from top)
            BassClefShape()
                .fill(Color.primary)
                .frame(width: 26, height: staffLineSpacing * 3)
                .position(x: leftMargin + 18, y: bassTop + staffLineSpacing * 1.5)
        }
    }

    // MARK: - Key Signature

    private func keySignature(in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)
        let baseX = leftMargin + clefWidth + 8
        let fifths = key.fifths

        // Sharps order on treble clef: F C G D A E B (staff positions relative to E4=2)
        // F5=8, C5=5, G5=11, D5=8, A4=5, E5=9, B4=6 - adjusted for treble
        let trebleSharpsPositions = [8, 5, 9, 6, 3, 7, 4]  // F C G D A E B on treble staff
        let bassSharpsPositions = [-2, -5, -1, -4, -7, -3, -6]  // F C G D A E B on bass staff

        // Flats order on treble clef: B E A D G C F
        let trebleFlatsPositions = [4, 7, 3, 6, 2, 5, 1]  // B E A D G C F on treble staff
        let bassFlatsPositions = [-6, -3, -7, -4, -8, -5, -9]  // B E A D G C F on bass staff

        return ZStack {
            if fifths > 0 {
                // Sharp key signature
                ForEach(0..<fifths, id: \.self) { index in
                    // Treble clef sharp
                    SharpShape()
                        .stroke(Color.primary, lineWidth: 1.5)
                        .frame(width: 10, height: staffLineSpacing * 2)
                        .position(
                            x: baseX + CGFloat(index) * 10,
                            y: yPositionForStaffPosition(trebleSharpsPositions[index], trebleTop: trebleTop)
                        )

                    // Bass clef sharp
                    SharpShape()
                        .stroke(Color.primary, lineWidth: 1.5)
                        .frame(width: 10, height: staffLineSpacing * 2)
                        .position(
                            x: baseX + CGFloat(index) * 10,
                            y: yPositionForStaffPosition(bassSharpsPositions[index], bassTop: bassTop)
                        )
                }
            } else if fifths < 0 {
                // Flat key signature
                let numFlats = abs(fifths)
                ForEach(0..<numFlats, id: \.self) { index in
                    // Treble clef flat
                    FlatShape()
                        .stroke(Color.primary, lineWidth: 1.5)
                        .frame(width: 8, height: staffLineSpacing * 2)
                        .position(
                            x: baseX + CGFloat(index) * 9,
                            y: yPositionForStaffPosition(trebleFlatsPositions[index], trebleTop: trebleTop)
                        )

                    // Bass clef flat
                    FlatShape()
                        .stroke(Color.primary, lineWidth: 1.5)
                        .frame(width: 8, height: staffLineSpacing * 2)
                        .position(
                            x: baseX + CGFloat(index) * 9,
                            y: yPositionForStaffPosition(bassFlatsPositions[index], bassTop: bassTop)
                        )
                }
            }
            // C major has no sharps or flats, so nothing is drawn
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
        let g2Position = -9  // G2 is on the bottom line of bass clef
        return bassBottom - CGFloat(position - g2Position) * (staffLineSpacing / 2)
    }

    // MARK: - Note Heads

    private func noteHead(for note: Note, at index: Int, isBass: Bool, noteSpacing: CGFloat, in geometry: GeometryProxy) -> some View {
        let xPosition = noteXPosition(at: index, noteSpacing: noteSpacing)
        let yPosition = noteYPosition(for: note.pitch, isBass: isBass, in: geometry)

        return ZStack {
            // Ledger lines if needed
            ledgerLines(for: note.pitch, isBass: isBass, at: xPosition, in: geometry)

            // Note head (whole note - ellipse with hollow center)
            WholeNoteShape()
                .stroke(Color.primary, lineWidth: 1.5)
                .frame(width: staffLineSpacing * 1.4, height: staffLineSpacing * 0.9)
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

            // Note head
            WholeNoteShape()
                .stroke(color, lineWidth: 2)
                .frame(width: staffLineSpacing * 1.4, height: staffLineSpacing * 0.9)
                .opacity(opacity)
                .position(x: xPosition, y: yPosition)

            // Show interval for incorrect notes
            if case .incorrect(let interval) = placedNote.state {
                Text(interval)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .position(x: xPosition, y: yPosition - staffLineSpacing * 1.5)
            }
        }
    }

    // MARK: - Ledger Lines

    private func ledgerLines(for pitch: Pitch, isBass: Bool, at xPosition: CGFloat, in geometry: GeometryProxy) -> some View {
        let trebleTop = trebleStaffTop(in: geometry)
        let bassTop = bassStaffTop(in: geometry)
        let staffBottom = { (top: CGFloat) in top + CGFloat(staffLineCount - 1) * staffLineSpacing }

        // Calculate staff position relative to middle C
        let position = pitch.staffPosition

        var ledgerLineYPositions: [CGFloat] = []

        if !isBass {
            // Treble clef: middle C (position 0) is one ledger line below staff
            // Treble staff bottom line is E4 (position 2)
            // Treble staff top line is F5 (position 9)
            let staffBottomPosition = 2  // E4
            let staffTopPosition = 9     // F5

            if position <= staffBottomPosition - 2 {
                // Notes below the staff - need ledger lines
                var linePosition = staffBottomPosition - 2  // D4
                while linePosition >= position {
                    let y = staffBottom(trebleTop) + CGFloat(staffBottomPosition - linePosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition -= 2
                }
            } else if position >= staffTopPosition + 2 {
                // Notes above the staff
                var linePosition = staffTopPosition + 2
                while linePosition <= position {
                    let y = trebleTop - CGFloat(linePosition - staffTopPosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition += 2
                }
            }
        } else {
            // Bass clef: middle C (position 0) is one ledger line above staff
            // Bass staff top line is A3 (position -2)
            // Bass staff bottom line is G2 (position -9)
            let staffTopPosition = -2    // A3
            let staffBottomPosition = -9 // G2

            if position >= staffTopPosition + 2 {
                // Notes above the staff (including middle C)
                var linePosition = staffTopPosition + 2  // C4
                while linePosition <= position {
                    let y = bassTop - CGFloat(linePosition - staffTopPosition) * (staffLineSpacing / 2)
                    ledgerLineYPositions.append(y)
                    linePosition += 2
                }
            } else if position <= staffBottomPosition - 2 {
                // Notes below the staff
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
                path.move(to: CGPoint(x: xPosition - 12, y: y))
                path.addLine(to: CGPoint(x: xPosition + 12, y: y))
            }
            .stroke(Color.primary.opacity(0.6), lineWidth: 1)
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

                        // Only respond to taps in the treble staff area (for soprano input)
                        if location.y >= trebleTop - staffLineSpacing * 3 &&
                           location.y <= bassTop - staffGap / 2 {

                            // Calculate beat index from x position
                            let noteStartX = leftMargin + clefWidth + keySignatureWidth + 20
                            let beatIndex = Int((location.x - noteStartX) / noteSpacing)

                            if beatIndex >= 0 && beatIndex < totalNotes {
                                // Calculate pitch directly using the same geometry
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
        leftMargin + clefWidth + keySignatureWidth + 20 + CGFloat(index) * noteSpacing + noteSpacing / 2
    }

    private func noteYPosition(for pitch: Pitch, isBass: Bool, in geometry: GeometryProxy) -> CGFloat {
        let position = pitch.staffPosition

        if !isBass {
            // Treble clef: E4 (position 2) is on the bottom line
            let trebleBottom = trebleStaffTop(in: geometry) + CGFloat(staffLineCount - 1) * staffLineSpacing
            let e4Position = 2
            return trebleBottom - CGFloat(position - e4Position) * (staffLineSpacing / 2)
        } else {
            // Bass clef: G2 (position -9) is on the bottom line
            let bassBottom = bassStaffTop(in: geometry) + CGFloat(staffLineCount - 1) * staffLineSpacing
            let g2Position = -9
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

// MARK: - Custom Shapes

/// Whole note shape (ellipse)
struct WholeNoteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Outer ellipse
        path.addEllipse(in: rect)
        return path
    }
}

/// Treble clef (G clef) shape - more authentic appearance
struct TrebleClefShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // The treble clef has several parts:
        // 1. A vertical line with a curl at bottom
        // 2. A spiral in the middle that circles around the G line
        // 3. A curve at the top

        // Start from the bottom curl
        path.move(to: CGPoint(x: w * 0.45, y: h * 0.98))

        // Bottom curl going left then up
        path.addCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.85),
            control1: CGPoint(x: w * 0.15, y: h * 0.98),
            control2: CGPoint(x: w * 0.1, y: h * 0.92)
        )

        // Rising up the left side
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.55),
            control1: CGPoint(x: w * 0.35, y: h * 0.75),
            control2: CGPoint(x: w * 0.3, y: h * 0.62)
        )

        // The inner spiral around G line (at h * 0.5)
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.48),
            control1: CGPoint(x: w * 0.72, y: h * 0.52),
            control2: CGPoint(x: w * 0.78, y: h * 0.5)
        )

        // Continue spiral
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.52),
            control1: CGPoint(x: w * 0.65, y: h * 0.42),
            control2: CGPoint(x: w * 0.45, y: h * 0.4)
        )

        // Complete the inner loop and go up
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.25),
            control1: CGPoint(x: w * 0.25, y: h * 0.45),
            control2: CGPoint(x: w * 0.32, y: h * 0.32)
        )

        // Top curve
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.05),
            control1: CGPoint(x: w * 0.62, y: h * 0.18),
            control2: CGPoint(x: w * 0.65, y: h * 0.08)
        )

        // Curve down to form the top ornament
        path.addCurve(
            to: CGPoint(x: w * 0.38, y: h * 0.12),
            control1: CGPoint(x: w * 0.48, y: h * 0.02),
            control2: CGPoint(x: w * 0.35, y: h * 0.05)
        )

        return path
    }
}

/// Bass clef (F clef) shape - more authentic appearance
struct BassClefShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // The bass clef starts with a filled dot on the F line, then curves down

        // Main body - starts thick at top, curves down
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.08))

        // The head/dot part (filled circle at F line)
        path.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.02, width: w * 0.28, height: h * 0.22))

        // Main curved body going down from the dot
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.13))
        path.addCurve(
            to: CGPoint(x: w * 0.6, y: h * 0.25),
            control1: CGPoint(x: w * 0.5, y: h * 0.1),
            control2: CGPoint(x: w * 0.58, y: h * 0.15)
        )

        // Curve down and back
        path.addCurve(
            to: CGPoint(x: w * 0.2, y: h * 0.85),
            control1: CGPoint(x: w * 0.7, y: h * 0.45),
            control2: CGPoint(x: w * 0.5, y: h * 0.75)
        )

        // Two dots to the right (between 3rd and 4th lines relative to F)
        let dotSize = w * 0.15
        path.addEllipse(in: CGRect(x: w * 0.72, y: h * 0.18, width: dotSize, height: dotSize))
        path.addEllipse(in: CGRect(x: w * 0.72, y: h * 0.42, width: dotSize, height: dotSize))

        return path
    }
}

/// Sharp symbol (♯) shape
struct SharpShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Two vertical lines (slightly tilted)
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.9))

        path.move(to: CGPoint(x: w * 0.65, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.9))

        // Two horizontal lines (thicker, tilted up to the right)
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.28))

        path.move(to: CGPoint(x: w * 0.1, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.62))

        return path
    }
}

/// Flat symbol (♭) shape
struct FlatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Vertical stem
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.95))

        // The curved part (like a backwards "b")
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.65),
            control1: CGPoint(x: w * 0.5, y: h * 0.45),
            control2: CGPoint(x: w * 0.85, y: h * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.95),
            control1: CGPoint(x: w * 0.85, y: h * 0.85),
            control2: CGPoint(x: w * 0.5, y: h * 0.95)
        )

        return path
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
        key: .cMajor,
        showSoprano: true,
        onTapPosition: nil
    )
    .frame(height: 300)
    .padding()
}
