import SwiftUI

/// Adaptive brand colors, ported 1:1 from the Android app's
/// `ui/theme/Color.kt` (Light/Dark palettes), using dynamic `UIColor`
/// providers so every screen automatically matches system light/dark mode.
enum Theme {

    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }

    /// Primary brand blue — LightPrimary #005FB0 / DarkPrimary #5AB6E5
    static let primary = dynamic(
        light: UIColor(red: 0x00/255, green: 0x5F/255, blue: 0xB0/255, alpha: 1),
        dark: UIColor(red: 0x5A/255, green: 0xB6/255, blue: 0xE5/255, alpha: 1)
    )

    /// Deep heading tone — LightSecondary #001D35 / DarkSecondary #1E293B
    static let secondary = dynamic(
        light: UIColor(red: 0x00/255, green: 0x1D/255, blue: 0x35/255, alpha: 1),
        dark: UIColor(red: 0xE2/255, green: 0xE8/255, blue: 0xF0/255, alpha: 1)
    )

    /// Card / surface background — LightSurface #FFFFFF / DarkSurface #141E30
    static let surface = dynamic(
        light: UIColor(red: 0xFF/255, green: 0xFF/255, blue: 0xFF/255, alpha: 1),
        dark: UIColor(red: 0x14/255, green: 0x1E/255, blue: 0x30/255, alpha: 1)
    )

    /// Screen background — LightBackground #FDFBFF / DarkBackground #0F172A
    static let background = dynamic(
        light: UIColor(red: 0xFD/255, green: 0xFB/255, blue: 0xFF/255, alpha: 1),
        dark: UIColor(red: 0x0F/255, green: 0x17/255, blue: 0x2A/255, alpha: 1)
    )

    /// Slate border/accent — LightTertiary #E1E2EC / DarkTertiary #2E3D52
    static let tertiary = dynamic(
        light: UIColor(red: 0xE1/255, green: 0xE2/255, blue: 0xEC/255, alpha: 1),
        dark: UIColor(red: 0x2E/255, green: 0x3D/255, blue: 0x52/255, alpha: 1)
    )

    /// Primary container fill — soft tertiary tint used behind icon rows/badges.
    static let primaryContainer = dynamic(
        light: UIColor(red: 0xE1/255, green: 0xE2/255, blue: 0xEC/255, alpha: 0.55),
        dark: UIColor(red: 0x2E/255, green: 0x3D/255, blue: 0x52/255, alpha: 0.85)
    )

    static let onSurface = dynamic(
        light: UIColor(red: 0x1B/255, green: 0x1B/255, blue: 0x1F/255, alpha: 1),
        dark: UIColor(red: 0xF8/255, green: 0xFA/255, blue: 0xFC/255, alpha: 1)
    )

    // Status colors — same hue family across light/dark, semantic and consistent
    // with the badges seen in the Android screenshots.
    static let success = dynamic(
        light: UIColor(red: 0x1B/255, green: 0x8A/255, blue: 0x4C/255, alpha: 1),
        dark: UIColor(red: 0x4A/255, green: 0xDE/255, blue: 0x80/255, alpha: 1)
    )
    static let successContainer = dynamic(
        light: UIColor(red: 0xE3/255, green: 0xF6/255, blue: 0xE8/255, alpha: 1),
        dark: UIColor(red: 0x14/255, green: 0x3D/255, blue: 0x27/255, alpha: 1)
    )
    static let warning = dynamic(
        light: UIColor(red: 0xB0/255, green: 0x63/255, blue: 0x02/255, alpha: 1),
        dark: UIColor(red: 0xF5/255, green: 0xB1/255, blue: 0x4D/255, alpha: 1)
    )
    static let warningContainer = dynamic(
        light: UIColor(red: 0xFF/255, green: 0xF1/255, blue: 0xDB/255, alpha: 1),
        dark: UIColor(red: 0x40/255, green: 0x30/255, blue: 0x10/255, alpha: 1)
    )
    static let danger = dynamic(
        light: UIColor(red: 0xC6/255, green: 0x28/255, blue: 0x28/255, alpha: 1),
        dark: UIColor(red: 0xF3/255, green: 0x7A/255, blue: 0x7A/255, alpha: 1)
    )
    static let dangerContainer = dynamic(
        light: UIColor(red: 0xFD/255, green: 0xE7/255, blue: 0xE7/255, alpha: 1),
        dark: UIColor(red: 0x40/255, green: 0x18/255, blue: 0x18/255, alpha: 1)
    )
    static let pink = dynamic(
        light: UIColor(red: 0xD8/255, green: 0x1B/255, blue: 0x60/255, alpha: 1),
        dark: UIColor(red: 0xF4/255, green: 0x8F/255, blue: 0xB1/255, alpha: 1)
    )
    static let pinkContainer = dynamic(
        light: UIColor(red: 0xFC/255, green: 0xE4/255, blue: 0xEC/255, alpha: 1),
        dark: UIColor(red: 0x3D/255, green: 0x14/255, blue: 0x24/255, alpha: 1)
    )
    static let teal = dynamic(
        light: UIColor(red: 0x00/255, green: 0x6D/255, blue: 0x60/255, alpha: 1),
        dark: UIColor(red: 0x4D/255, green: 0xD0/255, blue: 0xC0/255, alpha: 1)
    )
    static let tealContainer = dynamic(
        light: UIColor(red: 0xDB/255, green: 0xF3/255, blue: 0xEF/255, alpha: 1),
        dark: UIColor(red: 0x0E/255, green: 0x38/255, blue: 0x33/255, alpha: 1)
    )
}

// MARK: - Reusable components

/// A rounded status "pill" badge, matching the small colored labels seen
/// throughout the Android app (متصل / روسی / دانلودی / اسکن).
struct PillBadge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(Capsule())
    }
}

/// A card container matching the Android app's rounded, softly-shadowed surfaces.
struct SurfaceCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.tertiary.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

/// A single stat tile used in the speed-test result grid (icon, label, value).
struct StatTile: View {
    let label: String
    let value: String
    let systemIcon: String
    var tint: Color = Theme.primary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.onSurface)
            }
            Spacer(minLength: 4)
            Image(systemName: systemIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.tertiary.opacity(0.4), lineWidth: 1)
        )
    }
}

/// A colored navigation row used on the Settings screen (saved proxies /
/// speed test / support), matching the tinted rounded rows in the screenshots.
struct TintedNavRow: View {
    let title: String
    let systemIcon: String
    let tint: Color
    let container: Color

    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(tint)
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(container)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
