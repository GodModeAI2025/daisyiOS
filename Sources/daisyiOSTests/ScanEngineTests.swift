import XCTest
@testable import daisyiOS

final class ScanEngineTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appending(path: "daisyiOS-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testScanAggregatesSizesAndCounts() async throws {
        let dirA = tempDir.appending(path: "A")
        try FileManager.default.createDirectory(at: dirA, withIntermediateDirectories: true)
        try Data(count: 1024).write(to: dirA.appending(path: "a1.bin"))
        try Data(count: 2048).write(to: dirA.appending(path: "a2.bin"))

        let dirB = tempDir.appending(path: "B")
        try FileManager.default.createDirectory(at: dirB, withIntermediateDirectories: true)
        let dirBC = dirB.appending(path: "C")
        try FileManager.default.createDirectory(at: dirBC, withIntermediateDirectories: true)
        try Data(count: 512).write(to: dirBC.appending(path: "b1.bin"))

        let engine = ScanEngine()
        var root: FileNode?
        var progressEvents = 0
        for await event in await engine.scan(tempDir) {
            switch event {
            case .progress:
                progressEvents += 1
            case .finished(let node):
                root = node
            case .failed(let error):
                XCTFail("Unexpected scan failure: \(error)")
            }
        }

        let node = try XCTUnwrap(root)
        XCTAssertEqual(node.fileCount, 3)
        XCTAssertEqual(node.directoryCount, 4)
        XCTAssertGreaterThanOrEqual(node.aggregateSize, 3584)
        XCTAssertEqual(node.children.count, 2)
        XCTAssertEqual(node.children.filter(\.isDirectory).count, 2)
        XCTAssertGreaterThan(progressEvents, 0)
    }

    func testProgressNeverMovesBackwards() async throws {
        for index in 0..<10 {
            let directory = tempDir.appending(path: "folder-\(index)/nested/deep")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data(count: 1024).write(to: directory.appending(path: "data"))
        }
        var previous = ScanProgress()
        for await event in await ScanEngine().scan(tempDir) {
            if case .progress(let current) = event {
                XCTAssertGreaterThanOrEqual(current.filesScanned, previous.filesScanned)
                XCTAssertGreaterThanOrEqual(current.directoriesScanned, previous.directoriesScanned)
                XCTAssertGreaterThanOrEqual(current.bytesScanned, previous.bytesScanned)
                previous = current
            }
        }
    }

    func testScanEmptyDirectory() async throws {
        let empty = tempDir.appending(path: "empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        let engine = ScanEngine()
        var root: FileNode?
        for await event in await engine.scan(empty) {
            if case let .finished(node) = event {
                root = node
            }
        }

        let node = try XCTUnwrap(root)
        XCTAssertEqual(node.fileCount, 0)
        XCTAssertEqual(node.directoryCount, 1)
        XCTAssertTrue(node.children.isEmpty)
    }

    func testScanInaccessiblePathFails() async throws {
        let missing = tempDir.appending(path: "does-not-exist")
        let engine = ScanEngine()
        var failed = false
        for await event in await engine.scan(missing) {
            if case .failed = event {
                failed = true
            }
        }
        XCTAssertTrue(failed)
    }
    func testLargeFlatFolderIsCompleteAndReportsProgress() async throws {
        for index in 0..<5000 {
            try Data([1]).write(to: tempDir.appending(path: "file-\(index).log"))
        }
        var lastProgress = ScanProgress()
        var sawProgressBeforeCompletion = false
        var root: FileNode?
        for await event in await ScanEngine().scan(tempDir) {
            switch event {
            case .progress(let progress):
                if progress.filesScanned < 5000 {
                    sawProgressBeforeCompletion = true
                }
                lastProgress = progress
            case .finished(let node): root = node
            case .failed(let error): XCTFail("\(error)")
            }
        }
        XCTAssertEqual(root?.fileCount, 5000)
        XCTAssertEqual(root?.children.count, 5000)
        XCTAssertEqual(lastProgress.filesScanned, 5000)
        XCTAssertEqual(lastProgress.unreadableEntries, 0)
        XCTAssertTrue(sawProgressBeforeCompletion)
    }

    func testCancellationDoesNotPublishCompletedResult() async throws {
        for index in 0..<1000 {
            try Data([1]).write(to: tempDir.appending(path: "file-\(index)"))
        }
        let url = try XCTUnwrap(tempDir)
        let consumer = Task {
            var finished = false
            for await event in await ScanEngine().scan(url) {
                if case .progress = event {
                    withUnsafeCurrentTask { $0?.cancel() }
                }
                if case .finished = event { finished = true }
            }
            return finished
        }
        let finished = await consumer.value
        XCTAssertFalse(finished)
    }

}
