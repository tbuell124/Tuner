import XCTest
@testable import PedalTuner

final class PedalTunerTests: XCTestCase {
    func testDefaultState() {
        let tuner = AudioTuner()
        XCTAssertEqual(tuner.note, "--")
        XCTAssertEqual(tuner.cents, 0)
    }
}
