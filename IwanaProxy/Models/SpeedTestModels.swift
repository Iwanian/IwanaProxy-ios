import Foundation

struct ParsedProxy: Equatable {
    let server: String
    let port: Int
    let secret: String?
    let originalLink: String
}

enum ConnectionQuality: String {
    case excellent, good, fair, poor, offline
}

struct SpeedTestResult {
    let parsedProxy: ParsedProxy
    let dnsLookupMs: Int
    let pingSamples: [Int]
    let avgPing: Int
    let minPing: Int
    let maxPing: Int
    let jitter: Int
    let packetLossPercent: Int
    let downloadSpeedMbps: Double
    let uploadSpeedMbps: Double
    let stabilityPercent: Int
    let isSuccess: Bool
    let quality: ConnectionQuality
    let ipAddress: String?
}
