// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "system-monitor",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(name: "SystemMonitor", targets: ["SystemMonitor"]),
        .executable(name: "SystemMonitorCLI", targets: ["SystemMonitorCLI"])
    ],
    targets: [
        .executableTarget(
            name: "SystemMonitorCLI",
            dependencies: [.target(name: "SystemMonitor")], 
            path: "swift-monitor/cli"
        ),
        .target(
            name: "SystemMonitor",
            path: "swift-monitor/lib"
        )
    ]
)
