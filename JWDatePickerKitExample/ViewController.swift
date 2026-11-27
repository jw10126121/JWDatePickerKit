import UIKit
import JWDatePickerKit
import XBDialog

final class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    fileprivate enum DialogDemo: Int, CaseIterable {
        case centeredFade
        case centeredScale
        case centeredSlide
        case bottomSheet
        case leftMenu
        case rightMenu

        var titleKey: String {
            switch self {
            case .centeredFade: return "dialog.centeredFade"
            case .centeredScale: return "dialog.centeredScale"
            case .centeredSlide: return "dialog.centeredSlide"
            case .bottomSheet: return "dialog.bottomSheet"
            case .leftMenu: return "dialog.leftMenu"
            case .rightMenu: return "dialog.rightMenu"
            }
        }

        var detailKey: String {
            switch self {
            case .centeredFade: return "dialog.centeredFade.detail"
            case .centeredScale: return "dialog.centeredScale.detail"
            case .centeredSlide: return "dialog.centeredSlide.detail"
            case .bottomSheet: return "dialog.bottomSheet.detail"
            case .leftMenu: return "dialog.leftMenu.detail"
            case .rightMenu: return "dialog.rightMenu.detail"
            }
        }
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let modes = JWDatePickerType.allCases
    private var birthday: Date?
    private var birthdayWasCancelled = false
    private var locale: Locale { .current }
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = JWDatePickerLocalization.string("picker", locale: locale)
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? modes.count + 2 : DialogDemo.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? JWDatePickerLocalization.string("dialog.section", locale: locale) : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 1 {
            let demo = DialogDemo(rawValue: indexPath.row)!
            cell.textLabel?.text = JWDatePickerLocalization.string(demo.titleKey, locale: locale)
            cell.detailTextLabel?.text = JWDatePickerLocalization.string(demo.detailKey, locale: locale)
        } else if indexPath.row == 0 {
            cell.textLabel?.text = JWDatePickerLocalization.string("birthday", locale: locale)
        } else if indexPath.row == 1 {
            cell.textLabel?.text = JWDatePickerLocalization.string("loopingDemo", locale: locale)
        } else {
            cell.textLabel?.text = modes[indexPath.row - 2].localizedName(locale: locale)
        }
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        if indexPath.row == 0 {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate("yMMMd")
            cell.detailTextLabel?.text = birthday.map(formatter.string(from:))
                ?? JWDatePickerLocalization.string(birthdayWasCancelled ? "cancelled" : "notSet", locale: locale)
        } else if indexPath.row == 1 {
            cell.detailTextLabel?.text = JWDatePickerLocalization.string("loopingDemoDetail", locale: locale)
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let demo = DialogDemo(rawValue: indexPath.row)!
            showDialogDemo(demo)
            return
        }
        if indexPath.row == 0 {
            showBirthdayPicker()
            return
        }
        if indexPath.row == 1 {
            showLoopingPicker()
            return
        }
        let controller = JWDatePickerViewController()
        do {
            try controller.apply(JWDatePickerConfiguration(
                type: modes[indexPath.row - 2], selectedDate: Date(), calendar: calendar, locale: locale
            ))
        } catch {
            assertionFailure("Invalid picker configuration \(error)")
            return
        }
        configureAppearance(of: controller)
        controller.confirmHandler = { date in print(date) }
        present(controller, animated: true)
    }

    private func showLoopingPicker() {
        let controller = JWDatePickerViewController()
        do {
            try controller.apply(JWDatePickerConfiguration(
                type: .dateHourMinute, selectedDate: Date(), calendar: calendar, locale: locale
            ))
        } catch {
            assertionFailure("Invalid looping picker configuration \(error)")
            return
        }
        controller.pickerView.loopingComponents = [.hour, .minute]
        configureAppearance(of: controller)
        controller.confirmHandler = { date in print("Looping picker date:", date) }
        present(controller, animated: true)
    }

    private func configureAppearance(of controller: JWDatePickerViewController) {
        controller.automaticallyDismisses = true
        controller.topCornerRadius = 24
        let titleFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 16, weight: .medium))
        controller.contentView.headerHeight = max(56, titleFont.lineHeight * 2 + 12)
        controller.headerView.attributedTitle = NSAttributedString(
            string: controller.datePickerMode.localizedTitle(locale: locale),
            attributes: [.font: titleFont, .foregroundColor: UIColor.label]
        )
        let buttonFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 16))
        controller.headerView.cancelFont = buttonFont
        controller.headerView.confirmFont = buttonFont
        controller.headerView.cancelNormalColor = .secondaryLabel
        controller.headerView.confirmNormalColor = UIColor(red: 0, green: 0.65, blue: 0.6, alpha: 1)
        controller.headerView.showsTopLine = false
        controller.headerView.showsBottomLine = false
        let count = controller.datePickerMode.section
        let size: CGFloat = count <= 3 ? 22 : (count <= 5 ? 18 : 17)
        let font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: size), maximumPointSize: 28)
        controller.pickerView.rowHeight = max(40, font.lineHeight + 12)
        controller.contentView.pickerHeight = max(216, controller.pickerView.rowHeight * 5)
        controller.pickerView.textAttributes = [.font: font, .foregroundColor: UIColor.label]
        controller.pickerView.lineColor = .clear
    }

    private func showDialogDemo(_ demo: DialogDemo) {
        let controller = XBDialogDemoViewController(demo: demo)
        let animator = controller.xb.present
        let backdropTap = controller.makeBackdropTapGesture()

        switch demo {
        case .centeredFade:
            animator.dialog { (config: DialogConfig) in
                config.dialogType = .preferSize
                config.animateType = .alpha(from: 0, to: 1)
                config.duration = 0.35
                config.isShowMask = true
                config.gestureRecognizer = backdropTap
            }
        case .centeredScale:
            animator.dialog { (config: DialogConfig) in
                config.dialogType = .size(s: CGSize(width: min(UIScreen.main.bounds.width - 48, 340), height: 250))
                config.animateType = .scale(from: 0.8, to: 1)
                config.duration = 0.42
                config.damping = 0.78
                config.springVelocity = 0.6
                config.presentingScale = 0.94
                config.blurEffectStyle = .systemMaterial
                config.gestureRecognizer = backdropTap
            }
        case .centeredSlide:
            animator.dialog { (config: DialogConfig) in
                config.dialogType = .preferSize
                config.animateType = .direction(type: .top)
                config.duration = 0.3
                config.isShowMask = true
                config.gestureRecognizer = backdropTap
            }
        case .bottomSheet:
            animator.menu { (config: MenuConfig) in
                config.menuType = .bottomHeightFromViewRate(rate: 0.48)
                config.isDraggable = true
                config.damping = 0.82
                config.springVelocity = 0.4
                config.presentingScale = 0.97
                config.blurEffectStyle = .systemMaterial
                config.gestureRecognizer = backdropTap
            }
        case .leftMenu:
            animator.menu { (config: MenuConfig) in
                config.menuType = .leftWidthFromViewRate(rate: 0.78)
                config.isDraggable = true
                config.duration = 0.35
                config.blurEffectStyle = .systemMaterial
                config.gestureRecognizer = backdropTap
            }
        case .rightMenu:
            animator.menu { (config: MenuConfig) in
                config.menuType = .rightWidth(w: min(UIScreen.main.bounds.width - 56, 320))
                config.isDraggable = true
                config.duration = 0.35
                config.presentingScale = 0.96
                config.isShowMask = true
                config.gestureRecognizer = backdropTap
            }
        }

        present(controller, animated: true)
    }

    private func showBirthdayPicker() {
        let controller = JWDatePickerViewController()
        let configuration = JWDatePickerConfiguration(
            type: .date, selectedDate: birthday ?? Date(),
            minimumDate: calendar.date(from: DateComponents(year: 1940, month: 1, day: 1)),
            maximumDate: Date(), calendar: calendar, locale: locale,
            selectionPolicy: .startOfDay
        )
        do {
            try controller.apply(configuration)
        } catch {
            assertionFailure("Invalid birthday configuration \(error)")
            return
        }
        configureAppearance(of: controller)
        controller.confirmHandler = { [weak self] date in
            guard let self else { return }
            self.birthday = date
            self.tableView.reloadData()
        }
        controller.cancelHandler = { [weak self] in
            guard let self else { return }
            if self.birthday == nil { self.birthdayWasCancelled = true }
            self.tableView.reloadData()
        }
        present(controller, animated: true)
    }
}

