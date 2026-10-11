import Foundation

struct ScanProgress: Sendable, Equatable {
    var filesScanned: Int = 0
    var directoriesScanned: Int = 0
    var bytesScanned: Int64 = 0
    var unreadableEntries: Int = 0
    var currentPath: String = ""
    var elapsed: TimeInterval = 0
}
