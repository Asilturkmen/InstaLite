#if DEBUG
import Foundation
import WebKit

/// Yalnız geliştirme sürümünde: uygulamanın `Documents/bridge/cmd.js` dosyasına yazılan JS gövdesini
/// sayfada çalıştırır, dönen değeri `out.json`'a yazar (`Tools/bridge.sh`). Ayrıca `debug.js`'in her
/// saniye yolladığı ölçümleri `metrics.jsonl`'a ekler (`Tools/metrics.sh`).
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
        if let url = Bundle.main.url(forResource: "debug", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
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
        guard let source = try? String(contentsOf: command, encoding: .utf8) else { return }
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
}
#endif
