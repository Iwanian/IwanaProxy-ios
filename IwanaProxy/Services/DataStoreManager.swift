import Foundation
import Combine

/// Equivalent of Android's `DataStoreManager.kt`.
/// Uses `UserDefaults` (the iOS analogue of Android's DataStore/Preferences)
/// and exposes Combine publishers mirroring the Kotlin `Flow`s.
final class DataStoreManager: ObservableObject {

    private enum Keys {
        static let selectedLanguage = "selected_language"
        static let favorites = "favorites"
        static let themeMode = "theme_mode"
        static let autoScanEnabled = "auto_scan_enabled"
        static let autoScanInterval = "auto_scan_interval"
        static let bannerSliderEnabled = "banner_slider_enabled"
        static let cachedProxies = "cached_proxies"
        static let cachedBanners = "cached_banners"
    }

    private let defaults: UserDefaults

    @Published var selectedLanguage: String?
    @Published var themeMode: String
    @Published var favorites: Set<String>
    @Published var autoScanEnabled: Bool
    @Published var autoScanInterval: Int
    @Published var bannerSliderEnabled: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedLanguage = defaults.string(forKey: Keys.selectedLanguage)
        self.themeMode = defaults.string(forKey: Keys.themeMode) ?? "system"
        self.favorites = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        self.autoScanEnabled = defaults.bool(forKey: Keys.autoScanEnabled)
        self.autoScanInterval = defaults.object(forKey: Keys.autoScanInterval) as? Int ?? 15
        self.bannerSliderEnabled = defaults.object(forKey: Keys.bannerSliderEnabled) as? Bool ?? true
    }

    func saveSelectedLanguage(_ code: String) {
        selectedLanguage = code
        defaults.set(code, forKey: Keys.selectedLanguage)
    }

    func saveThemeMode(_ mode: String) {
        themeMode = mode
        defaults.set(mode, forKey: Keys.themeMode)
    }

    func toggleFavorite(_ link: String) {
        if favorites.contains(link) {
            favorites.remove(link)
        } else {
            favorites.insert(link)
        }
        defaults.set(Array(favorites), forKey: Keys.favorites)
    }

    func saveAutoScanEnabled(_ enabled: Bool) {
        autoScanEnabled = enabled
        defaults.set(enabled, forKey: Keys.autoScanEnabled)
    }

    func saveAutoScanInterval(_ seconds: Int) {
        autoScanInterval = seconds
        defaults.set(seconds, forKey: Keys.autoScanInterval)
    }

    func saveBannerSliderEnabled(_ enabled: Bool) {
        bannerSliderEnabled = enabled
        defaults.set(enabled, forKey: Keys.bannerSliderEnabled)
    }

    func saveCachedProxies(_ raw: String) {
        defaults.set(raw, forKey: Keys.cachedProxies)
    }

    func getCachedProxies() -> String? {
        defaults.string(forKey: Keys.cachedProxies)
    }

    func saveCachedBanners(_ json: String) {
        defaults.set(json, forKey: Keys.cachedBanners)
    }

    func getCachedBanners() -> String? {
        defaults.string(forKey: Keys.cachedBanners)
    }
}
