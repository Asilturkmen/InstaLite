import Network
import UIKit
import WebKit

/// Instagram'ın mobil web sürümünü tam ekran gösterir. Web'in alt çubuğunun yerinde yerel sekme
/// çubuğu durur; geri gitmek için kenardan kaydırılır, yenilemek için aşağı çekilir.
final class WebViewController: UIViewController {
    private static let home = URL(string: "https://www.instagram.com/")!

    private let webView: WKWebView
    private let tabBar = NativeTabBar()
    private let launchCover = UIView()
    private let offlineView = OfflineView()
    private let refreshControl = UIRefreshControl()
    private let pathMonitor = NWPathMonitor()
    private var failedURL: URL?
    private var webViewAboveTabBar: NSLayoutConstraint!
    private var webViewAboveSafeArea: NSLayoutConstraint!
    #if DEBUG
    private var debugBridge: DebugBridge?
    #endif

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.applicationNameForUserAgent = Self.safariApplicationName
        #if DEBUG
        // Karşılaştırma için: `-InstaLiteNoInject YES` ile başlatılınca betik ve stil eklenmez.
        let inject = !UserDefaults.standard.bool(forKey: "InstaLiteNoInject")
        #else
        let inject = true
        #endif
        if inject {
            ScriptInjector.install(into: configuration.userContentController)
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    deinit {
        pathMonitor.cancel()
    }

    /// Instagram'ın mobil sürümü vermesi için kullanıcı ajanı Mobile Safari gibi biter.
    private static var safariApplicationName: String {
        let version = UIDevice.current.systemVersion.split(separator: ".").prefix(2).joined(separator: ".")
        return "Version/\(version) Mobile/15E148 Safari/604.1"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let background = UIColor(named: "LaunchBackground")
        view.backgroundColor = background

        webView.isOpaque = false
        webView.backgroundColor = background
        webView.underPageBackgroundColor = background
        webView.scrollView.backgroundColor = background
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.removeInputAccessoryView()
        #if DEBUG
        webView.isInspectable = true
        debugBridge = DebugBridge(webView: webView)
        #endif

        webView.configuration.userContentController.add(ScriptMessageProxy(target: self), name: "instalite")
        tabBar.isHidden = true
        tabBar.onSelect = { [weak self] tab in
            self?.webView.evaluateJavaScript("globalThis.__instaLiteTabs && __instaLiteTabs.open('\(tab.name)')")
        }

        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        offlineView.isHidden = true
        offlineView.onRetry = { [weak self] in self?.retry() }
        launchCover.backgroundColor = background

        for subview in [webView, tabBar, offlineView, launchCover] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        let safeArea = view.safeAreaLayoutGuide
        webViewAboveTabBar = webView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        webViewAboveSafeArea = webView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            webViewAboveSafeArea,
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        for cover in [offlineView, launchCover] {
            NSLayoutConstraint.activate([
                cover.topAnchor.constraint(equalTo: view.topAnchor),
                cover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                cover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            DispatchQueue.main.async { self?.retryIfOffline() }
        }
        pathMonitor.start(queue: DispatchQueue(label: "InstaLite.network"))

        webView.load(URLRequest(url: Self.home))
    }

    private func show(_ route: NativeTabBar.Route) {
        tabBar.update(with: route)
        let visible = NativeTabBar.isVisible(on: route)
        guard tabBar.isHidden == visible else { return }
        tabBar.isHidden = !visible
        webViewAboveSafeArea.isActive = !visible
        webViewAboveTabBar.isActive = visible
    }

    @objc private func pullToRefresh() {
        webView.reload()
    }

    private func retryIfOffline() {
        guard !offlineView.isHidden else { return }
        retry()
    }

    private func retry() {
        webView.load(URLRequest(url: failedURL ?? webView.url ?? Self.home))
    }

    /// Açılış ekranı ilk sayfa çizilene kadar kalır; beyaz flaş olmaz.
    private func hideLaunchCover() {
        guard launchCover.superview != nil else { return }
        UIView.animate(withDuration: 0.2, animations: { self.launchCover.alpha = 0 }) { _ in
            self.launchCover.removeFromSuperview()
        }
    }

    private func handle(_ error: Error) {
        refreshControl.endRefreshing()
        let error = error as NSError
        let networkErrors = [
            NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut,
            NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed,
        ]
        guard error.domain == NSURLErrorDomain, networkErrors.contains(error.code) else { return }
        failedURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        offlineView.isHidden = false
        hideLaunchCover()
    }

    /// Engellenen adres sessizce yönlendirilir, dış bağlantı Safari'de açılır.
    /// Dönen değer true ise yükleme uygulamada devam etmemeli.
    private func route(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        if let external = BlockRules.externalURL(for: url) {
            UIApplication.shared.open(external)
            return true
        }
        if BlockRules.isInstagram(url), let target = BlockRules.redirect(from: webView.url?.path, to: url.path) {
            webView.load(URLRequest(url: URL(string: target, relativeTo: Self.home)!))
            return true
        }
        return false
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Yeni pencere isteyenler (targetFrame nil) createWebViewWith'te, iç çerçeveler hiç ele alınmaz.
        guard navigationAction.targetFrame?.isMainFrame == true else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(route(navigationAction.request) ? .cancel : .allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
        failedURL = nil
        offlineView.isHidden = true
        hideLaunchCover()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension WebViewController: WKScriptMessageHandler {
    /// `tabs.js` her sayfa değişiminde yolu, oturum durumunu ve profil bilgisini bildirir.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame,
              let body = message.body as? [String: Any],
              let path = body["path"] as? String
        else { return }
        show(NativeTabBar.Route(
            path: path,
            loggedIn: body["loggedIn"] as? Bool ?? false,
            profile: body["profile"] as? String,
            avatar: (body["avatar"] as? String).flatMap(URL.init(string:))
        ))
    }
}

/// `WKUserContentController` ileti alıcısını güçlü tutar; denetleyiciyle döngü olmasın diye zayıf aracı.
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

extension WebViewController: WKUIDelegate {
    /// `target="_blank"` bağlantıları ayrı pencere açmaz; aynı kurallarla burada ya da Safari'de açılır.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if !route(navigationAction.request) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Vazgeç", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}
