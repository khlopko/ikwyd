import Foundation
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
            let logger = Logger(tmpURL: URL(fileURLWithPath: FileManager.default.currentDirectoryPath), apiKey: "bd7ae4b74aaefc6ebc66e1680fca0c36df7575a6d0d80ffcf1d9c0aeb79dccac", limit: 30)
            try await logger.start()
        }
        while true {
            //await Task.yield()
        }
    }
}

