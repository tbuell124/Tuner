import Foundation

final class PitchStabilizer {
    private var recentResults: [PitchResult] = []
    private let maxBufferSize: Int
    private let confidenceThreshold: Double
    private let stabilityThreshold: Double
    private var currentStableFrequency: Double?
    private var stableCount: Int = 0
    private let requiredStableCount: Int = 3
    
    init(maxBufferSize: Int = 5, confidenceThreshold: Double = 0.6, stabilityThreshold: Double = 0.02) {
        self.maxBufferSize = maxBufferSize
        self.confidenceThreshold = confidenceThreshold
        self.stabilityThreshold = stabilityThreshold
    }
    
    func stabilize(_ result: PitchResult?) -> PitchResult? {
        guard let result = result, result.confidence >= confidenceThreshold else {
            if recentResults.count > 0 {
                recentResults.removeFirst()
            }
            return nil
        }
        
        recentResults.append(result)
        
        if recentResults.count > maxBufferSize {
            recentResults.removeFirst()
        }
        
        guard recentResults.count >= 3 else { return result }
        
        let medianResult = calculateMedianResult()
        let emaResult = calculateEMAResult()
        
        let stabilizedFrequency = (medianResult.frequency + emaResult.frequency) / 2.0
        let stabilizedConfidence = min(medianResult.confidence, emaResult.confidence)
        
        let stabilizedResult = PitchResult(
            frequency: stabilizedFrequency,
            confidence: stabilizedConfidence,
            algorithm: result.algorithm
        )
        
        return applyHysteresis(stabilizedResult)
    }
    
    private func calculateMedianResult() -> PitchResult {
        let sortedFrequencies = recentResults.map { $0.frequency }.sorted()
        let medianFrequency = sortedFrequencies[sortedFrequencies.count / 2]
        
        let averageConfidence = recentResults.map { $0.confidence }.reduce(0, +) / Double(recentResults.count)
        
        return PitchResult(
            frequency: medianFrequency,
            confidence: averageConfidence,
            algorithm: recentResults.last?.algorithm ?? "Unknown"
        )
    }
    
    private func calculateEMAResult() -> PitchResult {
        let alpha: Double = 0.3
        var emaFrequency = recentResults.first?.frequency ?? 0
        var emaConfidence = recentResults.first?.confidence ?? 0
        
        for result in recentResults.dropFirst() {
            emaFrequency = alpha * result.frequency + (1 - alpha) * emaFrequency
            emaConfidence = alpha * result.confidence + (1 - alpha) * emaConfidence
        }
        
        return PitchResult(
            frequency: emaFrequency,
            confidence: emaConfidence,
            algorithm: recentResults.last?.algorithm ?? "Unknown"
        )
    }
    
    private func applyHysteresis(_ result: PitchResult) -> PitchResult {
        if let stableFreq = currentStableFrequency {
            let relativeChange = abs(result.frequency - stableFreq) / stableFreq
            
            if relativeChange < stabilityThreshold {
                stableCount += 1
                if stableCount >= requiredStableCount {
                    return PitchResult(
                        frequency: stableFreq,
                        confidence: min(result.confidence + 0.1, 1.0),
                        algorithm: result.algorithm
                    )
                }
            } else {
                stableCount = 0
                currentStableFrequency = result.frequency
            }
        } else {
            currentStableFrequency = result.frequency
            stableCount = 1
        }
        
        return result
    }
    
    func reset() {
        recentResults.removeAll()
        currentStableFrequency = nil
        stableCount = 0
    }
}
