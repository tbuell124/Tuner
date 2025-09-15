import Foundation
import AVFoundation
import Tuna

protocol PitchDetectionAlgorithm {
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult?
}

struct PitchResult {
    let frequency: Double
    let confidence: Double
    let algorithm: String
}

enum DetectorType: String, CaseIterable {
    case yin = "YIN"
    case hps = "HPS" 
    case quadratic = "Quadratic"
    case quinn = "Quinn"
    case current = "Current"
    
    var displayName: String {
        return rawValue
    }
}

final class PitchDetectionService: ObservableObject {
    @Published var currentDetector: DetectorType = .yin
    @Published var lastResult: PitchResult?
    @Published var confidence: Double = 0.0
    
    private var detectors: [DetectorType: PitchDetectionAlgorithm] = [:]
    private let confidenceThreshold: Double = 0.6
    private let stabilityBuffer: [PitchResult] = []
    private let maxBufferSize = 5
    
    init() {
        setupDetectors()
    }
    
    private func setupDetectors() {
        detectors[.yin] = YINDetector()
        detectors[.hps] = HPSDetector()
        detectors[.quadratic] = QuadraticDetector()
        detectors[.quinn] = QuinnDetector()
        detectors[.current] = CurrentDetector()
    }
    
    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchResult? {
        guard let detector = detectors[currentDetector] else { return nil }
        
        let result = detector.detectPitch(from: buffer)
        
        if let result = result, result.confidence >= confidenceThreshold {
            DispatchQueue.main.async {
                self.lastResult = result
                self.confidence = result.confidence
            }
            return result
        }
        
        return nil
    }
    
    func switchDetector(to type: DetectorType) {
        currentDetector = type
    }
    
    func benchmarkAllDetectors(with buffer: AVAudioPCMBuffer) -> [DetectorType: PitchResult?] {
        var results: [DetectorType: PitchResult?] = [:]
        
        for (type, detector) in detectors {
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = detector.detectPitch(from: buffer)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            if var result = result {
                result = PitchResult(
                    frequency: result.frequency,
                    confidence: result.confidence,
                    algorithm: "\(type.rawValue) (\(String(format: "%.2f", (endTime - startTime) * 1000))ms)"
                )
            }
            results[type] = result
        }
        
        return results
    }
}
