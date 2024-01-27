import Darwin
import Foundation

private let _mem_layout_int = MemoryLayout<integer_t>.size
private let _n_host_basic_info: mach_msg_type_number_t = UInt32(MemoryLayout<host_basic_info_data_t>.size / _mem_layout_int)
private let _n_host_load_info: mach_msg_type_number_t = UInt32(MemoryLayout<host_load_info_data_t>.size / _mem_layout_int)
private let _n_host_cpu_load_info: mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / _mem_layout_int)
private let _n_host_vm_info64: mach_msg_type_number_t = UInt32(MemoryLayout<vm_statistics64_data_t>.size / _mem_layout_int)
private let _n_host_sched_info: mach_msg_type_number_t = UInt32(MemoryLayout<host_sched_info_data_t>.size / _mem_layout_int)
private let _n_processor_set_load_info: mach_msg_type_number_t = UInt32(MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size)

public struct CPULoadSnap {
    let user: Double
    let system: Double
    let idle: Double
    let nice: Double
}

extension CPULoadSnap: CustomStringConvertible {
    public var description: String {
        String(
            format: "[cpu] user: %.2f%% | system: %.2f%% | idle: %.2f%% | nice: %.2f%%",
            user * 100, system * 100, idle * 100, nice * 100
        )
    }
}

public struct Metrics {
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
}
