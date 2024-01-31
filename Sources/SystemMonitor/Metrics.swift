import Darwin
import Foundation

/// A snapshot of basic system information.
public struct Metrics {
    private static let megabyte = 1048576.0

    private var prevCPU = host_cpu_load_info()
    
    public init() {
    }

    public mutating func cpu() -> CPULoadSnap {
        var size = _n_host_cpu_load_info
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(
                mach_host_self(),
                HOST_CPU_LOAD_INFO,
                $0,
                &size
            )
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        let u = Double(data.cpu_ticks.0 - prevCPU.cpu_ticks.0)
        let s = Double(data.cpu_ticks.1 - prevCPU.cpu_ticks.1)
        let i = Double(data.cpu_ticks.2 - prevCPU.cpu_ticks.2)
        let n = Double(data.cpu_ticks.3 - prevCPU.cpu_ticks.3)
        let t = u + s + i + n
        prevCPU = data
        return CPULoadSnap(user: u / t, system: s / t, idle: i / t, nice: n / t)
    }

    public func memory() -> MemorySnap {
        var size = mach_msg_type_number_t(_n_host_vm_info64)
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(
                mach_host_self(),
                HOST_VM_INFO64,
                $0,
                &size
            )
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        let compressed = Double(data.compressor_page_count) * Double(vm_kernel_page_size) / Self.megabyte
        return MemorySnap(
            active: Double(data.active_count) * Double(vm_kernel_page_size) / Self.megabyte,
            inactive: Double(data.inactive_count) * Double(vm_kernel_page_size) / Self.megabyte,
            wired: Double(data.wire_count) * Double(vm_kernel_page_size) / Self.megabyte,
            free: Double(data.free_count) * Double(vm_kernel_page_size) / Self.megabyte,
            compressed: Double(compressed)
        )
    }

    public func basicInfo() -> BasicInfoSnap {
        var size = mach_msg_type_number_t(_n_host_basic_info)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(
                mach_host_self(),
                HOST_BASIC_INFO,
                $0,
                &size
            )
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return BasicInfoSnap(
            cpuCount: Int(data.logical_cpu_max),
            physicalMemory: Double(data.max_mem) / Self.megabyte
        )
    }

}
