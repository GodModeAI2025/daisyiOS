import Foundation

struct VolumeInfo: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let totalCapacity: Int64
    let availableCapacity: Int64
    let availableForImportantUsage: Int64
    let availableForOpportunisticUsage: Int64

    init(
        id: UUID = UUID(),
        name: String,
        totalCapacity: Int64,
        availableCapacity: Int64,
        availableForImportantUsage: Int64,
        availableForOpportunisticUsage: Int64
    ) {
        self.id = id
        self.name = name
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.availableForImportantUsage = availableForImportantUsage
        self.availableForOpportunisticUsage = availableForOpportunisticUsage
    }

    var usedCapacity: Int64 {
        max(0, totalCapacity - availableCapacity)
    }

    var purgeableCapacity: Int64 {
        max(0, availableForImportantUsage - availableCapacity)
    }
}
