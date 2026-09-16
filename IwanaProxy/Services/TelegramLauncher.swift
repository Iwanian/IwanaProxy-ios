import Foundation
import UIKit

/// Equivalent of Android's `TelegramLauncher.kt`.
/// On iOS there is no package-targeted intent system, so we simply open the
/// `tg://` URL scheme; iOS routes it to whichever Telegram app is installed
/// (official app, Telegram X, etc. all register the same `tg://` scheme).
enum TelegramLauncher {

    /// Converts a t.me/telegram.me proxy link into a tg:// deep link and opens it.
    static func launchProxy(_ link: String, onNotInstalled: (() -> Void)? = nil) {
        var tgLink = link
        if link.hasPrefix("https://t.me/proxy") {
            tgLink = link.replacingOccurrences(of: "https://t.me/proxy", with: "tg://proxy")
        } else if link.hasPrefix("https://telegram.me/proxy") {
            tgLink = link.replacingOccurrences(of: "https://telegram.me/proxy", with: "tg://proxy")
        }
        openTelegramURI(tgLink, onNotInstalled: onNotInstalled)
    }

    /// Opens the @I_w_a_n_a channel via tg://resolve?domain=I_w_a_n_a
    static func launchChannel(onNotInstalled: (() -> Void)? = nil) {
        openTelegramURI("tg://resolve?domain=I_w_a_n_a", onNotInstalled: onNotInstalled)
    }

    private static func openTelegramURI(_ uriString: String, onNotInstalled: (() -> Void)?) {
        guard let url = URL(string: uriString) else {
            onNotInstalled?()
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    onNotInstalled?()
                }
            }
        }
    }
}
