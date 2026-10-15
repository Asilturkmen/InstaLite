# InstaLite

Reels'siz Instagram: instagram.com'u uygulama içi web görünümünde açan kişisel iOS uygulaması.
Analitik, sunucu ya da dış istek yok.

> **Not:** Bu proje Meta Platforms, Inc. ya da Instagram ile bağlantılı değildir; onlar tarafından
> desteklenmez veya onaylanmaz. "Instagram" Meta'nın tescilli markasıdır. InstaLite kişisel kullanım
> için yazılmış bir açık kaynak projesidir; App Store'da dağıtılmaz. Kullanırken Instagram'ın
> kullanım koşulları geçerlidir.

## Gizlilik ve güvenlik

- Uygulamanın sunucusu, analitiği ya da üçüncü taraf kütüphanesi yok. Uygulamanın kendisi yalnız profil
  fotoğrafını Instagram'ın resim sunucusundan indirir; oturum çerezleri bu istekle gitmez.
- Instagram oturumu yalnız cihazda, uygulamanın kendi web deposunda tutulur.
- instagram.com dışındaki bağlantılar Safari'de açılır. Başka uygulama açan adresler (App Store, `tel:` vb.)
  yalnız kullanıcı dokunduğunda açılır.
- Debug sürümü geliştirme köprüsü (`Web/DebugBridge.swift`) ve sayfa denetleyicisi içerir; günlük kullanım için
  Release sürümünü kur: `Tools/run-device.sh Release`.

## Kurulum

```sh
brew install xcodegen
xcodegen generate          # InstaLite.xcodeproj'u project.yml'den üretir (git'e girmez)
open InstaLite.xcodeproj
```

İmza için `Config/Local.xcconfig` oluştur (git'e girmez):

```
DEVELOPMENT_TEAM = <Team ID>
INSTALITE_BUNDLE_ID = com.<adın>.instalite
```

Team ID, Xcode → Settings → Accounts'ta görünür. Uygulama kimlikleri Apple hesapları arasında
benzersiz olmalı, o yüzden kendine özgü bir `INSTALITE_BUNDLE_ID` seç.
iPhone'da Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu açık olmalı. Ücretsiz hesapta imza
7 gün geçerlidir; süre dolunca Xcode'dan yeniden Run.

## Nasıl engeller

- `Web/BlockRules.swift`: gerçek sayfa yüklemeleri (`decidePolicyFor`) ve Safari'de açılacak dış bağlantılar.
- `Resources/rules.js` + `blocker.js`: sayfa yeniden yüklenmeden yapılan geçişler (`history.pushState`).
- `Resources/feed-filter.js`: akıştaki Reels, Instagram'ın listesi görmeden veriden çıkarılır (CSS ile gizlemek
  akışın sanal listesini bozar: sayfa başa sıçrar, takılır).
- `Resources/hide.css` + `page.js`: Reels sekmeleri, "Uygulamada aç" bantları ve web ipuçları.
- `Resources/tabs.js` + `Web/NativeTabBar.swift`: web alt çubuğunun yerine yerel sekme çubuğu.

Engellenen: `/reels/`, `/<kullanıcı>/reels/`, Keşfet (`/explore/` aramaya yönlenir), bir Reel'den başka
bir Reel'e geçiş. DM'den açılan tek Reel serbesttir.

## Test

```sh
node --test                                    # JS kuralları
xcodebuild test -scheme InstaLite \
  -destination 'platform=iOS Simulator,name=iPhone 17'   # Swift kuralları, aynı vakalar
```

İki taraf da `Tests/rules-cases.json` vakalarını kullanır; bir kuralı değiştirirken ikisini birlikte değiştir.

Geliştirme araçları (yalnız Debug sürümünde çalışır): `Tools/run-sim.sh` / `Tools/run-device.sh` derleyip kurar,
`Tools/bridge.sh` açık uygulamanın sayfasında JS çalıştırır, `Tools/uitest.sh` telefonda akışı gerçek dokunuşla
kaydırıp akıcılığı ölçer (`InstaLiteMetrics` şeması; açık Instagram oturumu ister).

## Lisans

[MIT](LICENSE)
