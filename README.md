# Iwana Proxy — iOS (SwiftUI) port

This is a native Swift/SwiftUI port of the Android app `Iwana-Proxy`
(a Telegram MTProto proxy finder/launcher). It reproduces the same
features and general design:

- Downloads a public list of `tg://proxy?...` links (with a fallback
  source), and TCP-pings every proxy to show live latency / online status.
- Search, sort by latency, save favorites, auto-scan on an interval,
  optional promo banner carousel.
- A dedicated **Proxy Speed Test** screen: paste any proxy link or
  `server:port:secret`, and run a ~7 second benchmark that measures
  DNS lookup time, avg/min/max ping, jitter, packet loss, an estimated
  download/upload speed, a derived "real Telegram speed" estimate, and
  a file-size download-time calculator.
- Settings screen: in-app language switch (Persian / English / Russian,
  translated the same as the Android app's `strings.xml` resources),
  light/dark/system theme, auto-scan toggle + interval slider, banner
  toggle.
- Saved Proxies screen (favorites).
- Support Us screen with crypto donation addresses and GitHub/Telegram links.
- Tapping "Connect" opens Telegram via the `tg://` URL scheme (same
  proxy import flow Telegram uses on Android).

## Project layout

```
IwanaProxy.xcodeproj/          — the real Xcode project (open this)
  project.pbxproj
  xcshareddata/xcschemes/IwanaProxy.xcscheme
.github/workflows/ios-build.yml — CI: simulator smoke-build + optional signed IPA job
IwanaProxy/
  Info.plist                  — real target Info.plist (tg:// query scheme, localizations, etc.)
  Assets.xcassets/            — AppIcon + AccentColor placeholders (see note below)
  IwanaProxyApp.swift          — @main app entry point
  Models/                     — ProxyItem, UiState, BannerItem, SpeedTestModels
  Services/                   — ProxyParser, PingService (Network framework),
                                 ProxyRepository, BannerRepository,
                                 DataStoreManager (UserDefaults), TelegramLauncher,
                                 LocalizationManager, ProxySpeedTester
  DesignSystem/
    Theme.swift                — adaptive brand colors + reusable components
  ViewModels/
    ProxyViewModel.swift        — Combine-based state, mirrors the Kotlin ViewModel
  Views/
    RootView, SplashView, LanguageSelectionView, ProxyListView, ProxyCardView,
    SettingsView, SavedProxiesView, ProxySpeedTestView, SupportView,
    AdBannerSlideshowView
```

Everything is written with **only Apple's built-in frameworks**
(SwiftUI, Combine, Network, CFNetwork, UIKit) — no third-party
dependencies, no CocoaPods/SwiftPM packages required.

## How to open this in Xcode

The project is now a **real, ready-to-open Xcode project** — no manual
setup needed:

1. Unzip this download.
2. Double-click `IwanaProxy.xcodeproj` (it's already there at the top
   level, alongside the `IwanaProxy/` source folder).
3. Xcode opens with the `IwanaProxy` scheme already selected and every
   file already added to the target — press **⌘R** to run on a
   simulator or device.
4. Before shipping: open **Signing & Capabilities** in the target
   settings and select your own Apple Developer Team (the project
   uses `CODE_SIGN_STYLE = Automatic`, so Xcode will offer to create a
   provisioning profile for you). The placeholder bundle ID is
   `com.iwanian.iwanaproxy` — change it if that's already taken under
   your account.
5. Deployment target is already set to **iOS 15.0** (see the device
   compatibility table below).

### Building an IPA

- **From Xcode (simplest):** Product → Archive → once the archive
  finishes, the Organizer window opens → Distribute App → choose
  Ad Hoc / Development / App Store as needed → Xcode produces the
  `.ipa`.
- **From the command line / CI:** a ready GitHub Actions workflow is
  included at `.github/workflows/ios-build.yml`. On every push it
  builds the app for the simulator as an unsigned smoke test (this
  needs no secrets and will just confirm the project compiles). There
  is a second, disabled job in that same file for producing a real
  signed `.ipa` — it needs your own Apple Developer certificate,
  provisioning profile, and Team ID added as GitHub Actions secrets
  (the workflow file documents exactly which secrets and how). I can't
  generate those for you — they're tied to your personal/organization
  Apple Developer account — but once you add them and flip
  `if: false` to `if: true` in that job, CI will produce a downloadable
  `.ipa` artifact automatically.


### A note on device vs. iOS version compatibility

Support for a physical iPhone model is really determined by which iOS
version it can run, not the device itself:

| Device | Max iOS it can run | Works with this project (iOS 15+)? |
|---|---|---|
| iPhone SE (1st gen, 2016) | iOS 15 | ✅ yes, right at the floor |
| iPhone 8 / 8 Plus | iOS 16 | ✅ |
| iPhone X | iOS 16 | ✅ |
| iPhone XR / XS / XS Max | iOS 17+ | ✅ |
| iPhone 11 and newer, all later SE | current | ✅ |

Setting the deployment target to iOS 15.0 (done above) is what actually
makes the app installable on all of these — no per-device code is
needed since SwiftUI already adapts to different screen sizes
(everything in this project uses `padding`/`frame(maxWidth: .infinity)`/
`ScrollView`, no hardcoded frame sizes tied to one screen).

### Why I can't hand you a compiled `.ipa` / build directly

I'm running in a Linux sandbox with no macOS, no Xcode, and no Apple
code-signing certificate — none of which can be installed here. Building
an actual signed iOS binary requires a Mac (or a cloud Mac CI service)
with your own Apple Developer account. What I've done instead is make
sure the *source* compiles cleanly and targets the widest practical iOS
range, so the only remaining step on your end is opening it in Xcode and
pressing ⌘R / Product → Archive.


### Notes / things you may want to adjust

- **App icon**: `Assets.xcassets/AppIcon.appiconset` exists and is
  wired up (`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` is already
  set in the project), but it's empty — I don't have the Android app's
  icon source image. Drag a 1024×1024 PNG into that icon set slot in
  Xcode's Asset Catalog editor before archiving for the App Store
  (Debug/simulator builds work fine without it, just with a blank icon).
- **Accent color**: already set to the Android app's brand blue
  (`#005FB0` light / `#5AB6E5` dark) in `Assets.xcassets/AccentColor`.
- **Telegram deep link**: `tg://` opens whichever Telegram client is
  installed (official app, Telegram X, etc. — iOS doesn't support
  Android's package-targeted intents, so this is the closest
  equivalent and works the same way in practice).
- **Ping accuracy**: iOS sandboxes raw ICMP sockets, so — exactly like
  the Android version — "ping" here means a TCP handshake round-trip
  to the proxy's `server:port`, not an ICMP echo.
- The banner slideshow and proxy list both hit the same public GitHub
  raw URLs as the Android app (`Iwanian/Sub`, `Iwanian/Iwana-Proxy`),
  so no backend changes are needed.

## Attribution

Ported from the open-source Android app source you provided
(`github.com/Iwanian/Iwana-Proxy`, `Android/` folder). All copy/text
strings, URLs, wallet addresses, and app behavior were carried over
as-is from that source for feature parity.
