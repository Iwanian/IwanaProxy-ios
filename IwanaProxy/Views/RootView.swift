import SwiftUI

/// Equivalent of the Compose `NavHost` in `MainActivity.kt`:
/// splash -> (language_selection | home)
struct RootView: View {
    @ObservedObject var viewModel: ProxyViewModel

    enum Route { case splash, languageSelection, home }
    @State private var route: Route = .splash

    var body: some View {
        Group {
            switch route {
            case .splash:
                SplashView()
                    .task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        if viewModel.selectedLanguage == nil || viewModel.selectedLanguage!.isEmpty {
                            route = .languageSelection
                        } else {
                            route = .home
                        }
                    }
            case .languageSelection:
                LanguageSelectionView(viewModel: viewModel) {
                    route = .home
                }
            case .home:
                ProxyListView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: route)
    }
}
