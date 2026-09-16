import Foundation
import Combine

/// Equivalent of Android's `ProxyViewModel.kt`.
@MainActor
final class ProxyViewModel: ObservableObject {

    let dataStoreManager: DataStoreManager
    private let repository: ProxyRepository
    private let bannerRepository: BannerRepository

    // MARK: Published state (mirrors the Kotlin StateFlows)

    @Published var uiState: UiState = .loading
    @Published var isRefreshing: Bool = false
    @Published var isOfflineNoticeVisible: Bool = false
    @Published var searchQuery: String = ""
    @Published var bannerItems: [BannerItem] = []
    @Published var isBannerDismissed: Bool = false

    /// Full, unfiltered list of currently parsed proxies (mirrors `_allProxiesList`)
    @Published private var allProxiesList: [ProxyItem] = []

    /// Reactive filtered + sorted list shown on the home screen.
    @Published private(set) var displayProxies: [ProxyItem] = []

    /// Reactive favorites list, backfilled with parsed items for links not currently in allProxiesList.
    @Published private(set) var savedProxies: [ProxyItem] = []

    private var scanTask: Task<Void, Never>?
    private var autoScanTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var savedLinks: Set<String> { dataStoreManager.favorites }
    var selectedLanguage: String? { dataStoreManager.selectedLanguage }
    var themeMode: String { dataStoreManager.themeMode }
    var autoScanEnabled: Bool { dataStoreManager.autoScanEnabled }
    var autoScanInterval: Int { dataStoreManager.autoScanInterval }
    var bannerSliderEnabled: Bool { dataStoreManager.bannerSliderEnabled }

    init(repository: ProxyRepository, dataStoreManager: DataStoreManager, bannerRepository: BannerRepository = BannerRepository()) {
        self.repository = repository
        self.dataStoreManager = dataStoreManager
        self.bannerRepository = bannerRepository

        bindDerivedState()

        Task { await preloadCachedProxiesThenFetch() }
        Task { await fetchBannerImages() }
    }

    // MARK: Derived state (equivalent of the Kotlin `combine {}` StateFlows)

