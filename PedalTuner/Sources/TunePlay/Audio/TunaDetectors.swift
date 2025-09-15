import Foundation
import AVFoundation
import Tuna
import Accelerate

class YINDetector: PitchDetectionAlgorithm {
    private let estimator: Estimator
    
    init() {
        let config = EstimationConfig(
            estimationStrategy: .yin,
            bufferSize: 2048,
            frequency: 44100
        )
        self.estimator = Estimator(config: config)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        do {
            let result = try estimator.estimateFrequency(sampleBuffer: samples)
            return PitchResult(
                frequency: result.frequency,
                confidence: result.confidence,
                algorithm: "YIN"
            )
        } catch {
            return nil
        }
    }
}

class HPSDetector: PitchDetectionAlgorithm {
    private let estimator: Estimator
    
    init() {
        let config = EstimationConfig(
            estimationStrategy: .hps,
            bufferSize: 2048,
            frequency: 44100
        )
        self.estimator = Estimator(config: config)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        do {
            let result = try estimator.estimateFrequency(sampleBuffer: samples)
            return PitchResult(
                frequency: result.frequency,
                confidence: result.confidence,
                algorithm: "HPS"
            )
        } catch {
            return nil
        }
    }
}

class QuadraticDetector: PitchDetectionAlgorithm {
    private let estimator: Estimator
    
    init() {
        let config = EstimationConfig(
            estimationStrategy: .quadradic,
            bufferSize: 2048,
            frequency: 44100
        )
        self.estimator = Estimator(config: config)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        do {
            let result = try estimator.estimateFrequency(sampleBuffer: samples)
            return PitchResult(
                frequency: result.frequency,
                confidence: result.confidence,
                algorithm: "Quadratic"
            )
        } catch {
            return nil
        }
    }
}

class QuinnDetector: PitchDetectionAlgorithm {
    private let estimator: Estimator
    
    init() {
        let config = EstimationConfig(
            estimationStrategy: .quinnsFirst,
            bufferSize: 2048,
            frequency: 44100
        )
        self.estimator = Estimator(config: config)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        do {
            let result = try estimator.estimateFrequency(sampleBuffer: samples)
            return PitchResult(
                frequency: result.frequency,
                confidence: result.confidence,
                algorithm: "Quinn"
            )
        } catch {
            return nil
        }
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
