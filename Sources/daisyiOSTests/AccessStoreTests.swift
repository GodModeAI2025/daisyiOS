import XCTest
@testable import daisyiOS

final class AccessStoreTests: XCTestCase {
    func testSavedFolderReopensWithoutDuplicate() async throws {
        let suite = "OrbitDiskTests." + UUID().uuidString
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = AccessStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        try await store.add(name: "Test", url: folder)
        try await store.add(name: "Test", url: folder)
        let folders = await store.folders
        XCTAssertEqual(folders.count, 1)
        let reopened = try await store.url(for: XCTUnwrap(folders.first))
        XCTAssertEqual(reopened.resolvingSymlinksInPath(), folder.resolvingSymlinksInPath())
    }

    func testInvalidBookmarkThrows() async {
        let store = AccessStore()
        do {
            _ = try await store.url(for: .init(name: "Invalid", bookmark: Data([0, 1, 2])))
            XCTFail("Invalid bookmarks must not resolve")
        } catch {}
    }
}
