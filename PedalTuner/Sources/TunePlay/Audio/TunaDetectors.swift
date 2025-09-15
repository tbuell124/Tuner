import Foundation
import AVFoundation
import Tuna
import Accelerate

class YINDetector: PitchDetectionAlgorithm {
    private let estimator = YINEstimator()
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        let tunaBuffer = Buffer(elements: samples)
        
        do {
            let frequency = try estimator.estimateFrequency(sampleRate: sampleRate, buffer: tunaBuffer)
            
            if frequency > 0 && frequency < 20000 {
                return PitchResult(
                    frequency: Double(frequency),
                    confidence: 0.8,
                    algorithm: "YIN"
                )
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

class HPSDetector: PitchDetectionAlgorithm {
    private let estimator = HPSEstimator()
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        let tunaBuffer = Buffer(elements: samples)
        
        do {
            let frequency = try estimator.estimateFrequency(sampleRate: sampleRate, buffer: tunaBuffer)
            
            if frequency > 0 && frequency < 20000 {
                return PitchResult(
                    frequency: Double(frequency),
                    confidence: 0.8,
                    algorithm: "HPS"
                )
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

class QuadraticDetector: PitchDetectionAlgorithm {
    private let estimator = QuadradicEstimator()
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        let tunaBuffer = Buffer(elements: samples)
        
        do {
            let frequency = try estimator.estimateFrequency(sampleRate: sampleRate, buffer: tunaBuffer)
            
            if frequency > 0 && frequency < 20000 {
                return PitchResult(
                    frequency: Double(frequency),
                    confidence: 0.8,
                    algorithm: "Quadratic"
                )
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

class QuinnDetector: PitchDetectionAlgorithm {
    private let estimator = QuinnsFirstEstimator()
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        let tunaBuffer = Buffer(elements: samples)
        
        do {
            let frequency = try estimator.estimateFrequency(sampleRate: sampleRate, buffer: tunaBuffer)
            
            if frequency > 0 && frequency < 20000 {
                return PitchResult(
                    frequency: Double(frequency),
                    confidence: 0.8,
                    algorithm: "Quinn"
                )
            }
        } catch {
            return nil
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
