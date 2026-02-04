//
//  SMuFLGlyphs.swift
//  Counterpoint
//
//  SMuFL (Standard Music Font Layout) glyph definitions
//  Using Bravura font - the reference implementation for SMuFL
//  https://www.smufl.org/
//  https://w3c.github.io/smufl/latest/index.html
//

import Foundation

/// SMuFL glyph codepoints for music notation
/// All codepoints are in Unicode's Private Use Area (U+E000-U+FFFF)
enum SMuFL {

    // MARK: - Clefs (U+E050-U+E07F)

    /// G clef (treble clef) - U+E050
    static let gClef = "\u{E050}"

    /// G clef ottava bassa - U+E052
    static let gClef8vb = "\u{E052}"

    /// G clef ottava alta - U+E053
    static let gClef8va = "\u{E053}"

    /// F clef (bass clef) - U+E062
    static let fClef = "\u{E062}"

    /// F clef ottava bassa - U+E064
    static let fClef8vb = "\u{E064}"

    /// F clef ottava alta - U+E065
    static let fClef8va = "\u{E065}"

    /// C clef (alto/tenor clef) - U+E05C
    static let cClef = "\u{E05C}"

    // MARK: - Noteheads (U+E0A0-U+E0FF)

    /// Double whole note (breve) - U+E0A0
    static let noteheadDoubleWhole = "\u{E0A0}"

    /// Whole note (semibreve) - U+E0A2
    static let noteheadWhole = "\u{E0A2}"

    /// Half note (minim) - U+E0A3
    static let noteheadHalf = "\u{E0A3}"

    /// Filled notehead (quarter/eighth etc) - U+E0A4
    static let noteheadBlack = "\u{E0A4}"

    // MARK: - Standard Accidentals 12-EDO (U+E260-U+E26F)

    /// Flat - U+E260
    static let accidentalFlat = "\u{E260}"

    /// Natural - U+E261
    static let accidentalNatural = "\u{E261}"

    /// Sharp - U+E262
    static let accidentalSharp = "\u{E262}"

    /// Double sharp - U+E263
    static let accidentalDoubleSharp = "\u{E263}"

    /// Double flat - U+E264
    static let accidentalDoubleFlat = "\u{E264}"

    // MARK: - Time Signatures (U+E080-U+E09F)

    /// Time signature digits 0-9 start at U+E080
    static func timeSignatureDigit(_ digit: Int) -> String {
        guard digit >= 0 && digit <= 9 else { return "" }
        return String(UnicodeScalar(0xE080 + digit)!)
    }

    /// Common time (C) - U+E08A
    static let timeSigCommon = "\u{E08A}"

    /// Cut time (C with line) - U+E08B
    static let timeSigCutCommon = "\u{E08B}"

    // MARK: - Rests (U+E4E0-U+E4FF)

    /// Whole rest - U+E4E3
    static let restWhole = "\u{E4E3}"

    /// Half rest - U+E4E4
    static let restHalf = "\u{E4E4}"

    /// Quarter rest - U+E4E5
    static let restQuarter = "\u{E4E5}"

    /// Eighth rest - U+E4E6
    static let restEighth = "\u{E4E6}"

    // MARK: - Barlines (U+E030-U+E03F)

    /// Single barline - U+E030
    static let barlineSingle = "\u{E030}"

    /// Double barline - U+E031
    static let barlineDouble = "\u{E031}"

    /// Final barline - U+E032
    static let barlineFinal = "\u{E032}"

    // MARK: - Staff (U+E010-U+E02F)

    /// Staff lines (5 lines) - U+E014
    static let staff5Lines = "\u{E014}"

    /// Ledger line - U+E022
    static let ledgerLine = "\u{E022}"

    // MARK: - Font Name

    /// The font name to use for SMuFL glyphs
    static let fontName = "Bravura"
}

// MARK: - Helper Extensions

extension SMuFL {
    /// Get the notehead glyph for a given duration
    static func notehead(for duration: NoteDuration) -> String {
        switch duration {
        case .whole:
            return noteheadWhole
        case .half:
            return noteheadHalf
        case .quarter, .eighth:
            return noteheadBlack
        }
    }

    /// Get the accidental glyph for a given accidental type
    static func accidental(for type: Accidental) -> String? {
        switch type {
        case .natural:
            return nil  // No glyph needed for natural in key signature context
        case .sharp:
            return accidentalSharp
        case .flat:
            return accidentalFlat
        }
    }
}
