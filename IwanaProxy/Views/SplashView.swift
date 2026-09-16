import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 32)
                .fill(Theme.primaryContainer)
                .frame(width: 150, height: 150)
                .overlay(
                    Text("🌐")
                        .font(.system(size: 64))
                )

            Text("Iwana Proxy")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(Theme.primary)

            ProgressView()
                .tint(Theme.primary)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}
