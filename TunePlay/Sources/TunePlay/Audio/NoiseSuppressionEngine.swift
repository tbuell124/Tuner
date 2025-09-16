import Foundation
import AVFoundation
import Accelerate

final class NoiseSuppressionEngine {
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length
    private let bufferSize: Int
    private var realp: [Float]
    private var imagp: [Float]
    private var splitComplex: DSPSplitComplex
    private var noiseProfile: [Float]
    private var isNoiseProfileEstimated = false
    private let alpha: Float = 0.95
    private let overSubtractionFactor: Float = 2.0
    private let spectralFloor: Float = 0.002
    
    init(bufferSize: Int = 2048) {
        self.bufferSize = bufferSize
        self.log2n = vDSP_Length(log2(Float(bufferSize)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        
        self.realp = [Float](repeating: 0, count: bufferSize / 2)
        self.imagp = [Float](repeating: 0, count: bufferSize / 2)
        self.splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        self.noiseProfile = [Float](repeating: 0, count: bufferSize / 2)
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func process(_ samples: [Float]) -> [Float] {
        guard samples.count >= bufferSize else { return samples }
        
        var processedSamples = samples
        if processedSamples.count > bufferSize {
            processedSamples = Array(processedSamples.prefix(bufferSize))
        } else if processedSamples.count < bufferSize {
            processedSamples.append(contentsOf: [Float](repeating: 0, count: bufferSize - processedSamples.count))
        }
        
        let spectrum = computeFFT(samples: processedSamples)
        
        if !isNoiseProfileEstimated {
            updateNoiseProfile(spectrum: spectrum)
        }
        
        let suppressedSpectrum = spectralSubtraction(spectrum: spectrum)
        let reconstructedSamples = computeIFFT(spectrum: suppressedSpectrum)
        
        return Array(reconstructedSamples.prefix(samples.count))
    }
    
    private func computeFFT(samples: [Float]) -> [Float] {
        var paddedSamples = samples
        if paddedSamples.count < bufferSize {
            paddedSamples.append(contentsOf: [Float](repeating: 0, count: bufferSize - paddedSamples.count))
        }
        
        paddedSamples.withUnsafeMutableBufferPointer { samplesPtr in
            samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
            }
        }
        
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: bufferSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize / 2))
        
        return magnitudes
    }
    
    private func computeIFFT(spectrum: [Float]) -> [Float] {
        for i in 0..<min(spectrum.count, realp.count) {
            let magnitude = spectrum[i]
            let phase = atan2(imagp[i], realp[i])
            realp[i] = magnitude * cos(phase)
            imagp[i] = magnitude * sin(phase)
        }
        
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_INVERSE))
        
        var result = [Float](repeating: 0, count: bufferSize)
        result.withUnsafeMutableBufferPointer { resultPtr in
            resultPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                vDSP_ztoc(&splitComplex, 1, complexPtr, 2, vDSP_Length(bufferSize / 2))
            }
        }
        
        let scale = Float(1.0) / Float(bufferSize)
        vDSP_vsmul(result, 1, &scale, &result, 1, vDSP_Length(bufferSize))
        
        return result
    }
    
    private func updateNoiseProfile(spectrum: [Float]) {
        if !isNoiseProfileEstimated {
            noiseProfile = spectrum
            isNoiseProfileEstimated = true
        } else {
            for i in 0..<min(noiseProfile.count, spectrum.count) {
                noiseProfile[i] = alpha * noiseProfile[i] + (1 - alpha) * spectrum[i]
            }
        }
    }
    
    private func spectralSubtraction(spectrum: [Float]) -> [Float] {
        var suppressedSpectrum = [Float](repeating: 0, count: spectrum.count)
        
        for i in 0..<min(spectrum.count, noiseProfile.count) {
            let signalPower = spectrum[i]
            let noisePower = noiseProfile[i]
            
            let subtractedPower = signalPower - overSubtractionFactor * noisePower
            let flooredPower = max(subtractedPower, spectralFloor * signalPower)
            
            suppressedSpectrum[i] = flooredPower
        }
        
        return suppressedSpectrum
    }
    
    func estimateNoiseProfile(samples: [Float]) {
        let spectrum = computeFFT(samples: samples)
        updateNoiseProfile(spectrum: spectrum)
    }
    
    func reset() {
        noiseProfile = [Float](repeating: 0, count: bufferSize / 2)
        isNoiseProfileEstimated = false
    }
}
