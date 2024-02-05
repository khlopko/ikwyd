import SystemMonitor

@main
struct SystemMonitorCLI {
    private static var loggingTask: Task<Void, Error>?

    static func main() async throws {
        /*
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
        */
        loggingTask = Task.detached {
            let logger = Logger(limit: 30)
            while true {
                try await logger.start()
            }
        }
        while true {
            //await Task.yield()
        }
    }
}

