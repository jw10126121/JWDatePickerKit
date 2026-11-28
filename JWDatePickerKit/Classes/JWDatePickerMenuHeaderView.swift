import UIKit

/// 可独立使用的日期选择菜单。
@objc public class JWDatePickerMenuHeaderView: UIView {
    @objc public var cancelHandler: (() -> Void)?
    @objc public var confirmHandler: (() -> Void)?
    public var locale: Locale = .current { didSet { updateAppearance() } }
    public var type: JWDatePickerType = .date { didSet { updateAppearance() } }
    @objc public dynamic var cancelTitle: String {
        get { customCancelTitle ?? JWDatePickerLocalization.string("cancel", locale: locale) }
        set { customCancelTitle = newValue; updateAppearance() }
    }
    @objc public dynamic var confirmTitle: String {
        get { customConfirmTitle ?? JWDatePickerLocalization.string("confirm", locale: locale) }
        set { customConfirmTitle = newValue; updateAppearance() }
    }
    @objc public dynamic var cancelNormalColor: UIColor = .secondaryLabel { didSet { updateAppearance() } }
    @objc public dynamic var cancelHighlightedColor: UIColor = .secondaryLabel { didSet { updateAppearance() } }
    @objc public dynamic var confirmNormalColor: UIColor = .systemTeal { didSet { updateAppearance() } }
    @objc public dynamic var confirmHighlightedColor: UIColor = .systemTeal { didSet { updateAppearance() } }
    @objc public var cancelFont: UIFont = .systemFont(ofSize: 17) { didSet { updateAppearance() } }
    @objc public var confirmFont: UIFont = .systemFont(ofSize: 17) { didSet { updateAppearance() } }
    @objc public var attributedTitle: NSAttributedString? { didSet { updateAppearance() } }
    @objc public var horizontalInset: CGFloat = 16 { didSet { setNeedsLayout() } }
    @objc public dynamic var lineColor: UIColor = .separator {
        didSet { updateAppearance() }
    }
    /// 是否显示头部上分隔线，默认隐藏。
    @objc public var showsTopLine = false { didSet { topLine.isHidden = !showsTopLine } }
    /// 是否显示头部下分隔线，默认隐藏。
    @objc public var showsBottomLine = false { didSet { bottomLine.isHidden = !showsBottomLine } }

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
            titleLabel.text = type.localizedTitle(locale: locale)
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
        // 属性初始值不会触发 didSet，初始化时也需要同步实际可见性。
        topLine.isHidden = !showsTopLine
        bottomLine.isHidden = !showsBottomLine
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let inset = max(0, horizontalInset)
        let left = safeAreaInsets.left + inset
        let right = safeAreaInsets.right + inset
        let available = max(0, bounds.width - left - right)
        let idealWidth = max(cancelButton.sizeThatFits(bounds.size).width, confirmButton.sizeThatFits(bounds.size).width)
        let buttonWidth = min(available / 2, max(44, min(available * 0.28, idealWidth + 8)))
        cancelButton.frame = CGRect(x: left, y: 0, width: buttonWidth, height: bounds.height)
        confirmButton.frame = CGRect(x: bounds.width - right - buttonWidth, y: 0, width: buttonWidth, height: bounds.height)
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            swap(&cancelButton.frame, &confirmButton.frame)
        }
        titleLabel.frame = CGRect(x: left + buttonWidth + 8, y: 0, width: max(0, available - 2 * buttonWidth - 16), height: bounds.height)
        // 使用 1 点厚度，使紧贴圆角弹窗顶缘的分隔线在 Retina 屏上也清晰可见。
        let lineHeight: CGFloat = 1
        topLine.frame = CGRect(x: 0, y: 0, width: bounds.width, height: lineHeight)
        bottomLine.frame = CGRect(x: 0, y: bounds.height - lineHeight, width: bounds.width, height: lineHeight)
    }

    @objc private func cancel() { cancelHandler?() }
    @objc private func confirm() { confirmHandler?() }
}
