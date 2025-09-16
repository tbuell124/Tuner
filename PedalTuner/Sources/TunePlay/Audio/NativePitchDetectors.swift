import Foundation
import AVFoundation
import Accelerate

final class YINDetector: PitchDetectionAlgorithm {
    private let threshold: Float = 0.1
    private let sampleRate: Float
    private let minPeriod: Int
    private let maxPeriod: Int
    
    init(sampleRate: Float = 48000) {
        self.sampleRate = sampleRate
        self.minPeriod = Int(sampleRate / 2000)
        self.maxPeriod = Int(sampleRate / 50)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        let halfLength = min(frameLength / 2, maxPeriod)
        var difference = [Float](repeating: 0, count: halfLength)
        var cumulativeDifference = [Float](repeating: 0, count: halfLength)
        
        calculateDifference(samples: samples, difference: &difference)
        calculateCumulativeDifference(difference: difference, cumulative: &cumulativeDifference)
        
        guard let period = findAbsoluteThreshold(cumulativeDifference: cumulativeDifference, threshold: threshold, minPeriod: minPeriod) else {
            return nil
        }
        
        let refinedPeriod = parabolicInterpolation(data: cumulativeDifference, peak: period)
        let frequency = sampleRate / refinedPeriod
        
        guard frequency >= 50 && frequency <= 2000 else { return nil }
        
        let confidence = max(0.0, 1.0 - Double(cumulativeDifference[period]))
        
        return PitchResult(frequency: Double(frequency), confidence: confidence, algorithm: "YIN")
    }
    
    private func calculateDifference(samples: [Float], difference: inout [Float]) {
        let frameLength = samples.count
        
        for tau in 0..<difference.count {
            var sum: Float = 0
            let count = frameLength - tau
            
            for j in 0..<count {
                let delta = samples[j] - samples[j + tau]
                sum += delta * delta
            }
            difference[tau] = sum
        }
    }
    
    private func calculateCumulativeDifference(difference: [Float], cumulative: inout [Float]) {
        cumulative[0] = 1.0
        var runningSum: Float = 0
        
        for tau in 1..<cumulative.count {
            runningSum += difference[tau]
            if runningSum == 0 {
                cumulative[tau] = 1.0
            } else {
                cumulative[tau] = difference[tau] / (runningSum / Float(tau))
            }
        }
    }
    
    private func findAbsoluteThreshold(cumulativeDifference: [Float], threshold: Float, minPeriod: Int) -> Int? {
        for tau in minPeriod..<cumulativeDifference.count {
            if cumulativeDifference[tau] < threshold {
                while tau + 1 < cumulativeDifference.count && cumulativeDifference[tau + 1] < cumulativeDifference[tau] {
                    return tau + 1
                }
                return tau
            }
        }
        return nil
    }
    
    private func parabolicInterpolation(data: [Float], peak: Int) -> Float {
        guard peak > 0 && peak < data.count - 1 else { return Float(peak) }
        
        let y1 = data[peak - 1]
        let y2 = data[peak]
        let y3 = data[peak + 1]
        
        let a = (y1 - 2 * y2 + y3) / 2
        let b = (y3 - y1) / 2
        
        guard abs(a) > 1e-10 else { return Float(peak) }
        
        let xPeak = -b / (2 * a)
        return Float(peak) + xPeak
    }
}

final class HPSDetector: PitchDetectionAlgorithm {
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length
    private let bufferSize: Int
    private var realp: [Float]
    private var imagp: [Float]
    private var splitComplex: DSPSplitComplex
    private var window: [Float]
    
