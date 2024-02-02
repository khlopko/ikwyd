import Foundation

public actor Logger {

    private var buffer = Data()
    private let iso8601 = ISO8601DateFormatter()
    private let limit = 30
    private let packetSize = 10
    private var uploadTrigger = 0
    private var metrics = Metrics()
    private let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath.appending("/logs.bin"))
    private let session = URLSession.shared

    public init() {
    }

    public func start() async throws {
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
        if uploadTrigger == 6 {
            uploadTrigger = 0
            try await upload()
        } else {
            uploadTrigger += 1
        }
        try await Task.sleep(nanoseconds: UInt64(2e9))
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
        var request = URLRequest(url: URL(string: "http://localhost:8080/rotterdam")!)
        request.httpMethod = "POST"
        request.httpBody = try Data(contentsOf: outputURL)
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