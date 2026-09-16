import SwiftUI

/// Equivalent of Android's `AdBannerSlideshow.kt`.
/// Auto-advancing carousel of promotional banner images, tapping opens `targetLink`.
struct AdBannerSlideshowView: View {
    let banners: [BannerItem]

    @State private var currentIndex = 0
    @State private var timer: Timer? = nil

    var body: some View {
        if banners.isEmpty {
            EmptyView()
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    bannerImage(banner)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexPrefix: .never))
            .indexViewStyle(.page(backgroundDisplayMode: banners.count > 1 ? .always : .never))
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .onAppear { startAutoAdvance() }
            .onDisappear { timer?.invalidate() }
        }
    }

    @ViewBuilder
    private func bannerImage(_ banner: BannerItem) -> some View {
        Button {
            openTarget(banner.targetLink)
        } label: {
            AsyncImage(url: URL(string: banner.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Color(.secondarySystemBackground)
                case .empty:
                    Color(.secondarySystemBackground)
                        .overlay(ProgressView())
                @unknown default:
                    Color(.secondarySystemBackground)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func startAutoAdvance() {
        guard banners.count > 1 else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % banners.count
            }
        }
    }

    private func openTarget(_ link: String?) {
        guard let link, !link.isEmpty else { return }
        if link.hasPrefix("tg://") || link.hasPrefix("t.me/") || link.hasPrefix("@") {
            let resolved = link.hasPrefix("@") ? "tg://resolve?domain=\(link.dropFirst())" : link
            TelegramLauncher.launchProxy(resolved)
        } else if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