private final class XBDialogDemoViewController: UIViewController {
    private let demo: ViewController.DialogDemo
    private lazy var backdropDismissTarget = BackdropDismissTarget(viewController: self)

    init(demo: ViewController.DialogDemo) {
        self.demo = demo
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: min(UIScreen.main.bounds.width - 48, 340), height: 250)
        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeBackdropTapGesture() -> UITapGestureRecognizer {
        UITapGestureRecognizer(target: backdropDismissTarget, action: #selector(BackdropDismissTarget.dismiss))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 22
        view.clipsToBounds = true

        let title = UILabel()
        title.text = JWDatePickerLocalization.string(demo.titleKey)
        title.font = .preferredFont(forTextStyle: .title2)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0

        let detail = UILabel()
        detail.text = JWDatePickerLocalization.string(demo.detailKey)
        detail.font = .preferredFont(forTextStyle: .body)
        detail.textColor = .secondaryLabel
        detail.adjustsFontForContentSizeCategory = true
        detail.numberOfLines = 0

        let closeButton = UIButton(type: .system)
        closeButton.setTitle(JWDatePickerLocalization.string("dialog.close"), for: .normal)
        closeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        closeButton.backgroundColor = .tintColor
        closeButton.tintColor = .white
        closeButton.layer.cornerRadius = 12
        closeButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, detail, closeButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

@MainActor
private final class BackdropDismissTarget: NSObject {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    @objc func dismiss() {
        viewController?.dismiss(animated: true)
    }
}
