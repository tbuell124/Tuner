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
    @Published var note: String = "--"
    @Published var cents: Double = 0
    @Published var confidence: Double = 0
    @Published var isStable: Bool = false
    @Published var detectedString: String = ""
    @Published var currentDetector: DetectorType = .yin
    @Published var noiseSuppressionEnabled: Bool = false
    
    private var audioInput: AudioInput
    private var preprocessor: AudioPreprocessor
    private var pitchDetectionService: PitchDetectionService
    private var pitchStabilizer: PitchStabilizer
    private var noiseSuppressionEngine: NoiseSuppressionEngine
    
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

    init() {
        self.audioInput = AudioInput()
        self.preprocessor = AudioPreprocessor(sampleRate: 48000)
        self.pitchDetectionService = PitchDetectionService()
        self.pitchStabilizer = PitchStabilizer()
        self.noiseSuppressionEngine = NoiseSuppressionEngine()
        
        setupAudioPipeline()
    }
    
    private func setupAudioPipeline() {
        audioInput.onAudioBuffer = { [weak self] buffer in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        var samples = preprocessor.process(buffer: buffer)
        
        if noiseSuppressionEnabled {
            samples = noiseSuppressionEngine.process(samples)
        }
        
        let processedBuffer = createBuffer(from: samples, format: buffer.format)
        let pitchResult = pitchDetectionService.detectPitch(from: processedBuffer)
        let stabilizedResult = pitchStabilizer.stabilize(pitchResult)
        
        guard let result = stabilizedResult else {
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
    
    private func createBuffer(from samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)!
        }
        
        buffer.frameLength = AVAudioFrameCount(samples.count)
        
        if let channelData = buffer.floatChannelData {
            for i in 0..<samples.count {
                channelData.pointee[i] = samples[i]
            }
        }
        
        return buffer
    }

    func start() {
        do {
            try audioInput.start()
        } catch {
            print("Failed to start audio input: \(error)")
        }
    }
    
    func switchDetector(to type: DetectorType) {
        currentDetector = type
        pitchDetectionService.switchDetector(to: type)
        pitchStabilizer.reset()
    }
    
    func switchNoiseMode(to mode: NoiseSuppressionMode) {
        noiseMode = mode
        noiseSuppressionEnabled = (mode == .voiceProcessing || mode == .adaptive)
        
        do {
            if noiseSuppressionEnabled {
                try audioInput.switchToVoiceProcessingMode()
            } else {
                try audioInput.switchToMeasurementMode()
            }
        } catch {
            print("Failed to switch audio mode: \(error)")
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
    
    func benchmarkAllDetectors() -> [DetectorType: PitchResult?] {
        guard let buffer = createSyntheticBuffer(frequency: 440.0, sampleRate: 48000, duration: 0.1) else {
            return [:]
        }
        
        return pitchDetectionService.benchmarkAllDetectors(with: buffer)
    }
    
    private func createSyntheticBuffer(frequency: Double, sampleRate: Double, duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else { return nil }
        
        for i in 0..<Int(frameCount) {
            let sample = sin(2.0 * Double.pi * frequency * Double(i) / sampleRate)
            channelData.pointee[i] = Float(sample)
        }
        
        return buffer
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
