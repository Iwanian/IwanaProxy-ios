import SwiftUI

/// Equivalent of Android's `ProxySpeedTestScreen.kt`.
struct ProxySpeedTestView: View {
    @ObservedObject var viewModel: ProxyViewModel
    private var lang: String? { viewModel.selectedLanguage }

    @State private var inputText = ""
    @State private var isTesting = false
    @State private var testProgress: Double = 0
    @State private var result: SpeedTestResult? = nil
    @State private var errorMessage: String? = nil
    @State private var testTask: Task<Void, Never>? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                inputCard

                if isTesting {
                    ProgressView(value: testProgress)
                        .tint(Theme.primary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.red)
                }

                if let result {
                    resultCard(result)
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L.t("proxy_speed_test", lang: lang))
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { testTask?.cancel() }
    }

    // MARK: Input card

    private var inputCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "link").foregroundColor(Theme.primary)
                TextField(L.t("proxy_input_hint", lang: lang), text: $inputText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onSubmit { startTest() }
                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                        result = nil
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))

            HStack(spacing: 8) {
                Button {
                    if let clip = UIPasteboard.general.string, !clip.isEmpty {
                        inputText = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                        errorMessage = nil
                    }
                } label: {
                    Label(L.t("paste_clipboard", lang: lang), systemImage: "doc.on.clipboard")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .foregroundColor(Theme.onSurface)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.tertiary))

                Button {
                    startTest()
                } label: {
                    Group {
                        if isTesting {
                            HStack {
                                ProgressView().tint(.white)
                                Text(L.t("testing", lang: lang)).fontWeight(.bold)
                            }
                        } else {
                            Label(L.t("start_test", lang: lang), systemImage: "play.fill")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .background(isTesting || inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.primary.opacity(0.4) : Theme.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .disabled(isTesting || inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))
    }

    private func startTest() {
        errorMessage = nil
        guard let parsed = ProxySpeedTester.parseInput(inputText) else {
            errorMessage = L.t("invalid_proxy_format", lang: lang)
            return
        }
        isTesting = true
        testProgress = 0.05
        result = nil
        testTask?.cancel()
        testTask = Task {
            let r = await ProxySpeedTester.runSpeedTest(proxy: parsed, targetDurationMs: 7000) { progress, _ in
                Task { @MainActor in testProgress = progress }
            }
            await MainActor.run {
                result = r
                isTesting = false
            }
        }
    }

    // MARK: Result card

    private func qualityColor(_ q: ConnectionQuality) -> Color {
        switch q {
        case .excellent: return Color(red: 0.18, green: 0.49, blue: 0.20)
        case .good: return Color(red: 0.22, green: 0.56, blue: 0.24)
        case .fair: return Color(red: 0.96, green: 0.49, blue: 0)
        case .poor: return Color(red: 0.9, green: 0.31, blue: 0)
        case .offline: return Color(red: 0.83, green: 0.18, blue: 0.18)
        }
    }

    private func qualityTitle(_ q: ConnectionQuality) -> String {
        switch q {
        case .excellent: return L.t("quality_excellent", lang: lang)
        case .good: return L.t("quality_good", lang: lang)
        case .fair: return L.t("quality_fair", lang: lang)
        case .poor: return L.t("quality_poor", lang: lang)
        case .offline: return L.t("quality_offline", lang: lang)
        }
    }

    private func resultCard(_ result: SpeedTestResult) -> some View {
        let color = qualityColor(result.quality)
        return VStack(spacing: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 140, height: 140)
                    Circle().stroke(color.opacity(0.55), lineWidth: 5).frame(width: 140, height: 140)
                    if result.isSuccess {
                        VStack(spacing: 0) {
                            Text("\(result.avgPing)").font(.system(size: 38, weight: .black)).foregroundColor(color)
                            Text("ms").font(.system(size: 14, weight: .bold)).foregroundColor(color.opacity(0.8))
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "cloud.slash.fill").font(.system(size: 36)).foregroundColor(color)
                            Text(L.t("quality_offline", lang: lang).uppercased()).font(.system(size: 12, weight: .bold)).foregroundColor(color)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text("\(L.t("connection_quality", lang: lang)): \(qualityTitle(result.quality))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(color.opacity(0.14))
                .clipShape(Capsule())
            }

            Divider()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile(label: L.t("stability_label", lang: lang), value: result.isSuccess ? "\(result.stabilityPercent)%" : "0%", systemIcon: "checkmark.seal.fill", tint: Theme.success)
                    StatTile(label: L.t("avg_ping", lang: lang), value: result.isSuccess ? "ms \(result.avgPing)" : "--", systemIcon: "waveform.path.ecg", tint: Theme.primary)
                }
                HStack(spacing: 10) {
                    StatTile(label: L.t("download_speed", lang: lang), value: result.isSuccess ? "Mbps \(String(format: "%.1f", result.downloadSpeedMbps))" : "--", systemIcon: "arrow.down.circle.fill", tint: Theme.primary)
                    StatTile(label: L.t("upload_speed", lang: lang), value: result.isSuccess ? "Mbps \(String(format: "%.1f", result.uploadSpeedMbps))" : "--", systemIcon: "arrow.up.circle.fill", tint: Theme.teal)
                }
                HStack(spacing: 10) {
                    StatTile(label: L.t("jitter_label", lang: lang), value: result.isSuccess ? "ms ±\(result.jitter)" : "--", systemIcon: "chart.xyaxis.line", tint: Theme.warning)
                    StatTile(label: L.t("packet_loss_label", lang: lang), value: "\(result.packetLossPercent)%", systemIcon: "arrow.triangle.2.circlepath", tint: result.packetLossPercent > 0 ? Theme.danger : Theme.success)
                }
            }

            if result.isSuccess {
                TelegramSpeedEstimatorCard(rawSpeedMbps: result.downloadSpeedMbps, lang: lang)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(result.parsedProxy.server):\(result.parsedProxy.port)")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(Theme.onSurface)
                if let ip = result.ipAddress, !ip.isEmpty, ip != result.parsedProxy.server {
                    Text("IP: \(ip)").font(.caption2.monospaced()).foregroundColor(.secondary)
                }
                if result.dnsLookupMs >= 0 {
                    Text("DNS Lookup: \(result.dnsLookupMs) ms").font(.caption2).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(14)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 10) {
                Button {
                    TelegramLauncher.launchProxy(result.parsedProxy.originalLink)
                } label: {
                    HStack(spacing: 6) {
                        Text(L.t("connect", lang: lang)).fontWeight(.bold)
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = result.parsedProxy.originalLink
                    } label: {
                        Label(L.t("copy", lang: lang), systemImage: "doc.on.doc")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .foregroundColor(Theme.onSurface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.tertiary))

                    Button {
                        viewModel.toggleSave(result.parsedProxy.originalLink)
                    } label: {
                        Label(
                            L.t("save", lang: lang),
                            systemImage: viewModel.savedLinks.contains(result.parsedProxy.originalLink) ? "bookmark.fill" : "bookmark"
                        )
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .foregroundColor(Theme.onSurface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.tertiary))
                }
            }
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))
    }
}

