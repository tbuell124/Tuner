import Foundation
import AVFoundation
import Accelerate

struct BenchmarkResult {
    let algorithm: String
    let frequency: Double
    let detectedFrequency: Double
    let cents: Double
    let confidence: Double
    let latencyMs: Double
    let cpuUsage: Double
    let accuracy: Double
    
    var csvRow: String {
        return "\(algorithm),\(frequency),\(detectedFrequency),\(cents),\(confidence),\(latencyMs),\(cpuUsage),\(accuracy)"
    }
    
    static var csvHeader: String {
        return "Algorithm,InputFreq,DetectedFreq,Cents,Confidence,LatencyMs,CPUUsage,Accuracy"
    }
}

class SyntheticToneGenerator {
    static func generateTone(frequency: Double, sampleRate: Double, duration: Double, amplitude: Float = 0.5) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        
        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let sample = amplitude * sin(2.0 * .pi * frequency * time)
            samples[i] = Float(sample)
        }
        
        return samples
    }
    
    static func generateVibratoTone(frequency: Double, vibratoRate: Double, vibratoDepth: Double, sampleRate: Double, duration: Double) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        
        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let vibrato = vibratoDepth * sin(2.0 * .pi * vibratoRate * time)
            let instantFreq = frequency * (1.0 + vibrato)
            let sample = 0.5 * sin(2.0 * .pi * instantFreq * time)
            samples[i] = Float(sample)
        }
        
        return samples
    }
    
    static func addPinkNoise(to samples: inout [Float], noiseLevel: Float) {
        let noiseCount = samples.count
        var noise = [Float](repeating: 0, count: noiseCount)
        
        for i in 0..<noiseCount {
            noise[i] = Float.random(in: -1...1) * noiseLevel
        }
        
        vDSP_vadd(samples, 1, noise, 1, &samples, 1, vDSP_Length(noiseCount))
    }
}

class BenchmarkRunner {
    private let testFrequencies: [Double] = [
        82.41,   // E2
        110.00,  // A2  
        146.83,  // D3
        196.00,  // G3
        246.94,  // B3
        329.63,  // E4
        440.00,  // A4 reference
        523.25   // C5
    ]
    
    private let centOffsets: [Double] = [-50, -25, -10, -5, -2, 0, 2, 5, 10, 25, 50]
    private let vibratoRates: [Double] = [4.0, 6.0, 8.0]
    private let noiseLevels: [Float] = [0.0, 0.05, 0.1, 0.15, 0.2]
    
    func runComprehensiveBenchmark() -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []
        
        print("Starting comprehensive pitch detection benchmark...")
        
        for frequency in testFrequencies {
            for centOffset in centOffsets {
                let testFreq = frequency * pow(2.0, centOffset / 1200.0)
                
                for noiseLevel in noiseLevels {
                    let result = benchmarkFrequency(testFreq, originalFreq: frequency, noiseLevel: noiseLevel)
                    results.append(contentsOf: result)
                }
            }
        }
        
        for frequency in testFrequencies {
            for vibratoRate in vibratoRates {
                let result = benchmarkVibratoFrequency(frequency, vibratoRate: vibratoRate)
                results.append(contentsOf: result)
            }
        }
        
