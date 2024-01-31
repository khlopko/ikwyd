import SystemMonitor

@main
struct SystemMonitorCLI {
    static func main() async throws {
        var metrics = Metrics()
        while true {
            let basic = metrics.basicInfo()
            print(basic)
            let cpu = metrics.cpu()
            print(cpu)
            let mem = metrics.memory()
            print(mem)
            try await Task.sleep(nanoseconds: UInt64(1e9))
        }
    }
}

