import UIKit

/// 可独立使用的日期选择菜单。
@objc public class JWDatePickerMenuHeaderView: UIView {
    @objc public var cancelHandler: (() -> Void)?
    @objc public var confirmHandler: (() -> Void)?
    public var locale: Locale = .current { didSet { updateAppearance() } }
    public var datePickerMode: JWDatePickerType = .date { didSet { updateAppearance() } }
    @objc public dynamic var cancelTitle: String {
        get { customCancelTitle ?? JWDatePickerLocalization.string("cancel", locale: locale) }
        set { customCancelTitle = newValue; updateAppearance() }
    }
    @objc public dynamic var confirmTitle: String {
        get { customConfirmTitle ?? JWDatePickerLocalization.string("confirm", locale: locale) }
        set { customConfirmTitle = newValue; updateAppearance() }
    }
    @objc public dynamic var cancelNormalColor: UIColor = .red { didSet { updateAppearance() } }
    @objc public dynamic var cancelHighlightedColor: UIColor = .red { didSet { updateAppearance() } }
    @objc public dynamic var confirmNormalColor: UIColor = .label { didSet { updateAppearance() } }
    @objc public dynamic var confirmHighlightedColor: UIColor = .label { didSet { updateAppearance() } }
    @objc public var cancelFont: UIFont = .systemFont(ofSize: 17) { didSet { updateAppearance() } }
    @objc public var confirmFont: UIFont = .systemFont(ofSize: 17) { didSet { updateAppearance() } }
    @objc public var attributedTitle: NSAttributedString? { didSet { updateAppearance() } }
    @objc public var horizontalInset: CGFloat = 16 { didSet { setNeedsLayout() } }
    @objc public dynamic var lineColor = UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1) {
        didSet { updateAppearance() }
    }
    @objc public var showsTopLine = true { didSet { topLine.isHidden = !showsTopLine } }
    @objc public var showsBottomLine = true { didSet { bottomLine.isHidden = !showsBottomLine } }

    private var customCancelTitle: String?
    private var customConfirmTitle: String?
    private let cancelButton = UIButton(type: .custom)
    private let confirmButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let topLine = UIView()
    private let bottomLine = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .systemBackground
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        for child in [topLine, cancelButton, titleLabel, confirmButton, bottomLine] { addSubview(child) }
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        updateAppearance()
    }

    private func updateAppearance() {
        semanticContentAttribute = Locale.characterDirection(forLanguage: locale.languageCode ?? "en") == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        if let attributedTitle {
            titleLabel.attributedText = attributedTitle
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = datePickerMode.localizedTitle(locale: locale)
        }
        cancelButton.setTitle(cancelTitle, for: .normal)
        confirmButton.setTitle(confirmTitle, for: .normal)
        cancelButton.setTitleColor(cancelNormalColor, for: .normal)
        cancelButton.setTitleColor(cancelHighlightedColor, for: .highlighted)
        confirmButton.setTitleColor(confirmNormalColor, for: .normal)
        confirmButton.setTitleColor(confirmHighlightedColor, for: .highlighted)
        cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        confirmButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cancelButton.titleLabel?.minimumScaleFactor = 0.75
        confirmButton.titleLabel?.minimumScaleFactor = 0.75
        cancelButton.titleLabel?.font = cancelFont
        confirmButton.titleLabel?.font = confirmFont
        topLine.backgroundColor = lineColor
        bottomLine.backgroundColor = lineColor
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let inset = max(0, horizontalInset)
        let left = safeAreaInsets.left + inset
        let right = safeAreaInsets.right + inset
        let available = max(0, bounds.width - left - right)
        let buttonWidth = min(available * 0.28, max(44, max(cancelButton.sizeThatFits(bounds.size).width, confirmButton.sizeThatFits(bounds.size).width) + 8))
        cancelButton.frame = CGRect(x: left, y: 0, width: buttonWidth, height: bounds.height)
        confirmButton.frame = CGRect(x: bounds.width - right - buttonWidth, y: 0, width: buttonWidth, height: bounds.height)
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            swap(&cancelButton.frame, &confirmButton.frame)
        }
        titleLabel.frame = CGRect(x: left + buttonWidth + 8, y: 0, width: max(0, available - 2 * buttonWidth - 16), height: bounds.height)
        let pixel = 1 / (window?.screen.scale ?? UIScreen.main.scale)
        topLine.frame = CGRect(x: 0, y: 0, width: bounds.width, height: pixel)
        bottomLine.frame = CGRect(x: 0, y: bounds.height - pixel, width: bounds.width, height: pixel)
    }

    @objc private func cancel() { cancelHandler?() }
    @objc private func confirm() { confirmHandler?() }
}
