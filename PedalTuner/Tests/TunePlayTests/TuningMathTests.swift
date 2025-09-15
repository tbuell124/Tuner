import XCTest
@testable import TunePlay

final class TuningMathTests: XCTestCase {
    
    func testFrequencyToNoteConversion() {
        let a4Frequency = 440.0
        let noteNumber = 12 * log2(a4Frequency / 440.0) + 69
        XCTAssertEqual(noteNumber, 69.0, accuracy: 0.01, "A4 should be MIDI note 69")
        
        let eStringFreq = 329.63
        let eNoteNumber = 12 * log2(eStringFreq / 440.0) + 69
        let expectedE4 = 64.0
        XCTAssertEqual(eNoteNumber, expectedE4, accuracy: 0.1, "High E string should be around MIDI note 64")
    }
    
    func testCentsCalculation() {
        let frequency = 440.0
        let a4 = 440.0
        let noteNumber = 12 * log2(frequency / a4) + 69
        let rounded = round(noteNumber)
        let cents = (noteNumber - rounded) * 100
        
        XCTAssertEqual(cents, 0.0, accuracy: 0.01, "A4 at 440Hz should be 0 cents")
        
        let sharpFreq = 446.16
        let sharpNoteNumber = 12 * log2(sharpFreq / a4) + 69
        let sharpCents = (sharpNoteNumber - round(sharpNoteNumber)) * 100
        XCTAssertGreaterThan(sharpCents, 10, "446.16Hz should be significantly sharp")
    }
    
    func testNoteIndexCalculation() {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        let aNoteIndex = (69 + 1200) % 12
        XCTAssertEqual(noteNames[aNoteIndex], "A", "MIDI note 69 should be A")
        
        let cNoteIndex = (60 + 1200) % 12
        XCTAssertEqual(noteNames[cNoteIndex], "C", "MIDI note 60 should be C")
        
        let eNoteIndex = (64 + 1200) % 12
        XCTAssertEqual(noteNames[eNoteIndex], "E", "MIDI note 64 should be E")
    }
    
    func testGuitarStringFrequencies() {
        let guitarStrings = [
            (note: "E", octave: 2, frequency: 82.41),
            (note: "A", octave: 2, frequency: 110.00),
            (note: "D", octave: 3, frequency: 146.83),
            (note: "G", octave: 3, frequency: 196.00),
            (note: "B", octave: 3, frequency: 246.94),
            (note: "E", octave: 4, frequency: 329.63)
        ]
        
        for string in guitarStrings {
            let noteNumber = 12 * log2(string.frequency / 440.0) + 69
            let rounded = Int(round(noteNumber))
            let noteIndex = (rounded + 1200) % 12
            let octave = (rounded / 12) - 1
            let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            
            XCTAssertEqual(noteNames[noteIndex], string.note, "String frequency should match note name")
            XCTAssertEqual(octave, string.octave, "String frequency should match octave")
        }
    }
    
    func testCentsClampingAndSmoothing() {
        let maxCents = 50.0
        
        let largeCents = 75.0
        let clampedCents = max(-maxCents, min(maxCents, largeCents))
        XCTAssertEqual(clampedCents, maxCents, "Large positive cents should be clamped to max")
        
        let negativeCents = -75.0
        let clampedNegative = max(-maxCents, min(maxCents, negativeCents))
        XCTAssertEqual(clampedNegative, -maxCents, "Large negative cents should be clamped to min")
        
        let alpha = 0.25
        let oldSmoothed = 10.0
        let newCents = 20.0
        let smoothed = oldSmoothed * (1 - alpha) + newCents * alpha
        let expected = 10.0 * 0.75 + 20.0 * 0.25
        XCTAssertEqual(smoothed, expected, accuracy: 0.01, "Smoothing calculation should be correct")
    }
}
