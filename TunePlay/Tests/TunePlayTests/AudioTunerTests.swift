import XCTest
@testable import TunePlay

final class AudioTunerTests: XCTestCase {
    var audioTuner: AudioTuner!
    
    override func setUp() {
        super.setUp()
        audioTuner = AudioTuner()
    }
    
    override func tearDown() {
        audioTuner = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(audioTuner.note, "--")
        XCTAssertEqual(audioTuner.cents, 0.0, accuracy: 0.01)
        XCTAssertEqual(audioTuner.confidence, 0.0, accuracy: 0.01)
        XCTAssertFalse(audioTuner.isStable)
        XCTAssertEqual(audioTuner.detectedString, "")
    }
    
    func testNoiseSuppressionModes() {
        XCTAssertNoThrow(audioTuner.switchNoiseMode(to: .measurement))
        XCTAssertNoThrow(audioTuner.switchNoiseMode(to: .voiceProcessing))
        XCTAssertNoThrow(audioTuner.switchNoiseMode(to: .adaptive))
    }
    
    func testDetectorSwitching() {
        XCTAssertNoThrow(audioTuner.switchDetector(to: .yin))
        XCTAssertNoThrow(audioTuner.switchDetector(to: .hps))
        XCTAssertNoThrow(audioTuner.switchDetector(to: .quadratic))
        XCTAssertNoThrow(audioTuner.switchDetector(to: .quinn))
        XCTAssertNoThrow(audioTuner.switchDetector(to: .current))
    }
}
