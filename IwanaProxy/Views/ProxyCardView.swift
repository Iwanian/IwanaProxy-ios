import SwiftUI

/// Equivalent of Android's `ProxyCard.kt`, redesigned to match the
/// Android app's card visuals: latency on the leading side, pill badges
/// next to the proxy title, icon-only save/copy buttons, and a filled
/// "اتصال" button with a leading chevron.
struct ProxyCardView: View {
    let proxy: ProxyItem
    let lang: String?
    var isSaved: Bool = false
    var onToggleSave: (() -> Void)? = nil

    @State private var copiedToast = false

    private var latencyColor: Color {
        switch proxy.ping {
        case 0...150: return Theme.success
        case 151...300: return Theme.warning
        default: return Theme.danger
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Latency column
            VStack(alignment: .leading, spacing: 2) {
                if !proxy.isScanned {
                    Text("…")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.secondary.opacity(0.4))
                } else if proxy.isAlive && proxy.ping > 0 {
                    Text("ms \(proxy.ping)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(latencyColor)
                } else {
                    Text("--")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                Text("LATENCY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .frame(minWidth: 64, alignment: .leading)

            VStack(alignment: .trailing, spacing: 10) {
                // Title row: badges then proxy name (RTL reading order)
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    if proxy.isRussian {
                        PillBadge(text: L.t("russian_badge", lang: lang), foreground: Theme.warning, background: Theme.warningContainer)
                    }
                    if proxy.isForDownload {
                        PillBadge(text: L.t("for_download_badge", lang: lang), foreground: Theme.success, background: Theme.successContainer)
                    }
                    statusBadge
                    Text("Proxy \(proxy.id)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.onSurface)
                        .lineLimit(1)
                }

                Text("\(proxy.server):\(proxy.port)")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Divider()

                HStack {
                    Button {
                        UIPasteboard.general.string = proxy.link
                        copiedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copiedToast = false }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Theme.background)
                            .clipShape(Circle())
                    }

                    if let onToggleSave {
                        Button(action: onToggleSave) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 15))
                                .foregroundColor(isSaved ? Theme.primary : .secondary)
                                .frame(width: 34, height: 34)
                                .background(Theme.background)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    Button {
                        TelegramLauncher.launchProxy(proxy.link)
                    } label: {
                        HStack(spacing: 6) {
                            Text(L.t("connect", lang: lang)).font(.system(size: 14, weight: .bold))
                            Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.tertiary.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .overlay(alignment: .top) {
            if copiedToast {
                Text(L.t("copied", lang: lang))
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.black.opacity(0.78))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .offset(y: -14)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: copiedToast)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if !proxy.isScanned {
            PillBadge(text: L.t("scanning_status", lang: lang), foreground: Theme.warning, background: Theme.warningContainer)
        } else if proxy.isAlive && proxy.ping > 0 {
            PillBadge(text: L.t("online_status", lang: lang), foreground: Theme.success, background: Theme.successContainer)
        } else {
            PillBadge(text: L.t("offline_failed_status", lang: lang), foreground: Theme.danger, background: Theme.dangerContainer)
        }
    }
}
