import Foundation

/// Gerçek sayfa yüklemelerinde hangi adreslere gidilemeyeceğine ve hangi bağlantıların
/// Safari'de açılacağına karar verir. Yönlendirme kuralları `Resources/rules.js` ile aynıdır;
/// ikisi de `Tests/rules-cases.json` ile test edilir, birini değiştirirsen ötekini de değiştir.
enum BlockRules {
    /// `from` yolundan `to` yoluna geçilirken gidilecek yeri döner; nil ise geçiş serbesttir.
    static func redirect(from: String?, to: String) -> String? {
        let parts = segments(to)
        if parts.first == "explore" {
            if parts.count > 1 && parts[1] == "search" { return nil }
            return parts.count == 1 ? "/explore/search/" : "/"
        }
        if parts.first == "reels" || (parts.count > 1 && parts[1] == "reels") { return "/" }

        // DM'den açılan tek Reel serbest; bir Reel'den başka bir Reel'e geçiş değil.
        if let toReel = reelID(parts), let from, let fromReel = reelID(segments(from)), fromReel != toReel {
            return "/"
        }
        return nil
    }

    /// Safari'de açılması gereken adresi döner; nil ise bağlantı uygulamada açılır.
    /// Instagram dış bağlantıları `l.instagram.com/?u=...` yönlendiricisinden geçirir.
    static func externalURL(for url: URL) -> URL? {
        switch url.scheme?.lowercased() {
        case nil, "about", "blob", "data", "javascript":
            return nil
        case "http", "https":
            guard isInstagram(url) else { return url }
            guard url.host?.lowercased() == "l.instagram.com" else { return nil }
            let target = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "u" }?.value
            return target.flatMap(URL.init(string:)) ?? url
        default:
            return url
        }
    }

    static func isInstagram(_ url: URL) -> Bool {
        isInstagramHost(url.host)
    }

    static func isInstagramHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "instagram.com" || host.hasSuffix(".instagram.com")
    }

    /// Profil fotoğrafı gibi uygulamanın kendisinin indirdiği resimler yalnız bu sunuculardan gelir.
    static func isInstagramImage(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        return ["cdninstagram.com", "fbcdn.net"].contains { host == $0 || host.hasSuffix("." + $0) }
    }

    private static func segments(_ path: String) -> [Substring] {
        path.split(separator: "/")
    }

    private static func reelID(_ parts: [Substring]) -> Substring? {
        if parts.count > 1 && parts[0] == "reel" { return parts[1] }
        if parts.count > 2 && parts[1] == "reel" { return parts[2] }
        return nil
    }
}
