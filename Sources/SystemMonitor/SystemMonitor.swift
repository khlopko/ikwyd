import Darwin
import Foundation

private let _mem_layout_int = MemoryLayout<integer_t>.size

internal let _n_host_basic_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<host_basic_info_data_t>.size / _mem_layout_int
)
internal let _n_host_load_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<host_load_info_data_t>.size / _mem_layout_int
)
internal let _n_host_cpu_load_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<host_cpu_load_info_data_t>.size / _mem_layout_int
)
internal let _n_host_vm_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<vm_statistics_data_t>.size / _mem_layout_int
)
internal let _n_host_vm_info64: mach_msg_type_number_t = UInt32(
    MemoryLayout<vm_statistics64_data_t>.size / _mem_layout_int
)
internal let _n_host_sched_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<host_sched_info_data_t>.size / _mem_layout_int
)
internal let _n_processor_set_load_info: mach_msg_type_number_t = UInt32(
    MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size
)

/// A snapshot of basic system information.
public struct BasicInfoSnap {

    /// The number of CPUs available to the system.
    public let cpuCount: Int

    /// The amount of physical memory (in Mb) available to the system.
    public let physicalMemory: Double

}

extension BasicInfoSnap: CustomStringConvertible {
    public var description: String {
        return String(
            format: "[basic] cpuCount: %d | physicalMemory: %.2fMb",
            cpuCount, physicalMemory
        )
    }
}

/// A snapshot of CPU load.
public struct CPULoadSnap {

    /// The percentage of CPU time spent executing user code.
    public let user: Double

    /// The percentage of CPU time spent executing system code.
    public let system: Double

    /// The percentage of CPU time spent idle.
    public let idle: Double

    /// The percentage of CPU time spent executing low-priority user code.
    public let nice: Double

}

extension CPULoadSnap: CustomStringConvertible {
    public var description: String {
        String(
            format: "[cpu] user: %.2f%% | system: %.2f%% | idle: %.2f%% | nice: %.2f%%",
            user * 100, system * 100, idle * 100, nice * 100
        )
    }
}

/// A snapshot of the memory usage of the system.
public struct MemorySnap {

    /// Memory (in Mb) in use by applications and the OS.
    public var used: Double {
        return active + inactive + wired
    }

    // Memory (in Mb) in use by applications
    public let active: Double

    /// Memory (in Mb) that is currently not in use, but was recently used. It either belongs to recently closed apps,
    /// or actually belongs to active apps, but has not been used in a while.
    public let inactive: Double
    
    /// Memory (in Mb) that is used by the OS and can't be freed up. It is reserved for the OS and can't be used by apps.
    public let wired: Double
    
    /// Memory (in Mb) that is not used at all.
    public let free: Double

    /// Memory (in Mb) that is compressed by the OS. It is not used by apps, but it is not free either.
    public let compressed: Double

}

extension MemorySnap: CustomStringConvertible {
    public var description: String {
        return String(
            format: "[mem] used: %.2fMb | active: %.2fMb | inactive: %.2fMb | wired: %.2fMb | free: %.2fMb | compressed: %.2fMb",
            used, active, inactive, wired, free, compressed
        )
    }
}
