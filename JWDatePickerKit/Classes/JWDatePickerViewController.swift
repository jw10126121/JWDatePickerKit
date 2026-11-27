import UIKit
import XBDialog

/// 底部日期弹层，也可通过 contentView 访问完整面板配置。
@objc public class JWDatePickerViewController: UIViewController {
    public let contentView = JWDatePickerContentView()
    public var pickerView: JWDatePickerView { contentView.pickerView }
    public var headerView: JWDatePickerMenuHeaderView { contentView.headerView }

    @objc public var backgoundTapDismissEnable = true
    /// 默认保持旧版按钮回调行为。开启后，确认和取消会自动关闭弹层。
    @objc public var automaticallyDismisses = false
    @objc public var cancelHandler: (() -> Void)?
    @objc public var confirmHandler: ((Date) -> Void)?
    @objc public var confirmDateComponentsHandler: ((DateComponents) -> Void)?
    public var onResult: ((JWDatePickerResult) -> Void)?
    @objc public var topCornerRadius: CGFloat = 0 { didSet { updateCorners() } }
    @objc public var dimmingColor: UIColor = UIColor.black.withAlphaComponent(0.25)
    @objc public var datePickerMode: JWDatePickerType {
        get { pickerView.type }
        set { pickerView.type = newValue }
    }
    @objc public var defaultDate: Date {
        get { pickerView.currentSelectedDate() ?? Date() }
        set { pickerView.selectDate = newValue }
    }
    @objc public var minimumDate: Date? {
        get { pickerView.minimumDate }
        set { pickerView.minimumDate = newValue }
    }
    @objc public var maximumDate: Date? {
        get { pickerView.maximumDate }
        set { pickerView.maximumDate = newValue }
    }
    @objc public dynamic var lineBackgroundColor: UIColor {
        get { pickerView.lineColor }
        set { pickerView.lineColor = newValue }
    }
    @objc public dynamic var textColorOfSelectedRow: UIColor {
        get { pickerView.selectedAttributes?[.foregroundColor] as? UIColor ?? .label }
        set {
            var attributes = pickerView.selectedAttributes ?? pickerView.textAttributes
            attributes[.foregroundColor] = newValue
            pickerView.selectedAttributes = attributes
        }
    }
    @objc public dynamic var textColorOfOtherRow: UIColor {
        get { pickerView.textAttributes[.foregroundColor] as? UIColor ?? .label }
        set { pickerView.textAttributes[.foregroundColor] = newValue }
    }

    private var sheetTransition: DatePickerSheetTransition!
    private var closesForBackdrop = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        sheetTransition = DatePickerSheetTransition(self)
        transitioningDelegate = sheetTransition
        contentView.onResult = { [weak self] result in self?.handle(result) }
        pickerView.lineColor = .black
    }

    public func apply(_ configuration: JWDatePickerConfiguration) throws {
        try contentView.apply(configuration)
    }

    public override func loadView() {
        view = contentView
        updateCorners()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isBeingPresented { contentView.beginSelection() }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if presentingViewController == nil { contentView.cancelSelection() }
    }

    private func updateCorners() {
        contentView.layer.cornerRadius = max(0, topCornerRadius)
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true
    }

    fileprivate func dismissFromBackdrop() {
        guard backgoundTapDismissEnable else { return }
        closesForBackdrop = true
        contentView.cancelSelection()
        closesForBackdrop = false
        if presentingViewController != nil && !isBeingDismissed { dismiss(animated: true) }
    }

    private func handle(_ result: JWDatePickerResult) {
        let resultHandler = onResult
        let cancel = cancelHandler
        let confirm = confirmHandler
        let componentsHandler = confirmDateComponentsHandler
        let shouldDismiss = automaticallyDismisses || closesForBackdrop
        switch result {
        case .confirmed(let date):
            let components = pickerView.calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            confirm?(date)
            componentsHandler?(components)
        case .cancelled:
            cancel?()
        }
        resultHandler?(result)
        if shouldDismiss && presentingViewController != nil && !isBeingDismissed { dismiss(animated: true) }
    }
}

/// 复用 XBDialog 的转场动画，布局从本次呈现的容器读取安全区。
@MainActor
private final class DatePickerSheetTransition: NSObject, UIViewControllerTransitioningDelegate {
    private let animator: XBPresentAnimator
    private let config: MenuConfig

    init(_ controller: JWDatePickerViewController) {
        animator = XBPresentAnimator(controller)
        animator.menu { config in
            config.menuType = .bottomHeight(h: controller.contentView.headerHeight + controller.contentView.pickerHeight)
        }
        config = animator.config as! MenuConfig
        super.init()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        DatePickerSheetPresentation(presentedViewController: presented, presenting: presenting, config: config)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.animationController(forPresented: presented, presenting: presenting, source: source)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.animationController(forDismissed: dismissed)
    }
}

@MainActor
private final class DatePickerSheetPresentation: UIPresentationController {
    private let config: MenuConfig
    private let maskView = UIView()
    private var pickerController: JWDatePickerViewController { presentedViewController as! JWDatePickerViewController }

    init(presentedViewController: UIViewController, presenting: UIViewController?, config: MenuConfig) {
        self.config = config
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        maskView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedBackdrop)))
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        let content = pickerController.contentView
        let bottom = content.includesBottomSafeArea ? containerView.safeAreaInsets.bottom : 0
        let height = min(containerView.bounds.height, content.headerHeight + content.pickerHeight + bottom)
        config.menuType = .bottomHeight(h: height)
        return CGRect(x: 0, y: containerView.bounds.height - height, width: containerView.bounds.width, height: height)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        maskView.frame = containerView?.bounds ?? .zero
        let frame = frameOfPresentedViewInContainerView
        presentedView?.bounds.size = frame.size
        presentedView?.center = CGPoint(x: frame.midX, y: frame.midY)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        maskView.backgroundColor = pickerController.dimmingColor
        maskView.alpha = 1
        containerView?.insertSubview(maskView, at: 0)
        if let coordinator = presentedViewController.transitionCoordinator {
            maskView.alpha = 0
            coordinator.animate(alongsideTransition: { _ in self.maskView.alpha = 1 })
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in self.maskView.alpha = 0 })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed { maskView.removeFromSuperview() }
    }

    @objc private func tappedBackdrop() { pickerController.dismissFromBackdrop() }
}
