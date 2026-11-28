import UIKit
import JWDatePickerKit

final class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 供自动化截图使用：launch 时传 -autoOpenPicker 自动打开生日选择器
        if ProcessInfo.processInfo.arguments.contains("-autoOpenPicker") {
            showBirthdayPicker()
        }
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

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        modes.count + 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.row == 0 {
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
                type: modes[indexPath.row - 2], selection: Date(), calendar: calendar, locale: locale
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
                type: .dateHourMinute, selection: Date(), calendar: calendar, locale: locale
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
        controller.headerView.attributedTitle = NSAttributedString(
            string: controller.type.localizedTitle(locale: locale),
            attributes: [.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: UIColor.label]
        )
    }

    private func showBirthdayPicker() {
        let controller = JWDatePickerViewController()
        let configuration = JWDatePickerConfiguration(
            type: .date, selection: birthday ?? Date(),
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
