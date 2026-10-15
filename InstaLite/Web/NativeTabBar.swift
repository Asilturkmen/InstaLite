import UIKit

/// Instagram'ın web alt çubuğunun yerini alan yerel sekme çubuğu.
/// Sayfa durumu `tabs.js`'ten gelir; dokunuşlar `onSelect` ile sayfaya iletilir.
final class NativeTabBar: UITabBar, UITabBarDelegate {
    enum Tab: Int, CaseIterable {
        case home, search, messages, profile

        /// `tabs.js`'teki `open()`'a giden ad.
        var name: String { String(describing: self) }

        fileprivate var item: UITabBarItem {
            let (title, image, selected) = switch self {
            case .home: ("Ana sayfa", "house", "house.fill")
            case .search: ("Ara", "magnifyingglass", "magnifyingglass")
            case .messages: ("Mesajlar", "paperplane", "paperplane.fill")
            case .profile: ("Profil", "person.crop.circle", "person.crop.circle.fill")
            }
            let item = UITabBarItem(title: nil, image: UIImage(systemName: image), selectedImage: UIImage(systemName: selected))
            item.accessibilityLabel = title
            item.tag = rawValue
            return item
        }
    }

    /// Sayfanın bildirdiği durum: hangi yolda olunduğu ve oturum açık profilin yolu.
    struct Route: Equatable {
        var path: String
        var loggedIn: Bool
        var profile: String?
        var avatar: URL?
    }

    var onSelect: ((Tab) -> Void)?

    private let haptics = UISelectionFeedbackGenerator()
    private var avatarURL: URL?
    private var avatar: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        items = Tab.allCases.map(\.item)
        selectedItem = items?.first
        tintColor = .label
        unselectedItemTintColor = .label
        // Seçili profil halkası sabit renkle çizilir; görünüm değişince yeniden çizilsin.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (bar: NativeTabBar, _) in
            bar.applyAvatar()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    /// Sekme çubuğunun bu sayfada görünüp görünmeyeceği. Sohbet, hikâye, Reel ve giriş
    /// ekranlarında Instagram uygulamasında olduğu gibi gizlenir.
    static func isVisible(on route: Route) -> Bool {
        guard route.loggedIn else { return false }
        let fullScreen = ["/direct/t/", "/stories/", "/reel/", "/accounts/", "/challenge/", "/create/"]
        return !fullScreen.contains { route.path.hasPrefix($0) }
    }

    func update(with route: Route) {
        if let tab = Self.tab(for: route), selectedItem?.tag != tab.rawValue {
            selectedItem = items?[tab.rawValue]
        }
        if route.avatar != avatarURL {
            avatarURL = route.avatar
            loadAvatar(route.avatar)
        }
    }

    /// Bilinen bir sekmenin köküne denk gelmeyen sayfalarda (gönderi, başka profil) seçili sekme korunur.
    private static func tab(for route: Route) -> Tab? {
        if route.path == "/" { return .home }
        if route.path.hasPrefix("/explore/") { return .search }
        if route.path.hasPrefix("/direct/") { return .messages }
        if let profile = route.profile, route.path.hasPrefix(profile) { return .profile }
        return nil
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tab = Tab(rawValue: item.tag) else { return }
        haptics.selectionChanged()
        onSelect?(tab)
    }

    /// Profil sekmesinde Instagram uygulamasındaki gibi profil fotoğrafı gösterilir.
    private func loadAvatar(_ url: URL?) {
        avatar = nil
        applyAvatar()
        guard let url else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.avatarURL == url else { return }
                self.avatar = image
                self.applyAvatar()
            }
        }.resume()
    }

    /// Fotoğraf yoksa (henüz yüklenmedi ya da oturum kapandı) varsayılan simgeye döner.
    private func applyAvatar() {
        guard let item = items?[Tab.profile.rawValue] else { return }
        guard let avatar else {
            let fallback = Tab.profile.item
            item.image = fallback.image
            item.selectedImage = fallback.selectedImage
            return
        }
        traitCollection.performAsCurrent {
            item.image = Self.circle(avatar, ring: false)
            item.selectedImage = Self.circle(avatar, ring: true)
        }
    }

    private static func circle(_ image: UIImage, ring: Bool) -> UIImage {
        let size = CGSize(width: 28, height: 28)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in
            let bounds = CGRect(origin: .zero, size: size)
            let photo = ring ? bounds.insetBy(dx: 2.5, dy: 2.5) : bounds.insetBy(dx: 1, dy: 1)
            if ring {
                UIColor.label.setStroke()
                let border = UIBezierPath(ovalIn: bounds.insetBy(dx: 0.75, dy: 0.75))
                border.lineWidth = 1.5
                border.stroke()
            }
            UIBezierPath(ovalIn: photo).addClip()
            image.draw(in: photo)
        }
        return rendered.withRenderingMode(.alwaysOriginal)
    }
}