    init(bufferSize: Int = 2048) {
        self.bufferSize = bufferSize
        self.log2n = vDSP_Length(log2(Float(bufferSize)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        
        self.realp = [Float](repeating: 0, count: bufferSize / 2)
        self.imagp = [Float](repeating: 0, count: bufferSize / 2)
        self.splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        self.window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: min(frameLength, bufferSize)))
        
        var windowedSamples = applyHannWindow(samples: samples)
        var spectrum = computeFFT(samples: &windowedSamples)
        
        let harmonics = 5
        var hpsSpectrum = spectrum
        
        for i in 0..<hpsSpectrum.count {
            for h in 2...harmonics {
                let harmonicIndex = i * h
                if harmonicIndex < spectrum.count {
                    hpsSpectrum[i] *= spectrum[harmonicIndex]
                }
            }
        }
        
        guard let peakIndex = findSpectralPeak(spectrum: hpsSpectrum, minFreq: 50, maxFreq: 2000, sampleRate: Float(buffer.format.sampleRate)) else {
            return nil
        }
        
        let sampleRate = Float(buffer.format.sampleRate)
        let frequency = (Float(peakIndex) * sampleRate) / Float(bufferSize)
        let confidence = Double(hpsSpectrum[peakIndex]) / Double(hpsSpectrum.max() ?? 1.0)
        
        return PitchResult(frequency: Double(frequency), confidence: confidence, algorithm: "HPS")
    }
    
    private func applyHannWindow(samples: [Float]) -> [Float] {
        var windowed = [Float](repeating: 0, count: bufferSize)
        let count = min(samples.count, bufferSize)
        
        for i in 0..<count {
            windowed[i] = samples[i]
        }
        
        vDSP_vmul(windowed, 1, window, 1, &windowed, 1, vDSP_Length(bufferSize))
        return windowed
    }
    
    private func computeFFT(samples: inout [Float]) -> [Float] {
        samples.withUnsafeMutableBufferPointer { samplesPtr in
            samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
            }
        }
        
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: bufferSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize / 2))
        
        return magnitudes
    }
    
    private func findSpectralPeak(spectrum: [Float], minFreq: Float, maxFreq: Float, sampleRate: Float) -> Int? {
        let minBin = Int((minFreq * Float(bufferSize)) / sampleRate)
        let maxBin = Int((maxFreq * Float(bufferSize)) / sampleRate)
        
        guard minBin < spectrum.count && maxBin < spectrum.count && minBin < maxBin else { return nil }
        
        var maxValue: Float = 0
        var maxIndex = minBin
        
        for i in minBin...maxBin {
            if spectrum[i] > maxValue {
                maxValue = spectrum[i]
                maxIndex = i
            }
        }
        
        return maxValue > 0 ? maxIndex : nil
    }
}

final class QuadraticDetector: PitchDetectionAlgorithm {
    private let sampleRate: Float
    
    init(sampleRate: Float = 48000) {
        self.sampleRate = sampleRate
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        var autocorr = [Float](repeating: 0, count: frameLength)
        vDSP_conv(samples, 1, samples, 1, &autocorr, 1, vDSP_Length(frameLength), vDSP_Length(frameLength))
        
        let minPeriod = Int(sampleRate / 2000)
        let maxPeriod = Int(sampleRate / 50)
        
        guard minPeriod < autocorr.count && maxPeriod < autocorr.count else { return nil }
        
        var maxValue: Float = 0
        var maxIndex = minPeriod
        
        for i in minPeriod...maxPeriod {
            if autocorr[i] > maxValue {
                maxValue = autocorr[i]
                maxIndex = i
            }
        }
        
        guard maxValue > 0.1 else { return nil }
        
        let refinedPeriod = parabolicInterpolation(data: autocorr, peak: maxIndex)
        let frequency = sampleRate / refinedPeriod
        
        guard frequency >= 50 && frequency <= 2000 else { return nil }
        
        let confidence = Double(maxValue) / Double(autocorr[0])
        
        return PitchResult(frequency: Double(frequency), confidence: confidence, algorithm: "Quadratic")
    }
    
    private func parabolicInterpolation(data: [Float], peak: Int) -> Float {
        guard peak > 0 && peak < data.count - 1 else { return Float(peak) }
        
        let y1 = data[peak - 1]
        let y2 = data[peak]
        let y3 = data[peak + 1]
        
        let a = (y1 - 2 * y2 + y3) / 2
        let b = (y3 - y1) / 2
        
        guard abs(a) > 1e-10 else { return Float(peak) }
        
        let xPeak = -b / (2 * a)
        return Float(peak) + xPeak
    }
}

final class QuinnDetector: PitchDetectionAlgorithm {
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length
    private let bufferSize: Int
    private var realp: [Float]
    private var imagp: [Float]
    private var splitComplex: DSPSplitComplex
    
