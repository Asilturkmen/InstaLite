import Foundation
import WebKit

/// `Resources` içindeki betikleri ve stili her sayfaya, sayfanın kendi betiklerinden önce ekler.
enum ScriptInjector {
    static func install(into controller: WKUserContentController) {
        // Sayfa ile aynı JS dünyasında çalışmalı: history.pushState'i sarmak için sayfanın kendi nesnesi gerekir.
        add(resource("feed-filter", "js"), to: controller)
        add(resource("rules", "js") + "\n" + resource("blocker", "js"), to: controller)
        add(styleScript(css: resource("hide", "css")), to: controller)
        add(resource("page", "js"), to: controller)
        add(resource("tabs", "js"), to: controller)
    }

    private static func add(_ source: String, to controller: WKUserContentController) {
        controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    }

    private static func styleScript(css: String) -> String {
        let literal = (try? JSONEncoder().encode(css)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        return """
        (function () {
          const style = document.createElement('style');
          style.id = 'instalite-style';
          style.textContent = \(literal);
          (document.head || document.documentElement).appendChild(style);
        })();
        """
    }

    private static func resource(_ name: String, _ ext: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            preconditionFailure("Paket içinde \(name).\(ext) yok")
        }
        return source
    }
}
