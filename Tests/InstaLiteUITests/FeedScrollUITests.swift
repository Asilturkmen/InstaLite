import XCTest

/// Akışı gerçek parmak hareketiyle kaydırır; akıcılık ölçümünü Debug sürümündeki `debug.js` kaydeder,
/// sonuç `Tools/metrics.sh` ile okunur. Ortam: TEST_RUNNER_SWIPES (adet), TEST_RUNNER_NOINJECT=1
/// (betik ve stil olmadan karşılaştırma için), TEST_RUNNER_NOLAUNCH=1 (açık uygulamayı yeniden başlatmadan).
final class FeedScrollUITests: XCTestCase {
    func testScrollFeed() throws {
        let environment = ProcessInfo.processInfo.environment
        let app = XCUIApplication()
        if environment["NOLAUNCH"] == "1" {
            app.activate()
        } else {
            if environment["NOINJECT"] == "1" {
                app.launchArguments = ["-InstaLiteNoInject", "YES"]
            }
            app.launch()
            // Akışın ilk gönderileri yüklensin.
            Thread.sleep(forTimeInterval: 6)
        }

        let swipes = Int(environment["SWIPES"] ?? "") ?? 40
        for _ in 0..<swipes {
            app.swipeUp(velocity: .fast)
        }
        Thread.sleep(forTimeInterval: 3)
    }
}
