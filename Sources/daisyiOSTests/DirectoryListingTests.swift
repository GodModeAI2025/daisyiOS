import XCTest
@testable import daisyiOS

final class DirectoryListingTests: XCTestCase {
    private func entry(_ name: String, folder: Bool, size: Int64) -> FileNode {
        FileNode(name: name, url: URL(filePath: "/\(name)"), isDirectory: folder, size: size, aggregateSize: size, fileCount: folder ? 0 : 1, directoryCount: folder ? 1 : 0)
    }
    func testFoldersStayFirstForEverySortOrder() {
        let entries = [entry("Z.log", folder: false, size: 1000), entry("B", folder: true, size: 1), entry("A", folder: true, size: 20), entry("A.log", folder: false, size: 2)]
        for sort in EntrySort.allCases {
            let list = DirectoryListing.entries(entries, query: "", filter: .all, sort: sort)
            XCTAssertTrue(list.prefix(2).allSatisfy(\.isDirectory))
            XCTAssertTrue(list.suffix(2).allSatisfy { !$0.isDirectory })
        }
        XCTAssertEqual(DirectoryListing.entries(entries, query: "", filter: .all, sort: .largest).map(\.name), ["A", "B", "Z.log", "A.log"])
        XCTAssertEqual(DirectoryListing.entries(entries, query: "", filter: .all, sort: .smallest).map(\.name), ["B", "A", "A.log", "Z.log"])
    }
    func testSearchAndFilterCombineWithoutLosingMatchingEntries() {
        let entries = [entry("Logs", folder: true, size: 10), entry("Other", folder: true, size: 20), entry("app.log", folder: false, size: 100)]
        XCTAssertEqual(DirectoryListing.entries(entries, query: "log", filter: .folders, sort: .name).map(\.name), ["Logs"])
        XCTAssertEqual(DirectoryListing.entries(entries, query: "log", filter: .files, sort: .name).map(\.name), ["app.log"])
        XCTAssertEqual(DirectoryListing.entries(entries, query: "", filter: .all, sort: .name).count, 3)
    }
    func testNestedLookupDoesNotConfuseFoldersWithSharedPrefix() {
        let target = FileNode(name: "file", url: URL(filePath: "/root/AB/file"), isDirectory: false, size: 1, aggregateSize: 1, fileCount: 1, directoryCount: 0)
        let a = FileNode(name: "A", url: URL(filePath: "/root/A"), isDirectory: true, size: 0, aggregateSize: 0, fileCount: 0, directoryCount: 1)
        let ab = FileNode(name: "AB", url: URL(filePath: "/root/AB"), isDirectory: true, size: 0, aggregateSize: 1, fileCount: 1, directoryCount: 1, children: [target])
        let root = FileNode(name: "root", url: URL(filePath: "/root"), isDirectory: true, size: 0, aggregateSize: 1, fileCount: 1, directoryCount: 3, children: [a, ab])
        XCTAssertEqual(root.find(target.url)?.id, target.id)
        XCTAssertNil(root.find(URL(filePath: "/root/AC/file")))
    }

}
