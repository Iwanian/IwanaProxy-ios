import Foundation

/// Equivalent of Android's `ProxyRepository.kt`.
final class ProxyRepository {

    private let session: URLSession
    private let primaryURL = URL(string: "https://raw.githubusercontent.com/Iwanian/Sub/main/Proxy-Channel-%2540I_w_a_n_a.txt")!
    private let fallbackURLs: [URL] = [
        URL(string: "https://c-mamad.ir/proxies/proxy.txt")!
    ]

    init(session: URLSession = .shared) {
        self.session = session
    }

    enum RepositoryError: Error {
        case allSourcesFailed(underlying: Error?)
    }

    /// Downloads the raw proxies text from the primary source, falling back to
    /// alternates if the primary fails or yields an empty parsed list.
    func fetchProxiesRaw() async throws -> String {
        let urlsToTry = [primaryURL] + fallbackURLs
        var lastError: Error?

        for url in urlsToTry {
            do {
                var request = URLRequest(url: url, timeoutInterval: 8)
                request.setValue("IwanaProxyiOSApp", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                if !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let parsed = ProxyParser.parse(bodyText)
                    if !parsed.isEmpty {
                        return bodyText
                    }
                }
            } catch {
                lastError = error
            }
        }

        throw RepositoryError.allSourcesFailed(underlying: lastError)
    }

    func fetchProxies() async throws -> [ProxyItem] {
        let raw = try await fetchProxiesRaw()
        return ProxyParser.parse(raw)
    }
}
