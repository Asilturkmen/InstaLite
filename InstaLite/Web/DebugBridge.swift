#if DEBUG
import Foundation
import WebKit

/// Yalnız geliştirme sürümünde: uygulamanın `Documents/bridge/cmd.js` dosyasına yazılan JS gövdesini
/// sayfada çalıştırır, dönen değeri `out.json`'a yazar (`Tools/bridge.sh`). Ayrıca `metricsScript`'in her
/// saniye yolladığı ölçümleri `metrics.jsonl`'a ekler (`Tools/metrics.sh`). Betik normal sürümün paketine
/// girmesin diye burada, yalnız Debug'da derlenen kodun içinde durur.
final class DebugBridge: NSObject, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private let directory: URL
    private var timer: Timer?
    private var metrics: FileHandle?

    init(webView: WKWebView) {
        self.webView = webView
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bridge")
        super.init()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let metricsURL = directory.appendingPathComponent("metrics.jsonl")
        FileManager.default.createFile(atPath: metricsURL.path, contents: nil)
        metrics = try? FileHandle(forWritingTo: metricsURL)

        let controller = webView.configuration.userContentController
        controller.add(self, name: "instaliteDebug")
        controller.addUserScript(WKUserScript(source: Self.metricsScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard var sample = message.body as? [String: Any], let scrollView = webView?.scrollView else { return }
        sample["nativeOffset"] = Int(scrollView.contentOffset.y)
        sample["nativeContent"] = Int(scrollView.contentSize.height)
        guard var line = try? JSONSerialization.data(withJSONObject: sample) else { return }
        line.append(0x0A)
        metrics?.write(line)
    }

    private func poll() {
        let command = directory.appendingPathComponent("cmd.js")
        // Telefona kopyalama atomik değil; dosya bitiş işaretiyle tamamlanmadıysa sonraki turda okunur.
        guard let source = try? String(contentsOf: command, encoding: .utf8),
              source.hasSuffix("// instalite:end\n")
        else { return }
        try? FileManager.default.removeItem(at: command)
        webView?.callAsyncJavaScript(source, arguments: [:], in: nil, in: .page) { [weak self] result in
            self?.write(result)
        }
    }

    private func write(_ result: Result<Any, Error>) {
        var payload: [String: Any]
        switch result {
        case .success(let value):
            payload = ["ok": true, "value": value as? String ?? String(describing: value)]
        case .failure(let error):
            payload = ["ok": false, "error": String(describing: error)]
        }
        if let scrollView = webView?.scrollView {
            payload["native"] = [
                "contentHeight": scrollView.contentSize.height,
                "offsetY": scrollView.contentOffset.y,
                "frameHeight": scrollView.frame.height,
                "insetTop": scrollView.adjustedContentInset.top,
                "insetBottom": scrollView.adjustedContentInset.bottom,
                "zoom": scrollView.zoomScale,
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        try? data.write(to: directory.appendingPathComponent("out.json"), options: .atomic)
    }

    private static let metricsScript = #"""
// Yalnız geliştirme sürümünde eklenir: her saniye kaydırma sırasındaki kare sürelerini ve
// sayfa durumunu uygulamaya yollar; DebugBridge bunları Documents/bridge/metrics.jsonl'a yazar.
(function () {
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.instaliteDebug;
  if (!handler) return;

  let scrollAt = 0;
  let scrolls = 0;
  let previous = performance.now();
  let frames = [];

  addEventListener('scroll', () => {
    scrollAt = performance.now();
    scrolls++;
  }, { passive: true, capture: true });

  requestAnimationFrame(function tick(now) {
    if (now - scrollAt < 150) frames.push(Math.round((now - previous) * 10) / 10);
    previous = now;
    requestAnimationFrame(tick);
  });

  setInterval(() => {
    const articles = document.querySelectorAll('article');
    let hidden = 0;
    let reels = 0;
    for (const article of articles) {
      if (getComputedStyle(article).display === 'none') hidden++;
      if (article.querySelector('a[href*="/reel/"]')) reels++;
    }
    handler.postMessage({
      t: Date.now(),
      // Adres kişisel olabilir (profil, hikâye); yalnız sayfa türü yazılır.
      path: location.pathname === '/' ? 'akış' : 'diğer',
      y: Math.round(scrollY),
      docH: document.documentElement.scrollHeight,
      articles: articles.length,
      hidden,
      reels,
      removedReels: globalThis.__instaLiteRemovedReels || 0,
      scrolls,
      frames,
    });
    scrolls = 0;
    frames = [];
  }, 1000);
})();
"""#
}
#endif
