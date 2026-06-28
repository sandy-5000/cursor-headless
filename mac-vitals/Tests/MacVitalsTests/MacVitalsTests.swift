import XCTest
import Foundation
@testable import MacVitals

final class MacVitalsTests: XCTestCase {

    func testMemoryInfoComputesPercentAndFraction() {
        let info = MemoryInfo(usedBytes: 12 * 1_000_000_000, totalBytes: 16 * 1_000_000_000)
        XCTAssertEqual(info.fraction, 0.75, accuracy: 0.0001)
        XCTAssertEqual(info.percent, 75)
    }

    func testFractionIsClampedAndSafeWhenTotalIsZero() {
        let empty = StorageInfo(usedBytes: 0, totalBytes: 0)
        XCTAssertEqual(empty.fraction, 0)
        XCTAssertEqual(empty.percent, 0)

        let over = StorageInfo(usedBytes: 200, totalBytes: 100)
        XCTAssertEqual(over.fraction, 1)
    }

    func testLiveMemoryReadIsPlausible() {
        let info = MetricsReader.readMemory()
        XCTAssertGreaterThan(info.totalBytes, 0)
        XCTAssertLessThanOrEqual(info.usedBytes, info.totalBytes)
    }

    func testSnapshotIsCodableRoundTrip() throws {
        let snapshot = VitalsSnapshot(
            memory: MemoryInfo(usedBytes: 1, totalBytes: 2),
            storage: StorageInfo(usedBytes: 3, totalBytes: 4),
            battery: BatteryInfo(hasBattery: true, percentage: 87, state: .charging),
            capturedAt: Date(timeIntervalSince1970: 1_000)
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(VitalsSnapshot.self, from: data)
        XCTAssertEqual(decoded, snapshot)
    }
}
