# InstaLite

Reels'siz Instagram: instagram.com'u uygulama içi web görünümünde açan kişisel iOS uygulaması.
Analitik, sunucu ya da dış istek yok.

> **Not:** Bu proje Meta Platforms, Inc. ya da Instagram ile bağlantılı değildir; onlar tarafından
> desteklenmez veya onaylanmaz. "Instagram" Meta'nın tescilli markasıdır. InstaLite kişisel kullanım
> için yazılmış bir açık kaynak projesidir; App Store'da dağıtılmaz. Kullanırken Instagram'ın
> kullanım koşulları geçerlidir.

## Kurulum

```sh
brew install xcodegen
xcodegen generate          # InstaLite.xcodeproj'u project.yml'den üretir (git'e girmez)
open InstaLite.xcodeproj
```

İmza için `Config/Local.xcconfig` oluştur (git'e girmez):

```
DEVELOPMENT_TEAM = <Team ID>
PRODUCT_BUNDLE_IDENTIFIER = com.<adın>.instalite
```

Team ID, Xcode → Settings → Accounts'ta görünür. Uygulama kimlikleri Apple hesapları arasında
benzersiz olmalı, o yüzden kendine özgü bir `PRODUCT_BUNDLE_IDENTIFIER` seç.
iPhone'da Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu açık olmalı. Ücretsiz hesapta imza
7 gün geçerlidir; süre dolunca Xcode'dan yeniden Run.

## Nasıl engeller

- `Web/BlockRules.swift`: gerçek sayfa yüklemeleri (`decidePolicyFor`) ve Safari'de açılacak dış bağlantılar.
- `Resources/rules.js` + `blocker.js`: sayfa yeniden yüklenmeden yapılan geçişler (`history.pushState`).
- `Resources/hide.css` + `page.js`: Reels düğmeleri, akıştaki Reels, "Uygulamada aç" bantları ve web ipuçları.

Engellenen: `/reels/`, `/<kullanıcı>/reels/`, Keşfet (`/explore/` aramaya yönlenir), bir Reel'den başka
bir Reel'e geçiş. DM'den açılan tek Reel serbesttir.

## Test

```sh
node --test                                    # JS kuralları
xcodebuild test -scheme InstaLite \
  -destination 'platform=iOS Simulator,name=iPhone 17'   # Swift kuralları, aynı vakalar
```

İki taraf da `Tests/rules-cases.json` vakalarını kullanır; bir kuralı değiştirirken ikisini birlikte değiştir.

## Lisans

[MIT](LICENSE)
