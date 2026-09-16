import SwiftUI

/// Equivalent of Android's `SavedProxiesScreen.kt`.
struct SavedProxiesView: View {
    @ObservedObject var viewModel: ProxyViewModel
    private var lang: String? { viewModel.selectedLanguage }

    var body: some View {
        Group {
            if viewModel.savedProxies.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 56))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(L.t("no_saved_proxies", lang: lang))
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.savedProxies) { proxy in
                            ProxyCardView(
                                proxy: proxy,
                                lang: lang,
                                isSaved: viewModel.savedLinks.contains(proxy.link),
                                onToggleSave: { viewModel.toggleSave(proxy.link) }
                            )
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(Theme.background.ignoresSafeArea())
            }
        }
        .navigationTitle(L.t("saved_proxies", lang: lang))
        .navigationBarTitleDisplayMode(.large)
    }
}
