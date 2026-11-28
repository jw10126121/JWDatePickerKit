import UIKit

public enum JWDatePickerResult {
    case confirmed(Date)
    case cancelled
}

/// 头部、滚轮和底部安全区组成的面板，可嵌入业务方的弹层容器。
public final class JWDatePickerContentView: UIView {
    public let pickerView = JWDatePickerView()
    public let headerView = JWDatePickerMenuHeaderView()
    public var headerHeight: CGFloat = 50 {
        didSet {
            if !headerHeight.isFinite || headerHeight < 44 { headerHeight = oldValue }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    public var pickerHeight: CGFloat = 250 {
        didSet {
            if !pickerHeight.isFinite || pickerHeight <= 0 { pickerHeight = oldValue }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    public var includesBottomSafeArea = true {
        didSet { invalidateIntrinsicContentSize(); setNeedsLayout() }
    }
    /// 每次 beginSelection 后只发送一次最终结果。
    public var onResult: ((JWDatePickerResult) -> Void)?
    public private(set) var result: JWDatePickerResult?
    var onFinish: ((JWDatePickerResult) -> Void)?

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
        addSubview(headerView)
        addSubview(pickerView)
        pickerView.onConfigurationChanged = { [weak self] in
            guard let self else { return }
            self.headerView.locale = self.pickerView.locale
            self.headerView.type = self.pickerView.type
        }
        headerView.locale = pickerView.locale
        headerView.type = pickerView.type
        headerView.cancelHandler = { [weak self] in self?.cancelSelection() }
        headerView.confirmHandler = { [weak self] in self?.confirmSelection() }
    }

    public func apply(_ configuration: JWDatePickerConfiguration) throws {
        try pickerView.apply(configuration)
    }

    /// 重用嵌入式面板时，在开始新一轮选择前调用。
    public func beginSelection() { result = nil }

    public func confirmSelection() {
        guard result == nil else { return }
        finish(.confirmed(pickerView.commitSelection()))
    }

    public func cancelSelection() {
        guard result == nil else { return }
        finish(.cancelled)
    }

    private func finish(_ result: JWDatePickerResult) {
        self.result = result
        let resultHandler = onResult
        onFinish?(result)
        resultHandler?(result)
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: headerHeight + pickerHeight + (includesBottomSafeArea ? safeAreaInsets.bottom : 0))
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let bottom = includesBottomSafeArea ? safeAreaInsets.bottom : 0
        let availablePickerHeight = max(0, bounds.height - headerHeight - bottom)
        headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: headerHeight)
        pickerView.frame = CGRect(x: safeAreaInsets.left, y: headerHeight,
                                  width: max(0, bounds.width - safeAreaInsets.left - safeAreaInsets.right), height: min(pickerHeight, availablePickerHeight))
    }
}
