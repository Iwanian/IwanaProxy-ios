import Foundation
import Network
import CFNetwork

/// Equivalent of Android's `ProxySpeedTester.kt`.
enum ProxySpeedTester {

    /// Parses arbitrary user input into a `ParsedProxy`.
    /// Supports: tg://proxy?..., https://t.me/proxy?..., server:port:secret, server:port
    static func parseInput(_ rawInput: String) -> ParsedProxy? {
        var trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed = trimmed.replacingOccurrences(of: "\u{FEFF}", with: "")
        if trimmed.hasPrefix("\"") { trimmed.removeFirst() }
        if trimmed.hasSuffix("\"") { trimmed.removeLast() }
        if trimmed.hasPrefix("'") { trimmed.removeFirst() }
        if trimmed.hasSuffix("'") { trimmed.removeLast() }
        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        if lower.hasPrefix("tg://") || lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("t.me/") {
            let validString = lower.hasPrefix("t.me/") ? "https://\(trimmed)" : trimmed
            if let components = URLComponents(string: validString) {
                let queryItems = components.queryItems ?? []
                func value(_ name: String) -> String? { queryItems.first(where: { $0.name == name })?.value }
                let server = value("server") ?? ""
                let secret = value("secret")
                if let portStr = value("port"), let port = Int(portStr), !server.isEmpty, (1...65535).contains(port) {
                    var tgLink = "tg://proxy?server=\(server)&port=\(port)"
                    if let secret, !secret.isEmpty { tgLink += "&secret=\(secret)" }
                    return ParsedProxy(server: server.trimmingCharacters(in: .whitespaces), port: port, secret: secret?.trimmingCharacters(in: .whitespaces), originalLink: tgLink)
                }
            }
        }

        // Format 2: colon separated "server:port:secret" or "server:port"
        let parts = trimmed.components(separatedBy: ":")
        if parts.count >= 2 {
            let server = parts[0].trimmingCharacters(in: .whitespaces)
            let portStr = parts[1].trimmingCharacters(in: .whitespaces)
            let secret = parts.count >= 3 ? parts[2...].joined(separator: ":").trimmingCharacters(in: .whitespaces) : nil
            if !server.isEmpty, let port = Int(portStr), (1...65535).contains(port) {
                var tgLink = "tg://proxy?server=\(server)&port=\(port)"
                if let secret, !secret.isEmpty { tgLink += "&secret=\(secret)" }
                return ParsedProxy(server: server, port: port, secret: secret, originalLink: tgLink)
            }
        }

        return nil
    }

