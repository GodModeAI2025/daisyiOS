import XCTest
@testable import daisyiOS

final class BatchSelectionTests: XCTestCase {
    func testCollapsesSelectedFolderAndChildWithoutConfusingSiblingPrefix() {
        func node(_ path: String, folder: Bool) -> FileNode {
            FileNode(name: URL(filePath: path).lastPathComponent, url: URL(filePath: path), isDirectory: folder, size: 1, aggregateSize: 1, fileCount: 1, directoryCount: folder ? 1 : 0)
        }
        let folder = node("/root/A", folder: true)
        let child = node("/root/A/x", folder: false)
        let other = node("/root/AB/x", folder: false)
        XCTAssertEqual(Set(DeletionSelection.minimalRoots([child, folder, folder, other]).map { $0.url.path }), ["/root/A", "/root/AB/x"])
    }
    @MainActor func testSelectAllRetainsExistingSelectionAndClearResetsCounts() {
        func node(_ name: String) -> FileNode {
            FileNode(name: name, url: URL(filePath: "/\(name)"), isDirectory: false, size: 10, aggregateSize: 10, fileCount: 1, directoryCount: 0)
        }
        let a = node("a"), b = node("b")
        let selection = BatchSelection()
        selection.toggle(a)
        selection.select([a, b])
        XCTAssertEqual(selection.count, 2)
        XCTAssertEqual(selection.bytes, 20)
        selection.clear()
        XCTAssertEqual(selection.count, 0)
        XCTAssertEqual(selection.bytes, 0)
    }
    func testBatchRemovesOnlySelectedFilesAndUpdatesCounts() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "batch-test-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["a", "b", "keep"] { try Data([1]).write(to: dir.appending(path: name)) }
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let node) = event { root = node } }
        let snapshot = try XCTUnwrap(root)
        let result = await MainActor.run { ScanResult(root: snapshot, isAppContainer: false) }
        let outcome = await result.deleteNodes(snapshot.children.filter { $0.name != "keep" })
        XCTAssertEqual(outcome.removed.count, 2)
        XCTAssertEqual(outcome.failed, 0)
        let updated = await result.root
        XCTAssertEqual(updated.children.map(\.name), ["keep"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appending(path: "keep").path))
    }
}
