import SwiftUI

/// Equivalent of Android's `SupportScreen.kt`, redesigned to match the
/// screenshot: a pink heart title, an info banner, bordered crypto-address
/// cards with a copy icon, a red warning box, and outlined link rows for
/// GitHub / Telegram.
struct SupportView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @State private var toastText: String? = nil

    private var lang: String { viewModel.selectedLanguage ?? "fa" }
    private var isFa: Bool { lang == "fa" }
    private var isRu: Bool { lang == "ru" }

    private var titleText: String {
        if isFa { return "حمایت از ما" }
        if isRu { return "Поддержать нас" }
        return "Support Us"
    }
    private var bannerText: String {
        if isFa { return "تمام امکانات Iwana Proxy رایگان بوده، رایگان هست و رایگان خواهد ماند." }
        if isRu { return "Все функции Iwana Proxy были, есть и всегда будут бесплатными." }
        return "All features of Iwana Proxy are free, always have been, and always will be."
    }
    private var cryptoHeader: String {
        if isFa { return "💰 حمایت با ارز دیجیتال" }
        if isRu { return "💰 Поддержка криптовалютой" }
        return "💰 Support with Cryptocurrency"
    }
    private var trxLabel: String {
        if isFa { return "TRX (TRON) (پیشنهادی)" }
        if isRu { return "TRX (TRON) (Рекомендуемый)" }
        return "TRX (TRON) (Recommended)"
    }
    private var networkWarning: String {
        if isFa { return "⚠️ لطفاً هنگام انتقال، شبکه را دقیقاً مطابق موارد بالا انتخاب کنید." }
        if isRu { return "⚠️ Пожалуйста, выбирайте сеть точно в соответствии с указанной выше при переводе." }
        return "⚠️ Please ensure you select the exact network specified above when transferring."
    }
    private var starHeader: String {
        if isFa { return "⭐ حمایت از پروژه" }
        if isRu { return "⭐ Поддержка проекта" }
        return "⭐ Support the Project"
    }
    private var starSubtext: String {
        if isFa { return "با دادن یک Star در GitHub به رشد پروژه کمک کنید:" }
        if isRu { return "Помогите проекту расти, поставив Star на GitHub:" }
        return "Help the project grow by giving a Star on GitHub:"
    }
    private var telegramSubtext: String {
        if isFa { return "ما را در تلگرام دنبال کنید:" }
        if isRu { return "Подписывайтесь на нас в Telegram:" }
        return "Follow us on Telegram:"
    }
    private var thankYouText: String {
        if isFa { return "ممنون که از Iwana Proxy حمایت میکنید." }
        if isRu { return "Спасибо за поддержку Iwana Proxy!" }
        return "Thank you for supporting Iwana Proxy!"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 16) {
                Text(bannerText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(16)
                    .background(Theme.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(cryptoHeader).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.onSurface)

                cryptoCard(currency: "USDT (Polygon)", address: "0x3d76c651ee3f76ac468e2769c9d9fbfcaa545088")
                cryptoCard(currency: "BTC (Ethereum)", address: "0x3d76c651ee3f76ac468e2769c9d9fbfcaa545088")
                cryptoCard(currency: trxLabel, address: "TFaCWNT4N9wHJ2e1Z9MSuz1waUoMseRGqx")

                Text(networkWarning)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.danger)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(14)
                    .background(Theme.dangerContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(starHeader).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.onSurface).padding(.top, 6)
                Text(starSubtext).font(.subheadline).foregroundColor(.secondary)

                linkRow(icon: "chevron.left.slash.chevron.right", label: "GitHub") {
                    if let url = URL(string: "https://github.com/Iwanian/Iwana-Proxy") {
                        UIApplication.shared.open(url)
                    }
                }

                Text(telegramSubtext).font(.subheadline).foregroundColor(.secondary)

                linkRow(icon: "paperplane.fill", label: "Telegram") {
                    TelegramLauncher.launchChannel()
                }

                HStack(spacing: 6) {
                    Text(thankYouText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.primary)
                    Image(systemName: "heart.fill").foregroundColor(Theme.pink)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            if let toastText {
                Text(toastText)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.black.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
    }

    private func cryptoCard(currency: String, address: String) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(currency)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            HStack {
                Button {
                    UIPasteboard.general.string = address
                    let label = currency.components(separatedBy: " ").first ?? currency
                    let format: String = isFa ? "آدرس %@ کپی شد" : (isRu ? "Адрес %@ скопирован" : "%@ address copied")
                    withAnimation { toastText = String(format: format, label) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { toastText = nil } }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Theme.primary)
                        .frame(width: 32, height: 32)
                        .background(Theme.primaryContainer)
                        .clipShape(Circle())
                }
                Spacer()
                Text(address)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(Theme.onSurface)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))
    }

    private func linkRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
                Spacer()
                Text(label).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.onSurface)
                Image(systemName: icon).foregroundColor(Theme.primary)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }
}