        print("Benchmark completed with \(results.count) test cases")
        return results
    }
    
    private func benchmarkFrequency(_ frequency: Double, originalFreq: Double, noiseLevel: Float) -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []
        let sampleRate = 48000.0
        let duration = 0.5
        
        var samples = SyntheticToneGenerator.generateTone(
            frequency: frequency,
            sampleRate: sampleRate,
            duration: duration
        )
        
        if noiseLevel > 0 {
            SyntheticToneGenerator.addPinkNoise(to: &samples, noiseLevel: noiseLevel)
        }
        
        let buffer = createAudioBuffer(from: samples, sampleRate: sampleRate)
        
        let algorithms: [DetectorType] = [.yin, .hps, .quadratic, .quinn, .current]
        
        for algorithm in algorithms {
            let result = benchmarkAlgorithm(algorithm, buffer: buffer, expectedFreq: frequency, originalFreq: originalFreq)
            results.append(result)
        }
        
        return results
    }
    
    private func benchmarkVibratoFrequency(_ frequency: Double, vibratoRate: Double) -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []
        let sampleRate = 48000.0
        let duration = 1.0
        let vibratoDepth = 0.02
        
        let samples = SyntheticToneGenerator.generateVibratoTone(
            frequency: frequency,
            vibratoRate: vibratoRate,
            vibratoDepth: vibratoDepth,
            sampleRate: sampleRate,
            duration: duration
        )
        
        let buffer = createAudioBuffer(from: samples, sampleRate: sampleRate)
        
        let algorithms: [DetectorType] = [.yin, .hps, .quadratic, .quinn, .current]
        
        for algorithm in algorithms {
            let result = benchmarkAlgorithm(algorithm, buffer: buffer, expectedFreq: frequency, originalFreq: frequency)
            results.append(result)
        }
        
        return results
    }
    
    private func benchmarkAlgorithm(_ algorithm: DetectorType, buffer: AVAudioPCMBuffer, expectedFreq: Double, originalFreq: Double) -> BenchmarkResult {
        let service = PitchDetectionService()
        service.switchDetector(to: algorithm)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startCPU = ProcessInfo.processInfo.systemUptime
        
        let result = service.detectPitch(from: buffer)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endCPU = ProcessInfo.processInfo.systemUptime
        
        let latencyMs = (endTime - startTime) * 1000
        let cpuUsage = (endCPU - startCPU) * 100
        
        let detectedFreq = result?.frequency ?? 0.0
        let confidence = result?.confidence ?? 0.0
        
        let cents = detectedFreq > 0 ? 1200 * log2(detectedFreq / originalFreq) : 0.0
        let accuracy = detectedFreq > 0 ? abs(detectedFreq - expectedFreq) / expectedFreq : 1.0
        
        return BenchmarkResult(
            algorithm: algorithm.displayName,
            frequency: expectedFreq,
            detectedFrequency: detectedFreq,
            cents: cents,
            confidence: confidence,
            latencyMs: latencyMs,
            cpuUsage: cpuUsage,
            accuracy: accuracy
        )
    }
    
    private func createAudioBuffer(from samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        
        buffer.frameLength = AVAudioFrameCount(samples.count)
        
        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples.count {
            channelData[i] = samples[i]
        }
        
        return buffer
    }
    
    func exportResultsToCSV(_ results: [BenchmarkResult], filename: String) {
        var csvContent = BenchmarkResult.csvHeader + "\n"
        
        for result in results {
            csvContent += result.csvRow + "\n"
        }
        
        let url = URL(fileURLWithPath: filename)
        try? csvContent.write(to: url, atomically: true, encoding: .utf8)
        print("Results exported to \(filename)")
    }
    
    func generateSummaryReport(_ results: [BenchmarkResult]) -> String {
        var report = "# TunePlay Pitch Detection Benchmark Report\n\n"
        
        let algorithms = Set(results.map { $0.algorithm })
        
        for algorithm in algorithms.sorted() {
            let algorithmResults = results.filter { $0.algorithm == algorithm }
            
            let avgLatency = algorithmResults.map { $0.latencyMs }.reduce(0, +) / Double(algorithmResults.count)
            let avgAccuracy = algorithmResults.map { $0.accuracy }.reduce(0, +) / Double(algorithmResults.count)
            let avgConfidence = algorithmResults.map { $0.confidence }.reduce(0, +) / Double(algorithmResults.count)
            let avgCPU = algorithmResults.map { $0.cpuUsage }.reduce(0, +) / Double(algorithmResults.count)
            
            let accurateResults = algorithmResults.filter { abs($0.cents) <= 3.0 }
            let accuracyRate = Double(accurateResults.count) / Double(algorithmResults.count) * 100
            
            report += "## \(algorithm) Algorithm\n"
            report += "- Average Latency: \(String(format: "%.2f", avgLatency))ms\n"
            report += "- Average Accuracy: \(String(format: "%.4f", avgAccuracy))\n"
            report += "- Average Confidence: \(String(format: "%.3f", avgConfidence))\n"
            report += "- Average CPU Usage: \(String(format: "%.2f", avgCPU))%\n"
            report += "- Accuracy Rate (±3 cents): \(String(format: "%.1f", accuracyRate))%\n\n"
        }
        
        return report
    }
}
