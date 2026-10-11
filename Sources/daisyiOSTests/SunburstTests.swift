import XCTest
@testable import daisyiOS

final class SunburstTests: XCTestCase {
    func testSegmentsRepresentActualSizeAndDepth() {
        let file = FileNode(name: "file", url: URL(filePath: "/a/file"), isDirectory: false, size: 60, aggregateSize: 60, fileCount: 1, directoryCount: 0)
        let folder = FileNode(name: "a", url: URL(filePath: "/a"), isDirectory: true, size: 0, aggregateSize: 60, fileCount: 1, directoryCount: 1, children: [file])
        let root = FileNode(name: "root", url: URL(filePath: "/"), isDirectory: true, size: 40, aggregateSize: 100, fileCount: 1, directoryCount: 2, children: [folder])
        let segments = SunburstChart.segments(for: root)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].end - segments[0].start, 2 * .pi * 0.6, accuracy: 0.0001)
        XCTAssertEqual(segments[1].depth, 1)
        XCTAssertEqual(segments[0].colorIndex, segments[1].colorIndex)
        XCTAssertEqual(segments[0].end, segments[1].end)
    }
    func testEmptyFolderHasNoSegments() {
        let root = FileNode(name: "empty", url: URL(filePath: "/"), isDirectory: true, size: 0, aggregateSize: 0, fileCount: 0, directoryCount: 1)
        XCTAssertTrue(SunburstChart.segments(for: root).isEmpty)
    }
    func testTinyFilesDoNotCreateThousandsOfViewsOrDisappearFromData() {
        let files = (0..<10000).map { index in
            FileNode(name: "\(index)", url: URL(filePath: "/\(index)"), isDirectory: false, size: 1, aggregateSize: 1, fileCount: 1, directoryCount: 0)
        }
        let root = FileNode(name: "large", url: URL(filePath: "/"), isDirectory: true, size: 0, aggregateSize: 10000, fileCount: 10000, directoryCount: 1, children: files)
        XCTAssertLessThan(SunburstChart.segments(for: root).count, 500)
        XCTAssertEqual(root.children.count, 10000)
        XCTAssertEqual(root.fileCount, 10000)
    }

}
