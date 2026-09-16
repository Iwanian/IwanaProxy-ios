import SwiftUI

/// Equivalent of Android's `ProxyScreen.kt` (home screen), redesigned to
/// match the Android layout: gear icon top-leading, title + live-count
/// pill top-trailing, banner slideshow, disclaimer bar, proxy list, and a
/// sticky bottom "اسکن پروکسی‌ها" button.
struct ProxyListView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @State private var pulse = false

    private var lang: String? { viewModel.selectedLanguage }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        if viewModel.isOfflineNoticeVisible {
                            Text(L.t("offline_notice", lang: lang))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.danger)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(14)
                                .background(Theme.dangerContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                        }

                        if viewModel.bannerSliderEnabled && !viewModel.bannerItems.isEmpty {
                            AdBannerSlideshowView(banners: viewModel.bannerItems)
                        }

                        Text(L.t("disclaimer", lang: lang))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.onSurface)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(14)
                            .background(Theme.primaryContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        content
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .overlay(alignment: .bottom) { footer }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        HStack {
            NavigationLink {
                SettingsView(viewModel: viewModel)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19))
                    .foregroundColor(Theme.primary)
                    .frame(width: 44, height: 44)
                    .background(Theme.primaryContainer)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Iwana Proxy")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(Theme.primary)
                HStack(spacing: 6) {
                    Text(String(format: L.t("system_ready_with_count", lang: lang), viewModel.displayProxies.filter { $0.isAlive }.count))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 8, height: 8)
                        .opacity(pulse ? 1.0 : 0.35)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .onAppear { pulse = true }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.uiState {
        case .loading:
            ProgressView().tint(Theme.primary).padding(.top, 60)
        case .error(let message):
            VStack(spacing: 16) {
                Text("🔴 \(message)")
                    .foregroundColor(Theme.danger)
                    .multilineTextAlignment(.center)
                Button(L.t("retry", lang: lang)) { viewModel.fetchAndScanProxies() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primary)
            }
            .padding(32)
        case .success:
            if viewModel.displayProxies.isEmpty {
                VStack(spacing: 12) {
                    Text("🔍").font(.system(size: 52))
                    Text(L.t("no_proxies_found", lang: lang))
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.displayProxies) { proxy in
                        ProxyCardView(
                            proxy: proxy,
                            lang: lang,
                            isSaved: viewModel.savedLinks.contains(proxy.link),
                            onToggleSave: { viewModel.toggleSave(proxy.link) }
                        )
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    private var footer: some View {
        Button {
            viewModel.fetchAndScanProxies()
        } label: {
            HStack(spacing: 8) {
                Text(L.t("scan_proxies_caps", lang: lang)).fontWeight(.bold)
                Image(systemName: "bolt.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Theme.background
                .clipShape(RoundedRectangleCorner(radius: 30, corners: [.topLeft, .topRight]))
                .shadow(color: .black.opacity(0.08), radius: 10, y: -3)
        )
    }
}

/// Helper for rounding only specific corners (top bar / footer style).
struct RoundedRectangleCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
