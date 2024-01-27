import SystemMonitor

@main
struct SystemMonitorCLI {
    static func main() async throws {
        var metrics = Metrics()
        while true {
            let info = metrics.cpu()
            print(info)
            try await Task.sleep(nanoseconds: UInt64(1e9))
        }
    }
}

