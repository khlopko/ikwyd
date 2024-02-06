import Foundation

public actor Logger {

    private var buffer = Data()
    private let iso8601 = ISO8601DateFormatter()
    private let limit: Int
    private let packetSize = 10
    private var uploadTrigger = 0
    private var metrics = Metrics()
    private let outputURL: URL
    private let session = URLSession.shared
    private let address: String
    private let apiKey: String
    private let nanosecondsInterval: TimeInterval

    public init(tmpURL: URL, address: String, apiKey: String, nanosecondsInterval: TimeInterval = 2e9, limit: Int = 1024) {
        self.outputURL = tmpURL.appendingPathComponent("logs.bin")
        self.address = address
        self.apiKey = apiKey
        self.nanosecondsInterval = nanosecondsInterval
        self.limit = limit
    }

    public func start() async throws {
        while true {
            try await iter()
        }
    }

    public func iter() async throws {
        try flushIfNeeded()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        append(UInt8(components.day!))
        append(UInt8(components.month!))
        append(UInt16(components.year!))
        append(UInt8(components.hour!))
        append(UInt8(components.minute!))
        append(UInt8(components.second!))
        let cpu = metrics.cpu()
        append(UInt8(cpu.user * 100))
        let mem = metrics.memory()
        append(UInt16(mem.used))
        if uploadTrigger == limit * 3 / packetSize {
            uploadTrigger = 0
            try await upload()
        } else {
            uploadTrigger += 1
        }
        try await Task.sleep(nanoseconds: UInt64(nanosecondsInterval))
    }

    private func append<T>(_ value: T) {
        withUnsafeBytes(of: value, { buffer.append(contentsOf: $0) })
    }

    private func flushIfNeeded() throws {
        if buffer.count > limit - packetSize {
            try buffer.append(fileURL: outputURL)
            buffer.removeAll(keepingCapacity: true)
        }
    }

    private func upload() async throws {
        var request = URLRequest(url: URL(string: "\(address)/rotterdam")!)
        request.httpMethod = "POST"
        request.httpBody = try Data(contentsOf: outputURL)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        let (_, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("Upload completed with status code: \(status)")
        try FileManager.default.removeItem(at: outputURL)
    }

}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
                fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
