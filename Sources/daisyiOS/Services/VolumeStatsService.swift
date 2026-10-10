import Foundation

enum VolumeStatsService {
    static func internalVolume() throws -> VolumeInfo {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try url.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey
        ])
        return VolumeInfo(
            name: values.volumeName ?? UIDeviceFallbackName,
            totalCapacity: Int64(values.volumeTotalCapacity ?? 0),
            availableCapacity: Int64(values.volumeAvailableCapacity ?? 0),
            availableForImportantUsage: Int64(values.volumeAvailableCapacityForImportantUsage ?? 0),
            availableForOpportunisticUsage: Int64(values.volumeAvailableCapacityForOpportunisticUsage ?? 0)
        )
    }

    private static var UIDeviceFallbackName: String {
        "iPhone"
    }
}