    private func bindDerivedState() {
        // displayProxies: filtered + searched + sorted, recomputed whenever inputs change.
        Publishers.CombineLatest3($allProxiesList, $searchQuery, $isOfflineNoticeVisible)
            .map { proxies, query, isOfflineNotice -> [ProxyItem] in
                let hasAnyAlive = proxies.contains { $0.isAlive }
                let allScanned = !proxies.isEmpty && proxies.allSatisfy { $0.isScanned }

                let filtered: [ProxyItem]
                if isOfflineNotice {
                    filtered = proxies
                } else if allScanned && !hasAnyAlive {
                    filtered = proxies
                } else {
                    let aliveOrUnscanned = proxies.filter { !$0.isScanned || ($0.isAlive && (1...1200).contains($0.ping)) }
                    filtered = (aliveOrUnscanned.isEmpty && !proxies.isEmpty) ? proxies : aliveOrUnscanned
                }

                let searched: [ProxyItem]
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    searched = filtered
                } else {
                    searched = filtered.filter { proxy in
                        proxy.server.localizedCaseInsensitiveContains(query) || String(proxy.port).contains(query)
                    }
                }

                return searched.sorted { a, b in
                    if a.isAlive != b.isAlive { return a.isAlive && !b.isAlive }
                    if a.isAlive {
                        return a.ping < b.ping
                    }
                    return a.id < b.id
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$displayProxies)

        // savedProxies: favorites, backfilled with parsed items for missing links.
        Publishers.CombineLatest($allProxiesList, dataStoreManager.$favorites)
            .map { allList, favSet -> [ProxyItem] in
                let existingSaved = allList.filter { favSet.contains($0.link) }
                let existingLinks = Set(existingSaved.map(\.link))
                let missingLinks = favSet.subtracting(existingLinks)
                var result = existingSaved
                if !missingLinks.isEmpty {
                    let parsedMissing = ProxyParser.parse(missingLinks.joined(separator: "\n"))
                    result += parsedMissing
                }
                return result.map { item in
                    var copy = item
                    copy.isFavorite = true
                    return copy
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$savedProxies)

        // React to auto-scan setting changes.
        Publishers.CombineLatest(dataStoreManager.$autoScanEnabled, dataStoreManager.$autoScanInterval)
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] enabled, interval in
                guard let self else { return }
                if enabled {
                    self.startAutoScanProgress(intervalSeconds: interval)
                } else {
                    self.stopAutoScanProgress()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Favorites

    func toggleSave(_ link: String) {
        dataStoreManager.toggleFavorite(link)
    }

    // MARK: Banners

    func fetchBannerImages() async {
        if let cachedJson = dataStoreManager.getCachedBanners(), !cachedJson.isEmpty, bannerItems.isEmpty {
            if let parsed = decodeBanners(cachedJson), !parsed.isEmpty {
                bannerItems = parsed
            }
        }
        let items = await bannerRepository.fetchBannerItems()
        if !items.isEmpty {
            bannerItems = items
            if let json = encodeBanners(items) {
                dataStoreManager.saveCachedBanners(json)
            }
        } else if bannerItems.isEmpty, let cached = dataStoreManager.getCachedBanners(), let parsed = decodeBanners(cached) {
            bannerItems = parsed
        }
    }

    func dismissBanner() { isBannerDismissed = true }

    private func encodeBanners(_ items: [BannerItem]) -> String? {
        guard let data = try? JSONEncoder().encode(items) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeBanners(_ json: String) -> [BannerItem]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([BannerItem].self, from: data)
    }

    // MARK: Fetching + scanning proxies

    private func preloadCachedProxiesThenFetch() async {
        if let cachedRaw = dataStoreManager.getCachedProxies(), !cachedRaw.isEmpty {
            let cachedProxies = ProxyParser.parse(cachedRaw)
            if !cachedProxies.isEmpty && allProxiesList.isEmpty {
                allProxiesList = cachedProxies
                uiState = .success(cachedProxies)
            }
        }
        await fetchAndScanProxies()
    }

    func fetchAndScanProxies() {
        Task { await fetchAndScanProxies() }
    }

    @discardableResult
    private func fetchAndScanProxies() async -> Void {
        if case .loading = uiState, !allProxiesList.isEmpty {
            // keep showing current proxies while loading in background
        } else if allProxiesList.isEmpty {
            uiState = .loading
        }

        do {
            let raw = try await repository.fetchProxiesRaw()
            let downloaded = ProxyParser.parse(raw)
            if !downloaded.isEmpty {
                isOfflineNoticeVisible = false
                dataStoreManager.saveCachedProxies(raw)
                startLiveScan(downloaded)
            } else {
                await handleFetchFailure()
            }
        } catch {
            await handleFetchFailure()
        }
    }

    private func handleFetchFailure() async {
        if let cachedRaw = dataStoreManager.getCachedProxies(), !cachedRaw.isEmpty {
            let cachedProxies = ProxyParser.parse(cachedRaw)
            if !cachedProxies.isEmpty {
                isOfflineNoticeVisible = true
                startLiveScan(cachedProxies)
                return
            }
        }

        if !allProxiesList.isEmpty {
            isOfflineNoticeVisible = true
            uiState = .success(allProxiesList)
        } else {
            uiState = .error("Failed to load proxies")
        }
    }

    func refresh() {
        Task {
            isRefreshing = true
            do {
                let raw = try await repository.fetchProxiesRaw()
                let downloaded = ProxyParser.parse(raw)
                if !downloaded.isEmpty {
                    isOfflineNoticeVisible = false
                    dataStoreManager.saveCachedProxies(raw)
                    startLiveScan(downloaded)
                } else {
                    await handleFetchFailure()
                }
            } catch {
                await handleFetchFailure()
            }
            isRefreshing = false
        }
    }

    private func startLiveScan(_ proxies: [ProxyItem]) {
        scanTask?.cancel()
        let unscanned = proxies.map { proxy -> ProxyItem in
            var copy = proxy
            copy.isScanned = false
            copy.ping = -1
            copy.isAlive = false
            return copy
        }
        allProxiesList = unscanned
        uiState = .success(unscanned)

        scanTask = Task { [weak self] in
            guard let self else { return }
            let scanned = await PingService.pingAll(unscanned)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.allProxiesList = scanned
            }
        }
    }

    func onSearchQueryChanged(_ query: String) {
        searchQuery = query
    }

    func setLanguage(_ code: String) { dataStoreManager.saveSelectedLanguage(code) }
    func setThemeMode(_ mode: String) { dataStoreManager.saveThemeMode(mode) }
    func setBannerSliderEnabled(_ enabled: Bool) { dataStoreManager.saveBannerSliderEnabled(enabled) }
    func setAutoScanEnabled(_ enabled: Bool) { dataStoreManager.saveAutoScanEnabled(enabled) }
    func setAutoScanInterval(_ seconds: Int) { dataStoreManager.saveAutoScanInterval(seconds) }

    private func startAutoScanProgress(intervalSeconds: Int) {
        autoScanTask?.cancel()
        autoScanTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds) * 1_000_000_000)
                if Task.isCancelled { break }
                do {
                    let raw = try await self.repository.fetchProxiesRaw()
                    let downloaded = ProxyParser.parse(raw)
                    if !downloaded.isEmpty {
                        await MainActor.run {
                            self.isOfflineNoticeVisible = false
                            self.dataStoreManager.saveCachedProxies(raw)
                            self.startLiveScan(downloaded)
                        }
                    }
                } catch {
                    if let cachedRaw = self.dataStoreManager.getCachedProxies(), !cachedRaw.isEmpty {
                        let cachedProxies = ProxyParser.parse(cachedRaw)
                        if !cachedProxies.isEmpty {
                            await MainActor.run {
                                self.isOfflineNoticeVisible = true
                                self.startLiveScan(cachedProxies)
                            }
                        }
                    }
                }
            }
        }
    }

    private func stopAutoScanProgress() {
        autoScanTask?.cancel()
        autoScanTask = nil
    }

    deinit {
        scanTask?.cancel()
        autoScanTask?.cancel()
    }
}
