import Foundation

struct ScanProgress: Sendable, Equatable {
    var filesScanned: Int = 0
    var directoriesScanned: Int = 0
    var bytesScanned: Int64 = 0
    var elapsed: TimeInterval = 0
}