    init(bufferSize: Int = 2048) {
        self.bufferSize = bufferSize
        self.log2n = vDSP_Length(log2(Float(bufferSize)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        
        self.realp = [Float](repeating: 0, count: bufferSize / 2)
        self.imagp = [Float](repeating: 0, count: bufferSize / 2)
        self.splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        var samples = Array(UnsafeBufferPointer(start: channelData, count: min(frameLength, bufferSize)))
        
        if samples.count < bufferSize {
            samples.append(contentsOf: [Float](repeating: 0, count: bufferSize - samples.count))
        }
        
        samples.withUnsafeMutableBufferPointer { samplesPtr in
            samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
            }
        }
        
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: bufferSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize / 2))
        
        let sampleRate = Float(buffer.format.sampleRate)
        let minBin = Int((50.0 * Float(bufferSize)) / sampleRate)
        let maxBin = Int((2000.0 * Float(bufferSize)) / sampleRate)
        
        guard minBin < magnitudes.count && maxBin < magnitudes.count && minBin < maxBin else { return nil }
        
        var maxValue: Float = 0
        var maxIndex = minBin
        
        for i in minBin...maxBin {
            if magnitudes[i] > maxValue {
                maxValue = magnitudes[i]
                maxIndex = i
            }
        }
        
        guard maxValue > 0 else { return nil }
        
        let refinedBin = quinnEstimation(realp: realp, imagp: imagp, peakBin: maxIndex)
        let frequency = (refinedBin * sampleRate) / Float(bufferSize)
        
        guard frequency >= 50 && frequency <= 2000 else { return nil }
        
        let confidence = Double(maxValue) / Double(magnitudes.max() ?? 1.0)
        
        return PitchResult(frequency: Double(frequency), confidence: confidence, algorithm: "Quinn")
    }
    
    private func quinnEstimation(realp: [Float], imagp: [Float], peakBin: Int) -> Float {
        guard peakBin > 0 && peakBin < realp.count - 1 else { return Float(peakBin) }
        
        let k = peakBin
        let real_k_minus_1 = realp[k - 1]
        let imag_k_minus_1 = imagp[k - 1]
        let real_k = realp[k]
        let imag_k = imagp[k]
        let real_k_plus_1 = realp[k + 1]
        let imag_k_plus_1 = imagp[k + 1]
        
        let ap = (real_k_plus_1 * real_k + imag_k_plus_1 * imag_k) / (real_k * real_k + imag_k * imag_k)
        let am = (real_k_minus_1 * real_k + imag_k_minus_1 * imag_k) / (real_k * real_k + imag_k * imag_k)
        
        let dp = -ap / (1 - ap)
        let dm = am / (1 - am)
        
        let d = (dp + dm) / 2 + tau(x: dp * dp) - tau(x: dm * dm)
        
        return Float(k) + d
    }
    
    private func tau(x: Float) -> Float {
        let p1: Float = log(3 * x * x + 6 * x + 1)
        let part1 = p1 + 1.023 + 0.249 * x
        let p2: Float = log(x * x + x + 0.333)
        let part2 = p2 + 2.047
        return 0.25 * part1 - 0.25 * part2
    }
}

final class CurrentDetector: PitchDetectionAlgorithm {
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let channelData = buffer.floatChannelData?.pointee else { return nil }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        
        var autocorr = [Float](repeating: 0, count: frameLength)
        vDSP_conv(samples, 1, samples, 1, &autocorr, 1, vDSP_Length(frameLength), vDSP_Length(frameLength))

        let sampleRate = Float(buffer.format.sampleRate)
        let minPeriod = Int(sampleRate / 2000)
        let maxPeriod = Int(sampleRate / 50)
        
        guard minPeriod < autocorr.count && maxPeriod < autocorr.count else { return nil }
        
        var maxIndex = minPeriod
        var maxValue: Float = 0
        
        for lag in minPeriod...maxPeriod {
            let value = autocorr[lag]
            if value > maxValue {
                maxValue = value
                maxIndex = lag
            }
        }

        guard maxValue > 0.1 else { return nil }
        
        let frequency = Double(sampleRate) / Double(maxIndex)
        let confidence = Double(maxValue) / Double(autocorr[0])
        
        return PitchResult(
            frequency: frequency,
            confidence: confidence,
            algorithm: "Current"
        )
    }
}
