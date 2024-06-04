import Noise
import XCTest

final class StubTests_swift: XCTestCase {

    override func setUpWithError() throws {
        // This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // This method is called after the invocation of each test method in the class.
    }

    func testRandomXorshiftConsistency() throws {
        var rand1 = RandomXorshift(seed: 5)
        var rand2 = RandomXorshift(seed: 5)
        XCTAssertEqual(rand1.generate(), rand2.generate())
        XCTAssertEqual(rand1.generate(), rand2.generate())
        XCTAssertEqual(rand1.generate(), rand2.generate())
        XCTAssertEqual(rand1.generate(), rand2.generate())
        XCTAssertEqual(rand1.generate(), rand2.generate())
    }

}
