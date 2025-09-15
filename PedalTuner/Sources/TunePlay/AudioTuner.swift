#if canImport(AVFoundation)
import AVFoundation
import Accelerate
import SwiftUI

enum NoiseSuppressionMode {
    case measurement
    case voiceProcessing
    case adaptive
}

final class AudioTuner: ObservableObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    private let pitchDetectionService = PitchDetectionService()
    
    @Published var note: String = "--"
    @Published var cents: Double = 0
    @Published var confidence: Double = 0
    @Published var isStable: Bool = false
    @Published var detectedString: String = ""
    
    private var noiseMode: NoiseSuppressionMode = .measurement
    private var stableFrameCount = 0
    private let requiredStableFrames = 15
    private var lastNoteNumber: Int?
    private let hysteresisThreshold: Double = 2.0
    
    private var smoothedCents: Double = 0
    private let centsAlpha: Double = 0.25
    
    private let guitarStrings = [
        (note: "E", octave: 2, frequency: 82.41),
        (note: "A", octave: 2, frequency: 110.00),
        (note: "D", octave: 3, frequency: 146.83),
        (note: "G", octave: 3, frequency: 196.00),
        (note: "B", octave: 3, frequency: 246.94),
        (note: "E", octave: 4, frequency: 329.63)
    ]

    func start() {
        configureSession()
        setupAudioEngine()
    }
    
    func switchDetector(to type: DetectorType) {
        pitchDetectionService.switchDetector(to: type)
    }
    
    func switchNoiseMode(to mode: NoiseSuppressionMode) {
        noiseMode = mode
        engine.stop()
        configureSession()
        setupAudioEngine()
    }

    private func configureSession() {
        do {
            switch noiseMode {
            case .measurement:
                try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            case .voiceProcessing:
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            case .adaptive:
                try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            }
            
            try session.setPreferredSampleRate(48000)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("Session error: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        let input = engine.inputNode
        let bus = 0
        let format = input.outputFormat(forBus: bus)

        input.installTap(onBus: bus, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        do {
            try engine.start()
        } catch {
            print("Engine start error: \(error)")
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let result = pitchDetectionService.detectPitch(from: buffer) else {
            decreaseStability()
            return
        }
        
        let frequency = result.frequency
        guard frequency > 60 && frequency < 2000 && frequency.isFinite else {
            decreaseStability()
            return
        }
        
        let a4 = 440.0
        let noteNumber = 12 * log2(frequency / a4) + 69
        let rounded = Int(round(noteNumber))
        let noteIndex = (rounded + 1200) % 12
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (rounded / 12) - 1
        let noteName = "\(names[noteIndex])\(octave)"
        
        var cents = (noteNumber - Double(rounded)) * 100
        cents = max(-50, min(50, cents))
        
        smoothedCents = smoothedCents * (1 - centsAlpha) + cents * centsAlpha
        
        let isNoteStable = lastNoteNumber == rounded
        let isCentsStable = abs(smoothedCents) < hysteresisThreshold
        
        if isNoteStable && isCentsStable {
            stableFrameCount += 1
        } else {
            stableFrameCount = 0
        }
        
        lastNoteNumber = rounded
        
        let detectedString = detectGuitarString(frequency: frequency)
        
        DispatchQueue.main.async {
            self.note = noteName
            self.cents = self.smoothedCents
            self.confidence = result.confidence
            self.isStable = self.stableFrameCount >= self.requiredStableFrames
            self.detectedString = detectedString
        }
    }
    
    private func decreaseStability() {
        stableFrameCount = max(0, stableFrameCount - 2)
        DispatchQueue.main.async {
            self.isStable = self.stableFrameCount >= self.requiredStableFrames
        }
    }
    
    private func detectGuitarString(frequency: Double) -> String {
        let tolerance = 0.15
        
        for string in guitarStrings {
            let ratio = frequency / string.frequency
            if ratio >= (1.0 - tolerance) && ratio <= (1.0 + tolerance) {
                return "\(string.note)\(string.octave)"
            }
        }
        
        return ""
    }
}
#else
final class AudioTuner: ObservableObject {
    @Published var note: String = "--"
    @Published var cents: Double = 0
    @Published var confidence: Double = 0
    @Published var isStable: Bool = false
    @Published var detectedString: String = ""
    
    func start() { }
    func switchDetector(to type: DetectorType) { }
    func switchNoiseMode(to mode: NoiseSuppressionMode) { }
}
#endif
