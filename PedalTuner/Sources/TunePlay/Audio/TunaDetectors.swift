import Foundation
import AVFoundation
import Accelerate

class YINDetector: PitchDetectionAlgorithm {
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
            algorithm: "YIN"
        )
    }
}

class HPSDetector: PitchDetectionAlgorithm {
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
        
        let confidence = maxValue > 0.12 ? Double(maxValue) : 0.0
        
        return PitchResult(
            frequency: frequency,
            confidence: confidence,
            algorithm: "HPS"
        )
    }
}

class QuadraticDetector: PitchDetectionAlgorithm {
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
        
        let confidence = maxValue > 0.11 ? Double(maxValue) : 0.0
        
        return PitchResult(
            frequency: frequency,
            confidence: confidence,
            algorithm: "Quadratic"
        )
    }
}

class QuinnDetector: PitchDetectionAlgorithm {
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
        
        let confidence = maxValue > 0.13 ? Double(maxValue) : 0.0
        
        return PitchResult(
            frequency: frequency,
            confidence: confidence,
            algorithm: "Quinn"
        )
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
