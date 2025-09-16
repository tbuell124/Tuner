import XCTest
@testable import TunePlay

final class TunePlayTests: XCTestCase {
    func testDefaultState() {
        let tuner = AudioTuner()
        XCTAssertEqual(tuner.note, "--")
        XCTAssertEqual(tuner.cents, 0)
    }
}
