import XCTest
@testable import TunePlay

final class PitchDetectionTests: XCTestCase {
    var pitchService: PitchDetectionService!
    
    override func setUp() {
        super.setUp()
        pitchService = PitchDetectionService()
    }
    
    override func tearDown() {
        pitchService = nil
        super.tearDown()
    }
    
    func testDetectorSwitching() {
        XCTAssertEqual(pitchService.currentDetector, .yin)
        
        pitchService.switchDetector(to: .hps)
        XCTAssertEqual(pitchService.currentDetector, .hps)
        
        pitchService.switchDetector(to: .quadratic)
        XCTAssertEqual(pitchService.currentDetector, .quadratic)
    }
    
    func testPitchResultStructure() {
        let result = PitchResult(frequency: 440.0, confidence: 0.95, algorithm: "YIN")
        
        XCTAssertEqual(result.frequency, 440.0, accuracy: 0.01)
        XCTAssertEqual(result.confidence, 0.95, accuracy: 0.01)
        XCTAssertEqual(result.algorithm, "YIN")
    }
    
    func testDetectorTypeEnum() {
        let allCases = DetectorType.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.yin))
        XCTAssertTrue(allCases.contains(.hps))
        XCTAssertTrue(allCases.contains(.quadratic))
        XCTAssertTrue(allCases.contains(.quinn))
        XCTAssertTrue(allCases.contains(.current))
    }
    
    func testDetectorDisplayNames() {
        XCTAssertEqual(DetectorType.yin.displayName, "YIN")
        XCTAssertEqual(DetectorType.hps.displayName, "HPS")
        XCTAssertEqual(DetectorType.quadratic.displayName, "Quadratic")
        XCTAssertEqual(DetectorType.quinn.displayName, "Quinn")
        XCTAssertEqual(DetectorType.current.displayName, "Current")
    }
}
