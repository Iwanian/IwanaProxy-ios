import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var viewModel: ProxyViewModel
    let onLanguageSelected: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                Spacer().frame(height: 24)

                RoundedRectangle(cornerRadius: 28)
                    .fill(Theme.primaryContainer)
                    .frame(width: 100, height: 100)
                    .overlay(Text("🌐").font(.system(size: 52)))

                Spacer().frame(height: 32)

                Text(L.t("first_launch_title", lang: viewModel.selectedLanguage))
                    .font(.title2.bold())
                    .foregroundColor(Theme.primary)
                    .multilineTextAlignment(.center)

                Text(L.t("select_lang_desc", lang: viewModel.selectedLanguage))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                Spacer().frame(height: 24)

                VStack(spacing: 16) {
                    ForEach(L.supportedLanguages) { option in
                        Button {
                            viewModel.setLanguage(option.code)
                            onLanguageSelected()
                        } label: {
                            HStack(spacing: 18) {
                                Text(option.emoji).font(.system(size: 24))
                                Text(option.displayName)
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(Theme.onSurface)
                                Spacer()
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 24)
                            .background(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.tertiary.opacity(0.5)))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Iwana Proxy")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
