import Foundation
import Network

/// Equivalent of Android's `PingService.kt`.
/// Measures TCP handshake latency to a proxy's server:port using NWConnection.
enum PingService {

    /// Connects to `server:port` and measures the TCP handshake round-trip in ms.
    /// Returns -1 if the connection fails or times out.
    static func ping(server: String, port: Int, timeoutMs: Int = 2000) async -> Int {
        await withCheckedContinuation { continuation in
            var didResume = false
            let resumeLock = NSLock()
            func resumeOnce(_ value: Int) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                if !didResume {
                    didResume = true
                    continuation.resume(returning: value)
                }
            }

            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                resumeOnce(-1)
                return
            }

            let params = NWParameters.tcp
            params.preferNoProxies = true
            let connection = NWConnection(host: NWEndpoint.Host(server), port: nwPort, using: params)
            let queue = DispatchQueue(label: "com.iwanaproxy.ping.\(server).\(port)")
            let startTime = DispatchTime.now()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsedNs = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
                    let elapsedMs = max(1, Int(elapsedNs / 1_000_000))
                    resumeOnce(elapsedMs)
                    connection.cancel()
                case .failed, .cancelled:
                    resumeOnce(-1)
                default:
                    break
                }
            }

            queue.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                resumeOnce(-1)
                connection.cancel()
            }

            connection.start(queue: queue)
        }
    }

    /// Pings all proxies concurrently with bounded concurrency (equivalent to the
    /// Kotlin Semaphore(24)), returning updated items with ping/isAlive/isScanned set.
    static func pingAll(_ proxies: [ProxyItem], maxConcurrent: Int = 24) async -> [ProxyItem] {
        var results = [ProxyItem](repeating: ProxyItem(id: 0, server: "", port: 0, secret: "", link: ""), count: proxies.count)
        await withTaskGroup(of: (Int, ProxyItem).self) { group in
            var index = 0
            var inFlight = 0

            func launchNext() {
                guard index < proxies.count else { return }
                let currentIndex = index
                let proxy = proxies[currentIndex]
                index += 1
                inFlight += 1
                group.addTask {
                    let latency = await ping(server: proxy.server, port: proxy.port)
                    var updated = proxy
                    if latency > 0 {
                        updated.ping = latency
                        updated.isAlive = true
                    } else {
                        updated.ping = -1
                        updated.isAlive = false
                    }
                    updated.isScanned = true
                    return (currentIndex, updated)
                }
            }

            while inFlight < maxConcurrent && index < proxies.count {
                launchNext()
            }

            for await (idx, item) in group {
                results[idx] = item
                inFlight -= 1
                launchNext()
            }
        }
        return results
    }
}
