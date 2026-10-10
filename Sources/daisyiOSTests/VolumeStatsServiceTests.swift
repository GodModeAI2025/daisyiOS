import XCTest
@testable import daisyiOS

final class VolumeStatsServiceTests: XCTestCase {
    func testInternalVolumeReturnsSaneValues() throws {
        let volume = try VolumeStatsService.internalVolume()
        XCTAssertGreaterThan(volume.totalCapacity, 0)
        XCTAssertGreaterThanOrEqual(volume.availableCapacity, 0)
        XCTAssertLessThanOrEqual(volume.availableCapacity, volume.totalCapacity)
        XCTAssertFalse(volume.name.isEmpty)
        XCTAssertGreaterThanOrEqual(volume.availableForImportantUsage, volume.availableCapacity)
    }
}
