import Foundation
import AVFoundation
import Tuna
import Accelerate

class YINDetector: PitchDetectionAlgorithm {
    private var pitchEngine: PitchEngine?
    private var lastResult: PitchResult?
    
    init() {
        self.pitchEngine = PitchEngine(bufferSize: 2048, estimationStrategy: .yin) { [weak self] pitch in
            if let frequency = pitch.frequency, frequency > 0 {
                self?.lastResult = PitchResult(
                    frequency: frequency,
                    confidence: 0.8,
                    algorithm: "YIN"
                )
            }
        }
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        let transform = Transform(strategy: .yin)
        let pitch = transform.pitch(for: samples)
        
        if let frequency = pitch.frequency, frequency > 0 {
            return PitchResult(
                frequency: frequency,
                confidence: 0.8,
                algorithm: "YIN"
            )
        }
        
        return nil
    }
}

class HPSDetector: PitchDetectionAlgorithm {
    private var pitchEngine: PitchEngine?
    private var lastResult: PitchResult?
    
    init() {
        self.pitchEngine = PitchEngine(bufferSize: 2048, estimationStrategy: .hps) { [weak self] pitch in
            if let frequency = pitch.frequency, frequency > 0 {
                self?.lastResult = PitchResult(
                    frequency: frequency,
                    confidence: 0.8,
                    algorithm: "HPS"
                )
            }
        }
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        let transform = Transform(strategy: .hps)
        let pitch = transform.pitch(for: samples)
        
        if let frequency = pitch.frequency, frequency > 0 {
            return PitchResult(
                frequency: frequency,
                confidence: 0.8,
                algorithm: "HPS"
            )
        }
        
        return nil
    }
}

class QuadraticDetector: PitchDetectionAlgorithm {
    private var pitchEngine: PitchEngine?
    private var lastResult: PitchResult?
    
    init() {
        self.pitchEngine = PitchEngine(bufferSize: 2048, estimationStrategy: .quadradic) { [weak self] pitch in
            if let frequency = pitch.frequency, frequency > 0 {
                self?.lastResult = PitchResult(
                    frequency: frequency,
                    confidence: 0.8,
                    algorithm: "Quadratic"
                )
            }
        }
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        let transform = Transform(strategy: .quadradic)
        let pitch = transform.pitch(for: samples)
        
        if let frequency = pitch.frequency, frequency > 0 {
            return PitchResult(
                frequency: frequency,
                confidence: 0.8,
                algorithm: "Quadratic"
            )
        }
        
        return nil
    }
}

class QuinnDetector: PitchDetectionAlgorithm {
    private var pitchEngine: PitchEngine?
    private var lastResult: PitchResult?
    
    init() {
        self.pitchEngine = PitchEngine(bufferSize: 2048, estimationStrategy: .quinnsFirst) { [weak self] pitch in
            if let frequency = pitch.frequency, frequency > 0 {
                self?.lastResult = PitchResult(
                    frequency: frequency,
                    confidence: 0.8,
                    algorithm: "Quinn"
                )
            }
        }
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        let transform = Transform(strategy: .quinnsFirst)
        let pitch = transform.pitch(for: samples)
        
        if let frequency = pitch.frequency, frequency > 0 {
            return PitchResult(
                frequency: frequency,
                confidence: 0.8,
                algorithm: "Quinn"
            )
        }
        
        return nil
    }
}

class CurrentDetector: PitchDetectionAlgorithm {
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        var autocorr = [Float](repeating: 0, count: frameLength)
        vDSP_conv(channelData, 1, channelData, 1, &autocorr, 1, vDSP_Length(frameLength), vDSP_Length(frameLength))

        var maxIndex = 0
        var maxValue: Float = 0
        for lag in 1..<frameLength {
            let value = autocorr[lag]
            if value > maxValue {
                maxValue = value
                maxIndex = lag
            }
        }

        let sampleRate = buffer.format.sampleRate
        let frequency = sampleRate / Double(maxIndex)
        
        let confidence = maxValue > 0.1 ? Double(maxValue) : 0.0
        
        return PitchResult(
            frequency: frequency,
            confidence: confidence,
            algorithm: "Current"
        )
    }
}
