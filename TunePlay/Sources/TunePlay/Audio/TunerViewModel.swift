import Foundation
import SwiftUI

final class TunerViewModel: ObservableObject {
    @Published var currentNote: String = ""
    @Published var currentFrequency: Double = 0.0
    @Published var centsOffset: Double = 0.0
    @Published var confidence: Double = 0.0
    @Published var isInTune: Bool = false
    @Published var detectedString: GuitarString?
    @Published var algorithm: String = ""
    
    private let inTuneThreshold: Double = 5.0
    private let perfectTuneThreshold: Double = 2.0
    
    func updatePitch(_ result: PitchResult?) {
        DispatchQueue.main.async {
            guard let result = result else {
                self.confidence = 0.0
                self.isInTune = false
                return
            }
            
            self.currentFrequency = result.frequency
            self.confidence = result.confidence
            self.algorithm = result.algorithm
            
            let noteInfo = self.frequencyToNote(result.frequency)
            self.currentNote = noteInfo.note
            self.centsOffset = noteInfo.cents
            self.detectedString = self.detectGuitarString(frequency: result.frequency)
            
            self.isInTune = abs(noteInfo.cents) <= self.inTuneThreshold
        }
    }
    
    private func frequencyToNote(_ frequency: Double) -> (note: String, cents: Double) {
        let A4 = 440.0
        let C0 = A4 * pow(2, -4.75)
        
        let noteNumber = 12 * log2(frequency / C0)
        let roundedNoteNumber = round(noteNumber)
        let cents = (noteNumber - roundedNoteNumber) * 100
        
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(roundedNoteNumber / 12)
        let noteIndex = Int(roundedNoteNumber.truncatingRemainder(dividingBy: 12))
        let adjustedNoteIndex = noteIndex >= 0 ? noteIndex : noteIndex + 12
        
        let noteName = noteNames[adjustedNoteIndex]
        let fullNoteName = "\(noteName)\(octave)"
        
        return (fullNoteName, cents)
    }
    
    private func detectGuitarString(frequency: Double) -> GuitarString? {
        let tolerance = 50.0
        
        for guitarString in GuitarString.allCases {
            if abs(frequency - guitarString.frequency) < tolerance {
                return guitarString
            }
        }
        
        return nil
    }
    
    var tuningColor: Color {
        let absCents = abs(centsOffset)
        
        if absCents <= perfectTuneThreshold {
            return .green
        } else if absCents <= inTuneThreshold {
            return .yellow
        } else {
            return .red
        }
    }
    
    var needleRotation: Double {
        let maxRotation: Double = 45.0
        let clampedCents = max(-50, min(50, centsOffset))
        return (clampedCents / 50.0) * maxRotation
    }
    
    var isPerfectTune: Bool {
        return abs(centsOffset) <= perfectTuneThreshold && confidence > 0.8
    }
}

enum GuitarString: String, CaseIterable {
    case lowE = "Low E"
    case A = "A"
    case D = "D"
    case G = "G"
    case B = "B"
    case highE = "High E"
    
    var frequency: Double {
        switch self {
        case .lowE: return 82.41
        case .A: return 110.00
        case .D: return 146.83
        case .G: return 196.00
        case .B: return 246.94
        case .highE: return 329.63
        }
    }
    
    var displayName: String {
        return rawValue
    }
}