/// Equivalent of the Kotlin `TelegramSpeedEstimatorCard` composable —
/// estimates real Telegram download speed and a file-size download-time calculator.
private struct TelegramSpeedEstimatorCard: View {
    let rawSpeedMbps: Double
    let lang: String?

    @State private var fileSizeInput = ""

    private var estimatedTelegramSpeedMBps: Double {
        max(0, (rawSpeedMbps.isFinite ? rawSpeedMbps : 0) * 0.035)
    }

    private var estimatedTime: String? {
        let normalized = normalizeDecimal(fileSizeInput)
        guard let size = Double(normalized), size > 0, estimatedTelegramSpeedMBps > 0.0001 else { return nil }
        let totalSeconds = Int((size / estimatedTelegramSpeedMBps).rounded())
        return formatDuration(totalSeconds)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text(L.t("estimated_badge", lang: lang))
                    .font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.primaryContainer)
                    .foregroundColor(Theme.primary)
                    .clipShape(Capsule())
                Spacer()
                HStack(spacing: 6) {
                    Text(L.t("real_telegram_download_speed", lang: lang)).font(.system(size: 14, weight: .bold))
                    Image(systemName: "icloud.and.arrow.down.fill").foregroundColor(Theme.primary)
                }
            }

            HStack(spacing: 4) {
                Text("MB/s").font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
                Text(String(format: "%.2f", estimatedTelegramSpeedMBps))
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(Theme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Text(L.t("telegram_speed_disclaimer", lang: lang))
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Divider()

            Text(L.t("file_download_estimator", lang: lang))
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .trailing)

            TextField(L.t("file_size_mb_hint", lang: lang), text: $fileSizeInput)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .padding(10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.tertiary.opacity(0.5)))

            HStack(spacing: 6) {
                ForEach(["1000", "500", "100", "50", "10"], id: \.self) { preset in
                    let isSelected = normalizeDecimal(fileSizeInput) == preset
                    Button {
                        fileSizeInput = isSelected ? "" : preset
                    } label: {
                        Text("M \(preset)")
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isSelected ? Theme.primary : Theme.surface)
                            .foregroundColor(isSelected ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Theme.tertiary.opacity(0.5))
                            )
                    }
                }
            }

            if let estimatedTime {
                HStack(spacing: 10) {
                    VStack(alignment: .trailing) {
                        Text(L.t("estimated_time_result", lang: lang)).font(.caption2).foregroundColor(.secondary)
                        Text("≈ \(estimatedTime)").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.primary)
                    }
                    Spacer()
                    Image(systemName: "timer").foregroundColor(Theme.primary)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Theme.primaryContainer)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Theme.primaryContainer.opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.primary.opacity(0.25)))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func normalizeDecimal(_ input: String) -> String {
        var s = input.trimmingCharacters(in: .whitespaces)
        let map: [Character: Character] = [
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4", "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4", "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "٫": ".", "،": "."
        ]
        s = String(s.map { map[$0] ?? $0 })
        s = s.replacingOccurrences(of: ",", with: ".")
        return s
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        guard totalSeconds > 0 else { return "0" }
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        switch lang {
        case "fa":
            if days > 0 { return "\(days) روز و \(hours) ساعت" }
            if hours > 0 { return seconds > 0 ? "\(hours) ساعت و \(minutes) دقیقه و \(seconds) ثانیه" : "\(hours) ساعت و \(minutes) دقیقه" }
            if minutes > 0 { return seconds > 0 ? "\(minutes) دقیقه و \(seconds) ثانیه" : "\(minutes) دقیقه" }
            return "\(seconds) ثانیه"
        case "ru":
            if days > 0 { return "\(days) дн \(hours) ч" }
            if hours > 0 { return seconds > 0 ? "\(hours) ч \(minutes) мин \(seconds) сек" : "\(hours) ч \(minutes) мин" }
            if minutes > 0 { return seconds > 0 ? "\(minutes) мин \(seconds) сек" : "\(minutes) мин" }
            return "\(seconds) сек"
        default:
            if days > 0 { return "\(days) d \(hours) h" }
            if hours > 0 { return seconds > 0 ? "\(hours) hr \(minutes) min \(seconds) sec" : "\(hours) hr \(minutes) min" }
            if minutes > 0 { return seconds > 0 ? "\(minutes) min \(seconds) sec" : "\(minutes) min" }
            return "\(seconds) sec"
        }
    }
}
