import Foundation

/// Equivalent of Android's `BannerRepository.kt`.
/// Fetches promotional banner images (and optional target links) from the
/// project's GitHub-hosted `pic` folder, with a probing fallback.
final class BannerRepository {

    private let session: URLSession

    private let apiEndpoints = [
        "https://api.github.com/repos/Iwanian/Sub/contents/pic",
        "https://api.github.com/repos/Iwanian/Sub/contents",
        "https://api.github.com/repos/Iwanian/Iwana-Proxy/contents/pic"
    ]

    private let rawFolderBaseUrls = [
        "https://raw.githubusercontent.com/Iwanian/Sub/main/pic",
        "https://raw.githubusercontent.com/Iwanian/Sub/main",
        "https://raw.githubusercontent.com/Iwanian/Iwana-Proxy/main/pic"
    ]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchBannerItems() async -> [BannerItem] {
        var bannerItems: [BannerItem] = []
        var txtFiles: [String: String] = [:] // baseName(lowercased) -> rawUrl
        var rawImageUrls: [(baseName: String, url: String)] = []
        var generalLinks: [String] = []

        // 1. Attempt GitHub API folder inspection
        for apiUrl in apiEndpoints {
            guard let url = URL(string: apiUrl) else { continue }
            do {
                var request = URLRequest(url: url, timeoutInterval: 6)
                request.setValue("IwanaProxyiOSApp", forHTTPHeaderField: "User-Agent")
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { continue }
                guard let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }

                for item in array {
                    let type = item["type"] as? String ?? ""
                    let name = item["name"] as? String ?? ""
                    let downloadUrl = item["download_url"] as? String ?? ""
                    guard type == "file" else { continue }

                    let baseName = (name as NSString).deletingPathExtension
                    let rawUrl = !downloadUrl.isEmpty && downloadUrl != "null" ? downloadUrl : "\(rawFolderBaseUrls.first!)/\(name)"

                    if isImageFile(name) {
                        if !rawImageUrls.contains(where: { $0.url == rawUrl }) {
                            rawImageUrls.append((baseName: baseName, url: rawUrl))
                        }
                    } else if name.lowercased().hasSuffix(".txt") {
                        txtFiles[baseName.lowercased()] = rawUrl
                    }
                }
                if !rawImageUrls.isEmpty { break }
            } catch {
                continue
            }
        }

        // General link fallback file (link.txt / links.txt / url.txt / urls.txt)
        let generalLinkUrl = txtFiles["link"] ?? txtFiles["links"] ?? txtFiles["url"] ?? txtFiles["urls"]
        if let generalLinkUrl {
            if let generalText = await fetchTextContent(generalLinkUrl) {
                generalLinks = generalText.components(separatedBy: .newlines)
                    .map(cleanUrl)
                    .filter { !$0.isEmpty }
            }
        }

        if !rawImageUrls.isEmpty {
            await withTaskGroup(of: BannerItem.self) { group in
                for (index, entry) in rawImageUrls.enumerated() {
                    group.addTask {
                        let txtUrl = txtFiles[entry.baseName.lowercased()]
                        var linkText: String? = nil
                        if let txtUrl {
                            linkText = await self.fetchTextContent(txtUrl)
                        }
                        if (linkText?.isEmpty ?? true) && !generalLinks.isEmpty {
                            linkText = index < generalLinks.count ? generalLinks[index] : generalLinks.first
                        }
                        return BannerItem(imageUrl: entry.url, targetLink: linkText.map(self.cleanUrl))
                    }
                }
                for await item in group {
                    bannerItems.append(item)
                }
            }
        } else {
            // Fallback: probe common file names across folder locations
            let commonNames = [
                "1.png", "1.jpg", "1.jpeg", "1.webp",
                "2.png", "2.jpg", "2.jpeg", "2.webp",
                "3.png", "3.jpg", "3.jpeg", "3.webp",
                "banner.png", "banner.jpg", "banner.jpeg", "banner.webp",
                "banner1.png", "banner1.jpg", "banner2.png", "banner2.jpg",
                "pic.png", "pic.jpg", "pic1.png", "pic1.jpg"
            ]

            for baseUrl in rawFolderBaseUrls {
                if let fallbackGeneralLink = await fetchTextContent("\(baseUrl)/link.txt") ?? (await fetchTextContent("\(baseUrl)/links.txt")) {
                    generalLinks = fallbackGeneralLink.components(separatedBy: .newlines)
                        .map(cleanUrl)
                        .filter { !$0.isEmpty }
                }

                var found: [BannerItem] = []
                await withTaskGroup(of: BannerItem?.self) { group in
                    for (index, name) in commonNames.enumerated() {
                        group.addTask {
                            let imgUrl = "\(baseUrl)/\(name)"
                            guard await self.checkUrlExists(imgUrl) else { return nil }
                            let baseName = (name as NSString).deletingPathExtension
                            var linkText = await self.fetchTextContent("\(baseUrl)/\(baseName).txt")
                            if (linkText?.isEmpty ?? true) && !generalLinks.isEmpty {
                                linkText = index < generalLinks.count ? generalLinks[index] : generalLinks.first
                            }
                            return BannerItem(imageUrl: imgUrl, targetLink: linkText.map(self.cleanUrl))
                        }
                    }
                    for await item in group {
                        if let item { found.append(item) }
                    }
                }

                if !found.isEmpty {
                    bannerItems.append(contentsOf: found)
                    break
                }
            }
        }

        return bannerItems
    }

    private func checkUrlExists(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "HEAD"
        request.setValue("IwanaProxyiOSApp", forHTTPHeaderField: "User-Agent")
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...299).contains(http.statusCode)
            }
            return false
        } catch {
            return false
        }
    }

    private func fetchTextContent(_ urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("IwanaProxyiOSApp", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            guard let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !body.isEmpty else { return nil }
            let cleanBody = body.replacingOccurrences(of: "\u{FEFF}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = cleanBody.components(separatedBy: .newlines).map(cleanUrl).filter { !$0.isEmpty }
            let preferred = lines.first { line in
                let lower = line.lowercased()
                return lower.hasPrefix("http://") || lower.hasPrefix("https://") ||
                       lower.hasPrefix("tg://") || lower.hasPrefix("t.me/") || line.hasPrefix("@")
            }
            return preferred ?? lines.first
        } catch {
            return nil
        }
    }

    private func cleanUrl(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "\u{FEFF}", with: "")
        if s.hasPrefix("\"") { s.removeFirst() }
        if s.hasSuffix("\"") { s.removeLast() }
        if s.hasPrefix("'") { s.removeFirst() }
        if s.hasSuffix("'") { s.removeLast() }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isImageFile(_ fileName: String) -> Bool {
        let lower = fileName.lowercased()
        return lower.hasSuffix(".png") || lower.hasSuffix(".jpg") ||
               lower.hasSuffix(".jpeg") || lower.hasSuffix(".webp") || lower.hasSuffix(".gif")
    }
}
