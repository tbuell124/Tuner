import Foundation
import AVFoundation
import Accelerate

struct BiquadCoefficients {
    let b0, b1, b2, a1, a2: Float
}

final class BiquadFilter {
    private var x1: Float = 0
    private var x2: Float = 0
    private var y1: Float = 0
    private var y2: Float = 0
    private let coefficients: BiquadCoefficients
    
    enum FilterType {
        case highPass
        case lowPass
        case notch
        case bandPass
    }
    
    init(type: FilterType, frequency: Float, sampleRate: Float, q: Float = 0.707) {
        let omega = 2.0 * Float.pi * frequency / sampleRate
        let sin_omega = sin(omega)
        let cos_omega = cos(omega)
        let alpha = sin_omega / (2.0 * q)
        
        switch type {
        case .highPass:
            let b0 = (1.0 + cos_omega) / 2.0
            let b1 = -(1.0 + cos_omega)
            let b2 = (1.0 + cos_omega) / 2.0
            let a0 = 1.0 + alpha
            let a1 = -2.0 * cos_omega
            let a2 = 1.0 - alpha
            
            self.coefficients = BiquadCoefficients(
                b0: b0 / a0, b1: b1 / a0, b2: b2 / a0,
                a1: a1 / a0, a2: a2 / a0
            )
            
        case .lowPass:
            let b0 = (1.0 - cos_omega) / 2.0
            let b1 = 1.0 - cos_omega
            let b2 = (1.0 - cos_omega) / 2.0
            let a0 = 1.0 + alpha
            let a1 = -2.0 * cos_omega
            let a2 = 1.0 - alpha
            
            self.coefficients = BiquadCoefficients(
                b0: b0 / a0, b1: b1 / a0, b2: b2 / a0,
                a1: a1 / a0, a2: a2 / a0
            )
            
        case .notch:
            let b0: Float = 1.0
            let b1 = -2.0 * cos_omega
            let b2: Float = 1.0
            let a0 = 1.0 + alpha
            let a1 = -2.0 * cos_omega
            let a2 = 1.0 - alpha
            
            self.coefficients = BiquadCoefficients(
                b0: b0 / a0, b1: b1 / a0, b2: b2 / a0,
                a1: a1 / a0, a2: a2 / a0
            )
            
        case .bandPass:
            let b0 = alpha
            let b1: Float = 0.0
            let b2 = -alpha
            let a0 = 1.0 + alpha
            let a1 = -2.0 * cos_omega
            let a2 = 1.0 - alpha
            
            self.coefficients = BiquadCoefficients(
                b0: b0 / a0, b1: b1 / a0, b2: b2 / a0,
                a1: a1 / a0, a2: a2 / a0
            )
        }
    }
    
    func process(_ samples: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: samples.count)
        
        for i in 0..<samples.count {
            let x0 = samples[i]
            let y0 = coefficients.b0 * x0 + coefficients.b1 * x1 + coefficients.b2 * x2 - coefficients.a1 * y1 - coefficients.a2 * y2
            
            output[i] = y0
            
            x2 = x1
            x1 = x0
            y2 = y1
            y1 = y0
        }
        
        return output
    }
    
    func reset() {
        x1 = 0
        x2 = 0
        y1 = 0
        y2 = 0
    }
}

final class NoiseGate {
    private let threshold: Float
    private let ratio: Float
    private var envelope: Float = 0
    private let attackTime: Float = 0.003
    private let releaseTime: Float = 0.1
    
    init(threshold: Float, ratio: Float = 10.0) {
        self.threshold = threshold
        self.ratio = ratio
    }
    
    func process(_ samples: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: samples.count)
        
        for i in 0..<samples.count {
            let inputLevel = abs(samples[i])
            let targetEnvelope = inputLevel > threshold ? 1.0 : 0.0
            
            if targetEnvelope > envelope {
                envelope += (targetEnvelope - envelope) * attackTime
            } else {
                envelope += (targetEnvelope - envelope) * releaseTime
            }
            
            output[i] = samples[i] * envelope
        }
        
        return output
    }
}

final class AudioPreprocessor {
    private var highPassFilter: BiquadFilter
    private var notchFilter: BiquadFilter
    private var noiseGate: NoiseGate
    private let sampleRate: Float
    
    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        self.highPassFilter = BiquadFilter(type: .highPass, frequency: 80.0, sampleRate: sampleRate)
        self.notchFilter = BiquadFilter(type: .notch, frequency: 60.0, q: 10.0, sampleRate: sampleRate)
        self.noiseGate = NoiseGate(threshold: 0.01)
    }
    
    func process(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?.pointee else { return [] }
        let frameLength = Int(buffer.frameLength)
        var samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        samples = highPassFilter.process(samples)
        samples = notchFilter.process(samples)
        samples = noiseGate.process(samples)
        
        return samples
    }
    
    func reset() {
        highPassFilter.reset()
        notchFilter.reset()
    }
}
