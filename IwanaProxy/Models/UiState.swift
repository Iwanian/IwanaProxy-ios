import Foundation

/// Equivalent of Android's `UiState.kt`
enum UiState: Equatable {
    case loading
    case success([ProxyItem])
    case error(String)
}

/// Equivalent of Android's `BannerItem` (declared inside BannerRepository.kt)
struct BannerItem: Identifiable, Equatable, Codable {
    var id: String { imageUrl }
    let imageUrl: String
    let targetLink: String?
}
