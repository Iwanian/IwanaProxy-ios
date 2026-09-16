import SwiftUI

@main
struct IwanaProxyApp: App {
    @StateObject private var dataStoreManager = DataStoreManager()
    @StateObject private var viewModel: ProxyViewModel

    init() {
        let store = DataStoreManager()
        _dataStoreManager = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: ProxyViewModel(
            repository: ProxyRepository(),
            dataStoreManager: store,
            bannerRepository: BannerRepository()
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .environment(\.layoutDirection, L.isRTL(viewModel.selectedLanguage) ? .rightToLeft : .leftToRight)
                .preferredColorScheme(colorScheme(for: viewModel.themeMode))
                .tint(Theme.primary)
        }
    }

    private func colorScheme(for mode: String) -> ColorScheme? {
        switch mode {
        case "light": return .light
        case "dark": return .dark
        default: return nil // follow system
        }
    }
}
