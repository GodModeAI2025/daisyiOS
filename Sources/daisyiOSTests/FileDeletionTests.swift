import XCTest
@testable import daisyiOS

final class FileDeletionTests: XCTestCase {
    func testInternalDirectoriesBrowseUserDocumentsInstead() {
        let root = URL(filePath: "/app")
        let node = FileNode(name: "Library", url: root.appending(path: "Library"), isDirectory: true, size: 0, aggregateSize: 0, fileCount: 0, directoryCount: 1)
        XCTAssertEqual(FileLocations.browserDirectory(for: node, root: root, isAppContainer: true), root.appending(path: "Documents"))
    }
    func testFileBrowserStartsAtItsParentOnExternalVolumes() {
        let root = URL(filePath: "/volume/selected")
        let file = FileNode(name: "file", url: root.appending(path: "folder/file.txt"), isDirectory: false, size: 1, aggregateSize: 1, fileCount: 1, directoryCount: 0)
        XCTAssertEqual(FileLocations.browserDirectory(for: file, root: root, isAppContainer: false).path, root.appending(path: "folder").path)
    }
    func testRejectsRootAndPathsOutsideSelectedDirectory() {
        let root = URL(filePath: "/tmp/selected")
        XCTAssertFalse(FileDeletionService.isAllowed(root, root: root, isAppContainer: false))
        XCTAssertFalse(FileDeletionService.isAllowed(URL(filePath: "/tmp/selected-other/a"), root: root, isAppContainer: false))
        XCTAssertFalse(FileDeletionService.isAllowed(root.appending(path: "../outside"), root: root, isAppContainer: false))
        XCTAssertTrue(FileDeletionService.isAllowed(root.appending(path: "nested/file"), root: root, isAppContainer: false))
    }
    func testProtectsInternalPreferencesButAllowsUserDocuments() {
        let root = URL(filePath: "/tmp/app")
        XCTAssertFalse(FileDeletionService.isAllowed(root.appending(path: "Library/Preferences/settings.plist"), root: root, isAppContainer: true))
        XCTAssertFalse(FileDeletionService.isAllowed(root.appending(path: ".metadata.plist"), root: root, isAppContainer: true))
        XCTAssertTrue(FileDeletionService.isAllowed(root.appending(path: "Documents/file.txt"), root: root, isAppContainer: true))
        XCTAssertTrue(FileDeletionService.isAllowed(root.appending(path: "Library/Caches/data"), root: root, isAppContainer: true))
    }
    func testDeletionRemovesOnlyTheSelectedFile() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appending(path: "target.txt")
        let sibling = root.appending(path: "sibling.txt")
        try Data("target".utf8).write(to: target)
        try Data("keep".utf8).write(to: sibling)
        try await FileDeletionService().remove(target, root: root, isAppContainer: false)
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sibling.path))
    }
    func testSymlinkOutsideSelectedDirectoryCannotDeleteExternalData() async throws {
        let base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let root = base.appending(path: "selected")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        let outside = base.appending(path: "outside.txt")
        try Data("keep".utf8).write(to: outside)
        let link = root.appending(path: "link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        do {
            try await FileDeletionService().remove(link, root: root, isAppContainer: false)
            XCTFail("External symlink must be rejected")
        } catch is FileDeletionService.DeletionError {}
        XCTAssertTrue(FileManager.default.fileExists(atPath: outside.path))
    }
    @MainActor func testDeletionUpdatesAllAncestorSizesAndCounts() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let folderURL = rootURL.appending(path: "nested")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let fileURL = folderURL.appending(path: "file.txt")
        try Data("data".utf8).write(to: fileURL)
        let file = FileNode(name: "file.txt", url: fileURL, isDirectory: false, size: 4, aggregateSize: 4, fileCount: 1, directoryCount: 0)
        let folder = FileNode(name: "nested", url: folderURL, isDirectory: true, size: 1, aggregateSize: 5, fileCount: 1, directoryCount: 1, children: [file])
        let root = FileNode(name: "root", url: rootURL, isDirectory: true, size: 1, aggregateSize: 6, fileCount: 1, directoryCount: 2, children: [folder])
        let result = ScanResult(root: root, isAppContainer: false)
        let deleted = await result.delete(file)
        XCTAssertTrue(deleted)
        XCTAssertEqual(result.root.aggregateSize, 2)
        XCTAssertEqual(result.root.fileCount, 0)
        XCTAssertEqual(result.root.directoryCount, 2)
        XCTAssertNil(result.find(fileURL))
        XCTAssertFalse(result.isDeleting)
    }
}
