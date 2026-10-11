import XCTest
@testable import daisyiOS

final class DuplicateEngineTests: XCTestCase {
    func testFindsContentCopiesButNotSameSizeDifferentContent() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "duplicate-test-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for (name, content) in [("a.txt", "AAA"), ("b.txt", "AAA"), ("c.txt", "BBB")] {
            try Data(content.utf8).write(to: dir.appending(path: name))
        }
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let node) = event { root = node } }
        let snapshot = try XCTUnwrap(root)
        var groups: [DuplicateGroup] = []
        for await event in DuplicateEngine.scan(snapshot, lease: nil) {
            if case .finished(let value, let unreadable, _) = event { groups = value; XCTAssertEqual(unreadable, 0) }
        }
        XCTAssertEqual(groups.count, 1)
        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(Set(group.files.map { $0.url.lastPathComponent }), ["a.txt", "b.txt"])
        let keep = group.files[0], remove = group.files[1]
        try await FileDeletionService().removeDuplicate(remove, keeping: keep, hash: group.hash, root: dir, isAppContainer: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: keep.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: remove.url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appending(path: "c.txt").path))
    }
    func testChangedKeeperPreventsDeletion() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "duplicate-change-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["a", "b"] { try Data("same".utf8).write(to: dir.appending(path: name)) }
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let value) = event { root = value } }
        var groups: [DuplicateGroup] = []
        for await event in DuplicateEngine.scan(try XCTUnwrap(root), lease: nil) { if case .finished(let value, _, _) = event { groups = value } }
        let group = try XCTUnwrap(groups.first)
        try Data("changed".utf8).write(to: group.files[0].url)
        do {
            try await FileDeletionService().removeDuplicate(group.files[1], keeping: group.files[0], hash: group.hash, root: dir, isAppContainer: false)
            XCTFail("Changed keeper must prevent removal")
        } catch {}
        XCTAssertTrue(FileManager.default.fileExists(atPath: group.files[1].url.path))
    }
    func testBatchKeepsChosenCopyAndUpdatesTreeOnce() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "duplicate-batch-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["a", "b", "c"] { try Data("same".utf8).write(to: dir.appending(path: name)) }
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let node) = event { root = node } }
        let snapshot = try XCTUnwrap(root)
        var groups: [DuplicateGroup] = []
        for await event in DuplicateEngine.scan(snapshot, lease: nil) { if case .finished(let value, _, _) = event { groups = value } }
        let group = try XCTUnwrap(groups.first)
        let result = await MainActor.run { ScanResult(root: snapshot, isAppContainer: false) }
        let outcome = await result.deleteDuplicateGroup(Array(group.files.dropFirst()), keeping: group.files[0], hash: group.hash)
        XCTAssertEqual(outcome.removed.count, 2)
        XCTAssertEqual(outcome.failed, 0)
        let updated = await result.root
        XCTAssertEqual(updated.fileCount, 1)
        XCTAssertEqual(updated.children.count, 1)
        XCTAssertEqual(updated.children[0].url, group.files[0].url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: group.files[0].url.path))
    }
    func testHardLinksAreNotOfferedAsRemovableCopies() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "duplicate-links-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let a = dir.appending(path: "a")
        try Data("same".utf8).write(to: a)
        try FileManager.default.linkItem(at: a, to: dir.appending(path: "linked"))
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let node) = event { root = node } }
        for await event in DuplicateEngine.scan(try XCTUnwrap(root), lease: nil) {
            if case .finished(let groups, _, let excluded) = event {
                XCTAssertTrue(groups.isEmpty)
                XCTAssertEqual(excluded, 2)
            }
        }
    }

    func testMissingCachedDirectoryDoesNotHideOtherDuplicates() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "duplicate-partial-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["a", "b"] { try Data("same".utf8).write(to: dir.appending(path: name)) }
        var root: FileNode?
        for await event in await ScanEngine().scan(dir) { if case .finished(let node) = event { root = node } }
        var snapshot = try XCTUnwrap(root)
        snapshot.children.append(FileNode(name: "missing", url: dir.appending(path: "missing"), isDirectory: true, size: 0, aggregateSize: 0, fileCount: 1, directoryCount: 1))
        var completed = false
        for await event in DuplicateEngine.scan(snapshot, lease: nil) {
            if case .finished(let groups, let unreadable, _) = event {
                completed = true
                XCTAssertEqual(groups.count, 1)
                XCTAssertEqual(unreadable, 1)
            }
        }
        XCTAssertTrue(completed)
    }

}
