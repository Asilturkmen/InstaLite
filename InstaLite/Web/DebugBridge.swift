#if DEBUG
import Foundation
import WebKit

/// Yalnız geliştirme sürümünde: simülatörde uygulamanın `Documents/bridge/cmd.js` dosyasına yazılan
/// JS gövdesini sayfada çalıştırır, dönen değeri `out.json`'a yazar. `Tools/sim.sh` ile kullanılır.
final class DebugBridge {
    private weak var webView: WKWebView?
    private let directory: URL
    private var timer: Timer?

    init(webView: WKWebView) {
        self.webView = webView
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bridge")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let command = directory.appendingPathComponent("cmd.js")
        guard let source = try? String(contentsOf: command, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(at: command)
        webView?.callAsyncJavaScript(source, arguments: [:], in: nil, in: .page) { [weak self] result in
            self?.write(result)
        }
    }

    private func write(_ result: Result<Any, Error>) {
        let payload: [String: Any]
        switch result {
        case .success(let value):
            payload = ["ok": true, "value": value as? String ?? String(describing: value)]
        case .failure(let error):
            payload = ["ok": false, "error": String(describing: error)]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        try? data.write(to: directory.appendingPathComponent("out.json"), options: .atomic)
    }
}
#endif
