import SwiftUI

/// Equivalent of Android's `SettingsScreen.kt`, redesigned with the same
/// visual language as the screenshots: tinted navigation rows, a 3-way
/// appearance segmented control, and bordered language selection cards.
struct SettingsView: View {
    @ObservedObject var viewModel: ProxyViewModel
    private var lang: String? { viewModel.selectedLanguage }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 22) {
                VStack(spacing: 12) {
                    NavigationLink {
                        SavedProxiesView(viewModel: viewModel)
                    } label: {
                        TintedNavRow(title: L.t("saved_proxies", lang: lang), systemIcon: "bookmark.fill", tint: Theme.primary, container: Theme.primaryContainer)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ProxySpeedTestView(viewModel: viewModel)
                    } label: {
                        TintedNavRow(title: L.t("proxy_speed_test", lang: lang), systemIcon: "checkmark.seal.fill", tint: Theme.teal, container: Theme.tealContainer)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SupportView(viewModel: viewModel)
                    } label: {
                        TintedNavRow(title: supportTitle, systemIcon: "heart.fill", tint: Theme.pink, container: Theme.pinkContainer)
                    }
                    .buttonStyle(.plain)
                }

                sectionHeading(appearanceTitle)

                HStack(spacing: 10) {
                    appearanceOption(mode: "dark", icon: "moon.fill", label: darkLabel)
                    appearanceOption(mode: "light", icon: "sun.max.fill", label: lightLabel)
                    appearanceOption(mode: "system", icon: "circle.lefthalf.filled", label: systemLabel)
                }

                Toggle(isOn: Binding(
                    get: { viewModel.bannerSliderEnabled },
                    set: { viewModel.setBannerSliderEnabled($0) }
                )) {
                    Text(L.t("banner_slider_setting", lang: lang))
                        .font(.system(size: 15, weight: .medium))
                }
                .tint(Theme.primary)
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))

                sectionHeading(L.t("language", lang: lang))

                VStack(spacing: 10) {
                    ForEach(L.supportedLanguages) { option in
                        Button {
                            viewModel.setLanguage(option.code)
                        } label: {
                            languageRow(option)
                        }
                        .buttonStyle(.plain)
                    }
                }

                sectionHeading(L.t("auto_scan_settings_title", lang: lang))

                VStack(alignment: .trailing, spacing: 14) {
                    Toggle(isOn: Binding(
                        get: { viewModel.autoScanEnabled },
                        set: { viewModel.setAutoScanEnabled($0) }
                    )) {
                        Text(L.t("auto_scan_enable_toggle", lang: lang))
                            .font(.system(size: 15, weight: .medium))
                    }
                    .tint(Theme.primary)

                    if viewModel.autoScanEnabled {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(String(format: L.t("auto_scan_interval_text", lang: lang), viewModel.autoScanInterval))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.autoScanInterval) },
                                    set: { viewModel.setAutoScanInterval(Int($0)) }
                                ),
                                in: 5...240
                            )
                            .tint(Theme.primary)
                        }
                    }
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L.t("settings", lang: lang))
        .navigationBarTitleDisplayMode(.large)
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func appearanceOption(mode: String, icon: String, label: String) -> some View {
        let isSelected = viewModel.themeMode == mode
        return Button {
            viewModel.setThemeMode(mode)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.primary : .secondary)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.primary : Theme.tertiary.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func languageRow(_ option: L.LangOption) -> some View {
        let isSelected = viewModel.selectedLanguage == option.code
        return HStack {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? Theme.primary : .secondary.opacity(0.5))
            Spacer()
            Text(option.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.onSurface)
            Text(option.emoji)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Theme.primary : Theme.tertiary.opacity(0.5), lineWidth: isSelected ? 2 : 1)
        )
    }

    private var supportTitle: String {
        switch viewModel.selectedLanguage {
        case "fa": return "حمایت از ما"
        case "ru": return "Поддержать нас"
        default: return "Support Us"
        }
    }
    private var appearanceTitle: String {
        switch viewModel.selectedLanguage {
        case "fa": return "ظاهر"
        case "ru": return "Оформление"
        default: return "Appearance"
        }
    }
    private var darkLabel: String {
        switch viewModel.selectedLanguage {
        case "fa": return "حالت تیره"
        case "ru": return "Тёмная"
        default: return "Dark"
        }
    }
    private var lightLabel: String {
        switch viewModel.selectedLanguage {
        case "fa": return "حالت روشن"
        case "ru": return "Светлая"
        default: return "Light"
        }
    }
    private var systemLabel: String {
        switch viewModel.selectedLanguage {
        case "fa": return "پیش‌فرض سیستم"
        case "ru": return "Системная"
        default: return "System"
        }
    }
}
