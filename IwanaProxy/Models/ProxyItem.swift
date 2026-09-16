import Foundation

/// Equivalent of Android's `ProxyItem.kt`
struct ProxyItem: Identifiable, Equatable, Hashable {
    let id: Int
    let server: String
    let port: Int
    let secret: String
    let link: String
    var ping: Int = -1
    var isAlive: Bool = false
    var isFavorite: Bool = false
    var isScanned: Bool = false
    var isForDownload: Bool = false
    var isRussian: Bool = false
}