    /// Runs a ~7 second connection quality / latency / throughput benchmark
    /// using repeated real TCP handshake probes (same approach as the Kotlin version).
    static func runSpeedTest(
        proxy: ParsedProxy,
        targetDurationMs: Int = 7000,
        onProgress: @escaping (Double, Int?) -> Void = { _, _ in }
    ) async -> SpeedTestResult {
        let testStart = DispatchTime.now()

        // 1. DNS resolution timing
        let dnsStart = DispatchTime.now()
        var dnsLookupMs = -1
        var resolvedIp: String? = nil
        if let ip = await resolveHost(proxy.server) {
            dnsLookupMs = elapsedMs(since: dnsStart)
            resolvedIp = ip
        }

        var successfulPings: [Int] = []
        var failedCount = 0
        var totalProbes = 0

        while elapsedMs(since: testStart) < targetDurationMs {
            totalProbes += 1
            let elapsedBefore = elapsedMs(since: testStart)
            let remainingMs = max(400, targetDurationMs - elapsedBefore)
            let probeTimeout = min(remainingMs, 1800)

            let samplePing = await PingService.ping(server: proxy.server, port: proxy.port, timeoutMs: probeTimeout)
            if samplePing >= 0 {
                successfulPings.append(samplePing)
            } else {
                failedCount += 1
            }

            let elapsedAfter = elapsedMs(since: testStart)
            let progress = min(0.98, max(0.05, Double(elapsedAfter) / Double(targetDurationMs)))
            onProgress(progress, samplePing >= 0 ? samplePing : nil)

            let probeDelayMs = 280
            if elapsedMs(since: testStart) + probeDelayMs < targetDurationMs {
                try? await Task.sleep(nanoseconds: UInt64(probeDelayMs) * 1_000_000)
            } else {
                break
            }
        }

        let totalElapsed = elapsedMs(since: testStart)
        if totalElapsed < targetDurationMs {
            try? await Task.sleep(nanoseconds: UInt64(targetDurationMs - totalElapsed) * 1_000_000)
        }
        onProgress(1.0, successfulPings.last)

        let packetLossPercent = totalProbes > 0 ? Int((Double(failedCount) / Double(totalProbes)) * 100) : 100
        let isSuccess = !successfulPings.isEmpty

        guard isSuccess else {
            return SpeedTestResult(
                parsedProxy: proxy, dnsLookupMs: dnsLookupMs, pingSamples: [],
                avgPing: -1, minPing: -1, maxPing: -1, jitter: -1,
                packetLossPercent: 100, downloadSpeedMbps: 0, uploadSpeedMbps: 0,
                stabilityPercent: 0, isSuccess: false, quality: .offline, ipAddress: resolvedIp
            )
        }

        let avgPing = Int(Double(successfulPings.reduce(0, +)) / Double(successfulPings.count))
        let minPing = successfulPings.min() ?? avgPing
        let maxPing = successfulPings.max() ?? avgPing

        var jitter = 0
        if successfulPings.count > 1 {
            var diffSum = 0
            for i in 0..<(successfulPings.count - 1) {
                diffSum += abs(successfulPings[i + 1] - successfulPings[i])
            }
            jitter = diffSum / (successfulPings.count - 1)
        }

        let lossPenalty = Double(packetLossPercent) * 1.6
        let jitterRatio = min(1.0, max(0.0, Double(jitter) / Double(max(10, avgPing))))
        let jitterPenalty = jitterRatio * 32.0
        let stabilityPercent = Int(min(99.0, max(5.0, 100.0 - lossPenalty - jitterPenalty)))

        let baseThroughput = min(85.0, max(0.8, 2600.0 / (Double(avgPing) + 22.0)))
        let lossFactor = min(1.0, max(0.0, 1.0 - Double(packetLossPercent) / 100.0))
        let jitterFactor = 1.0 - min(0.5, max(0.0, Double(jitter) / (Double(avgPing) + 35.0)))
        let rawDownload = baseThroughput * lossFactor * jitterFactor
        let downloadSpeedMbps = (rawDownload * 10).rounded() / 10
        let uploadSpeedMbps = ((rawDownload * 0.65) * 10).rounded() / 10

        let quality: ConnectionQuality
        if packetLossPercent == 0 && (1...220).contains(avgPing) && jitter < 35 {
            quality = .excellent
        } else if packetLossPercent <= 10 && (1...400).contains(avgPing) {
            quality = .good
        } else if packetLossPercent <= 30 && (1...750).contains(avgPing) {
            quality = .fair
        } else if avgPing > 0 {
            quality = .poor
        } else {
            quality = .offline
        }

        return SpeedTestResult(
            parsedProxy: proxy, dnsLookupMs: dnsLookupMs, pingSamples: successfulPings,
            avgPing: avgPing, minPing: minPing, maxPing: maxPing, jitter: jitter,
            packetLossPercent: packetLossPercent, downloadSpeedMbps: downloadSpeedMbps,
            uploadSpeedMbps: uploadSpeedMbps, stabilityPercent: stabilityPercent,
            isSuccess: true, quality: quality, ipAddress: resolvedIp
        )
    }

    private static func elapsedMs(since start: DispatchTime) -> Int {
        Int((DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
    }

    /// Resolves a hostname to its first IPv4/IPv6 address string, using CFHost (no extra deps).
    private static func resolveHost(_ hostname: String) async -> String? {
        await withCheckedContinuation { continuation in
            let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
            CFHostStartInfoResolution(host, .addresses, nil)
            var resolved: DarwinBoolean = false
            guard let addressesCF = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as NSArray?,
                  resolved.boolValue else {
                continuation.resume(returning: nil)
                return
            }
            for addressObj in addressesCF {
                guard let addressData = addressObj as? Data else { continue }
                var hostnameBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let success = addressData.withUnsafeBytes { rawBufferPointer -> Bool in
                    guard let sockaddrPtr = rawBufferPointer.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return false }
                    return getnameinfo(
                        sockaddrPtr,
                        socklen_t(addressData.count),
                        &hostnameBuffer,
                        socklen_t(hostnameBuffer.count),
                        nil, 0, NI_NUMERICHOST
                    ) == 0
                }
                if success {
                    continuation.resume(returning: String(cString: hostnameBuffer))
                    return
                }
            }
            continuation.resume(returning: nil)
        }
    }
}
