import UIKit

/// Bağlantı yokken tarayıcı hata sayfası yerine gösterilen sade ekran.
final class OfflineView: UIView {
    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(named: "LaunchBackground")

        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .secondaryLabel
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)

        let title = UILabel()
        title.text = "İnternet bağlantısı yok"
        title.font = .preferredFont(forTextStyle: .headline)

        let detail = UILabel()
        detail.text = "Bağlantı gelince sayfa kendiliğinden yenilenir."
        detail.font = .preferredFont(forTextStyle: .subheadline)
        detail.textColor = .secondaryLabel
        detail.textAlignment = .center
        detail.numberOfLines = 0

        let retry = UIButton(configuration: .plain(), primaryAction: UIAction(title: "Tekrar dene") { [weak self] _ in
            self?.onRetry?()
        })

        let stack = UIStackView(arrangedSubviews: [icon, title, detail, retry])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(24, after: detail)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }
}
