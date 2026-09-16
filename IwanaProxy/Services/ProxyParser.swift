import Foundation

/// Equivalent of Android's `ProxyParser.kt`
/// Parses raw text (a subscription/channel dump) for `tg://proxy?...` or
/// `https://t.me/proxy?...` links and turns them into `ProxyItem`s.
enum ProxyParser {

    private static let proxyRegex: NSRegularExpression = {
        // (tg://proxy?[^\s"']+|https?://(t\.me|telegram\.me)/proxy\?[^\s"']+)
        let pattern = #"(tg://proxy\?[^\s"']+|https?://(t\.me|telegram\.me)/proxy\?[^\s"']+)"#
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    static func parse(_ rawText: String) -> [ProxyItem] {
        var proxies: [ProxyItem] = []
        var idCounter = 1

        let lines = rawText.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }

            guard let match = firstMatch(in: trimmedLine) else { continue }
            var rawLink = match.trimmingCharacters(in: .whitespaces)

            let nsLine = trimmedLine as NSString
            guard let range = nsLine.range(of: rawLink) as NSRange?, range.location != NSNotFound else { continue }
            let matchEnd = range.location + range.length
            let matchStart = range.location

            let afterLink = matchEnd < nsLine.length
                ? nsLine.substring(from: matchEnd).trimmingCharacters(in: .whitespaces)
                : ""
            let beforeLink = matchStart > 0
                ? nsLine.substring(to: matchStart).trimmingCharacters(in: .whitespaces)
                : ""

            if rawLink.hasSuffix(".") && !rawLink.hasSuffix(".txt") {
                rawLink = String(rawLink.dropLast())
            }

            let starMarkers = ["⭐", "★", "\u{2B50}", "\u{2605}", "✨"]
            let isForDownload = starMarkers.contains { trimmedLine.contains($0) }
                || starMarkers.contains { afterLink.contains($0) }
                || ["⭐", "★"].contains { beforeLink.contains($0) }

            let isRussian = containsRussianMarker(afterLink)
                || containsRussianMarker(beforeLink)
                || rawLink.range(of: "#ru", options: .caseInsensitive) != nil
                || rawLink.range(of: "#rus", options: .caseInsensitive) != nil
                || rawLink.range(of: "#russia", options: .caseInsensitive) != nil
                || rawLink.range(of: "&tag=ru", options: .caseInsensitive) != nil
                || afterLink.lowercased().hasPrefix("ru")
                || afterLink.lowercased().hasSuffix("ru")
                || trimmedLine.contains("🇷🇺")
                || trimmedLine.contains("روسی")

            if let item = buildItem(rawLink: rawLink, idCounter: &idCounter, isForDownload: isForDownload, isRussian: isRussian) {
                proxies.append(item)
            }
        }

        // Fallback for single-line unseparated strings
        if proxies.isEmpty {
            for match in allMatches(in: rawText) {
                var rawLink = match.trimmingCharacters(in: .whitespaces)
                if rawLink.hasSuffix(".") && !rawLink.hasSuffix(".txt") {
                    rawLink = String(rawLink.dropLast())
                }
                let isForDownload = rawLink.contains("⭐") || rawLink.contains("★")
                let isRussian = rawLink.range(of: "#ru", options: .caseInsensitive) != nil
                if let item = buildItem(rawLink: rawLink, idCounter: &idCounter, isForDownload: isForDownload, isRussian: isRussian) {
                    proxies.append(item)
                }
            }
        }

        // De-duplicate by server:port, preserving first occurrence
        var seen = Set<String>()
        var result: [ProxyItem] = []
        for item in proxies {
            let key = "\(item.server):\(item.port)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(item)
            }
        }
        return result
    }

    private static func containsRussianMarker(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let pattern = #"\b(ru|rus|russia|russian)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    private static func buildItem(rawLink: String, idCounter: inout Int, isForDownload: Bool, isRussian: Bool) -> ProxyItem? {
        guard let components = URLComponents(string: rawLink) else { return nil }
        let queryItems = components.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value
        }
        guard let server = value("server"), !server.isEmpty,
              let portStr = value("port"), !portStr.isEmpty,
              let port = Int(portStr) else { return nil }
        let secret = value("secret") ?? ""

        let item = ProxyItem(
            id: idCounter,
            server: server,
            port: port,
            secret: secret,
            link: rawLink,
            ping: -1,
            isAlive: false,
            isFavorite: false,
            isScanned: false,
            isForDownload: isForDownload,
            isRussian: isRussian
        )
        idCounter += 1
        return item
    }

    private static func firstMatch(in text: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = proxyRegex.firstMatch(in: text, options: [], range: range) else { return nil }
        return nsText.substring(with: match.range)
    }

    private static func allMatches(in text: String) -> [String] {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = proxyRegex.matches(in: text, options: [], range: range)
        return matches.map { nsText.substring(with: $0.range) }
    }
}
