#if os(macOS)
import XCTest
import SwiftUI
@testable import daisyiOS

@MainActor
final class MacProgressLayoutTests: XCTestCase {
    func testProgressKeepsItsSizeWhenPathAndCountsChange() {
        let short = ScanModel()
        short.scannedFolderName = "Testordner"
        short.progress = ScanProgress(filesScanned: 1, directoriesScanned: 1, bytesScanned: 1, currentPath: "a")
        let long = ScanModel()
        long.scannedFolderName = "Testordner"
        long.progress = ScanProgress(filesScanned: 200000, directoriesScanned: 40000, bytesScanned: 100000000000, unreadableEntries: 3, currentPath: String(repeating: "very-long-filename-", count: 10))
        let first = NSHostingView(rootView: ScanActivityView(model: short)).fittingSize
        let second = NSHostingView(rootView: ScanActivityView(model: long)).fittingSize
        XCTAssertEqual(first.width, second.width, accuracy: 0.5)
        XCTAssertEqual(first.height, second.height, accuracy: 0.5)
    }
}
#endif
