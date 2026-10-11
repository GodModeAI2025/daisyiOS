import XCTest
@testable import daisyiOS

final class CleanupCandidateTests: XCTestCase {
    func testRecursesAndDoesNotDoubleCountCacheChildrenOrOfferBackups() {
        func node(_ name: String, folder: Bool = false, children: [FileNode] = []) -> FileNode {
            FileNode(name: name, url: URL(filePath: "/chosen/\(name)"), isDirectory: folder, size: 1, aggregateSize: 10, fileCount: 1, directoryCount: folder ? 1 : 0, children: children)
        }
        let root = node("chosen", folder: true, children: [
            node("ordinary", folder: true, children: [node("app.log"), node("notes.pdf")]),
            node("Caches", folder: true, children: [node("cache.tmp")]),
            node("Backups", folder: true, children: [node("backup.log")])
        ])
        let candidates = CleanupCandidates.find(in: root)
        XCTAssertEqual(Set(candidates.map { $0.node.name }), ["app.log", "Caches"])
    }
    func testProtectedContentInsideTempPreventsOfferingWholeFolder() {
        let protected = FileNode(name: "Backups", url: URL(filePath: "/tmp/Backups"), isDirectory: true, size: 0, aggregateSize: 20, fileCount: 1, directoryCount: 1)
        let log = FileNode(name: "x.log", url: URL(filePath: "/tmp/x.log"), isDirectory: false, size: 5, aggregateSize: 5, fileCount: 1, directoryCount: 0)
        let temp = FileNode(name: "tmp", url: URL(filePath: "/tmp"), isDirectory: true, size: 0, aggregateSize: 25, fileCount: 2, directoryCount: 2, children: [protected, log])
        let root = FileNode(name: "root", url: URL(filePath: "/"), isDirectory: true, size: 0, aggregateSize: 25, fileCount: 2, directoryCount: 3, children: [temp])
        XCTAssertEqual(CleanupCandidates.find(in: root).map { $0.node.name }, ["x.log"])
    }
}
