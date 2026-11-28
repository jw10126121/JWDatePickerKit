import SwiftUI
import UIKit
import XCTest
@testable import JWDatePickerKit

/// 逐个公开 API 的接入测试，覆盖类型元数据、配置、滚轮、面板、控制器与 SwiftUI 入口。
@MainActor
final class JWDatePickerKitAPITests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func wheel(in view: UIView) -> UIPickerView? {
        if let picker = view as? UIPickerView { return picker }
        for child in view.subviews {
            if let picker = wheel(in: child) { return picker }
        }
        return nil
    }

    private func descendant<T: UIView>(_ type: T.Type, in view: UIView) -> T? {
        if let match = view as? T { return match }
        for child in view.subviews {
            if let match = descendant(type, in: child) { return match }
        }
        return nil
    }

    @discardableResult
    private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
        return condition()
    }

    // MARK: - JWDatePickerType / 本地化

    func testTypeMetadataCoversEveryCase() {
        let types = JWDatePickerType.allCases
        XCTAssertEqual(types.count, 14)
        XCTAssertEqual(Set(types.map(\.rawValue)).count, types.count)
        XCTAssertEqual(JWDatePickerType.dateAndTime, .dateWeekHourMinute)

        for type in types {
            XCTAssertGreaterThan(type.columnCount, 0, "\(type) 列数应大于 0")
            XCTAssertFalse(type.stringFormat.isEmpty, "\(type) 缺少格式")
            XCTAssertFalse(type.name.isEmpty)
            XCTAssertFalse(type.name.hasPrefix("mode."))
            XCTAssertFalse(type.localizedTitle().hasPrefix("title."))
            for identifier in ["en_US", "zh_CN", "ja_JP"] {
                let locale = Locale(identifier: identifier)
                XCTAssertFalse(type.localizedName(locale: locale).hasPrefix("mode."))
                XCTAssertFalse(type.localizedTitle(locale: locale).hasPrefix("title."))
            }
        }

        XCTAssertEqual(JWDatePickerType.time.stringFormat, "HH:mm")
        XCTAssertEqual(JWDatePickerType.dateHourMinuteSecond.columnCount, 6)
        XCTAssertEqual(JWDatePickerType.dateWeekHourMinute.columnCount, 3)

        for type in types {
            let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
            view.calendar = calendar
            view.type = type
            XCTAssertEqual(wheel(in: view)?.numberOfComponents, type.columnCount, "\(type) 实际列数不一致")
        }
    }

    func testLocalizationLookupAndFallback() {
        XCTAssertEqual(JWDatePickerLocalization.string("confirm", locale: Locale(identifier: "en_US")), "Done")
        XCTAssertEqual(JWDatePickerLocalization.string("cancel", locale: Locale(identifier: "en_US")), "Cancel")
        XCTAssertEqual(JWDatePickerLocalization.string("confirm", locale: Locale(identifier: "zh-Hans")), "确定")
        XCTAssertEqual(JWDatePickerLocalization.string("missing.key", locale: Locale(identifier: "en_US")), "missing.key")
    }

    // MARK: - JWDatePickerConfiguration

    func testConfigurationInitializersExposeBothLabels() {
        let empty = JWDatePickerConfiguration()
        XCTAssertEqual(empty.type, .date)
        XCTAssertNil(empty.selectedDate)
        XCTAssertNil(empty.selection)
        XCTAssertEqual(empty.calendar, .current)
        XCTAssertEqual(empty.locale, .current)
        switch empty.selectionPolicy {
        case .preserveComponents: break
        case .startOfDay: XCTFail("默认策略应为 preserveComponents")
        }

        let selected = date(2024, 2, 29, 12, 30)
        var configuration = JWDatePickerConfiguration(
            type: .dateHourMinute, selectedDate: selected,
            minimumDate: date(2020, 1, 1), maximumDate: date(2030, 1, 1), calendar: calendar
        )
        XCTAssertEqual(configuration.selection, selected)
        configuration.selection = date(2025, 1, 1)
        XCTAssertEqual(configuration.selectedDate, date(2025, 1, 1))

        let alternate = JWDatePickerConfiguration(
            type: .time, selection: selected,
            minimumDate: date(2020, 1, 1), maximumDate: date(2030, 1, 1),
            calendar: calendar, locale: Locale(identifier: "ja_JP"), selectionPolicy: .startOfDay
        )
        XCTAssertEqual(alternate.type, .time)
        XCTAssertEqual(alternate.selectedDate, selected)
        XCTAssertEqual(alternate.minimumDate, date(2020, 1, 1))
        XCTAssertEqual(alternate.maximumDate, date(2030, 1, 1))
        XCTAssertEqual(alternate.locale, Locale(identifier: "ja_JP"))
        switch alternate.selectionPolicy {
        case .startOfDay: break
        case .preserveComponents: XCTFail("策略未写入")
        }
    }

    func testInvalidConfigurationIsRejectedAtomically() {
        let view = JWDatePickerView()
        let invalid = JWDatePickerConfiguration(
            type: .time, selectedDate: date(2030, 1, 1),
            minimumDate: date(2030, 1, 1), maximumDate: date(2020, 1, 1)
        )
        XCTAssertThrowsError(try view.apply(invalid)) { error in
            XCTAssertEqual(error as? JWDatePickerConfigurationError, .invalidDateRange)
        }
        XCTAssertEqual(view.configurationError, .invalidDateRange)
        XCTAssertNil(view.maximumDate)
        XCTAssertNil(view.minimumDate)
    }

    // MARK: - JWDatePickerView

    func testViewPropertiesRoundTrip() {
        let view = JWDatePickerView()
        view.calendar = calendar
        view.locale = Locale(identifier: "en_US")
        view.type = .dateHourMinuteSecond
        let selected = date(2024, 5, 6, 7, 8)
        view.selection = selected
        view.minimumDate = date(2020, 1, 1)
        view.maximumDate = date(2030, 1, 1)
        view.selectionPolicy = .startOfDay

        XCTAssertEqual(view.type, .dateHourMinuteSecond)
        XCTAssertEqual(view.currentSelection(), selected)
        XCTAssertEqual(view.currentSelectedDate(), selected)
        XCTAssertGreaterThan(view.pickerViewHeight, 0)
        XCTAssertEqual(view.intrinsicContentSize.height, view.pickerViewHeight)

        let configuration = view.configuration
        XCTAssertEqual(configuration.type, .dateHourMinuteSecond)
        XCTAssertEqual(configuration.selectedDate, selected)
        XCTAssertEqual(configuration.minimumDate, date(2020, 1, 1))
        XCTAssertEqual(configuration.maximumDate, date(2030, 1, 1))
        XCTAssertEqual(configuration.calendar, calendar)
        XCTAssertEqual(configuration.locale, Locale(identifier: "en_US"))
        switch configuration.selectionPolicy {
        case .startOfDay: break
        case .preserveComponents: XCTFail("selectionPolicy 未写入")
        }

        // 越界选择会被夹紧到范围内。
        view.selection = date(2010, 1, 1)
        XCTAssertEqual(view.currentSelection(), date(2020, 1, 1))
        view.selection = date(2040, 1, 1)
        XCTAssertEqual(view.currentSelection(), date(2030, 1, 1))
    }

    func testViewDataSourceAndDelegateSurface() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        view.calendar = calendar
        view.selection = date(2024, 5, 12, 13, 24)
        let picker = try XCTUnwrap(wheel(in: view))

        XCTAssertEqual(view.numberOfComponents(in: picker), 3)
        for component in 0..<3 {
            XCTAssertGreaterThan(view.pickerView(picker, numberOfRowsInComponent: component), 0)
            XCTAssertEqual(view.pickerView(picker, rowHeightForComponent: component), view.rowHeight)
            XCTAssertGreaterThan(view.pickerView(picker, widthForComponent: component), 0)
        }
        XCTAssertEqual(view.pickerView(picker, numberOfRowsInComponent: -1), 0)
        XCTAssertEqual(view.pickerView(picker, numberOfRowsInComponent: 3), 0)

        let widths = (0..<3).map { view.pickerView(picker, widthForComponent: $0) }
        XCTAssertLessThanOrEqual(widths.reduce(0, +), 390)

        view.columnWidth = { component, _ in CGFloat(60 + component) }
        XCTAssertEqual(view.pickerView(picker, widthForComponent: 2), 62)
        view.columnWidth = { _, _ in 1_000 }
        XCTAssertEqual(view.pickerView(picker, widthForComponent: 0), 390)

        let row = view.pickerView(picker, viewForRow: 0, forComponent: 0, reusing: nil)
        XCTAssertEqual(row.subviews.compactMap { $0 as? UILabel }.count, 2)
        XCTAssertFalse(row.accessibilityLabel?.isEmpty ?? true)
    }

    func testViewCallbacksLoopingAndCommit() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        view.calendar = calendar
        view.type = .dateHourMinute
        view.selection = date(2024, 5, 12, 13, 24)
        let picker = try XCTUnwrap(wheel(in: view))

        var changes = [Date]()
        view.onSelectionChanged = { changes.append($0) }
        let nextYear = picker.selectedRow(inComponent: 0) + 1
        picker.selectRow(nextYear, inComponent: 0, animated: false)
        view.pickerView(picker, didSelectRow: nextYear, inComponent: 0)
        XCTAssertEqual(changes, [date(2025, 5, 12, 13, 24)])
        XCTAssertEqual(view.currentSelectedDate(), date(2025, 5, 12, 13, 24))
        XCTAssertEqual(view.commitSelection(), date(2025, 5, 12, 13, 24))

        // onDateChanged 与 onSelectionChanged 是同一存储。
        var alias = [Date]()
        view.onDateChanged = { alias.append($0) }
        XCTAssertNotNil(view.onSelectionChanged, "onDateChanged 与 onSelectionChanged 应共用存储")
        let row = picker.selectedRow(inComponent: 1) + 1
        picker.selectRow(row, inComponent: 1, animated: false)
        view.pickerView(picker, didSelectRow: row, inComponent: 1)
        XCTAssertEqual(alias.count, 1)
        XCTAssertEqual(alias.first, view.currentSelection())

        XCTAssertFalse(view.isLooping(for: .hour))
        view.setLooping(true, for: .hour)
        XCTAssertTrue(view.isLooping(for: .hour))
        XCTAssertTrue(view.loopingComponents.contains(.hour))
        XCTAssertEqual(picker.numberOfRows(inComponent: 3), 10_000)
        view.setLooping(false, for: .hour)
        XCTAssertFalse(view.isLooping(for: .hour))

        // 越界行不会触发选择回调。
        view.pickerView(picker, didSelectRow: 9_999, inComponent: 0)
        XCTAssertEqual(alias.count, 1)
    }

    func testViewInvalidRowsAndAppearanceKeysAreHandled() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        view.calendar = calendar
        view.rowHeight = 60
        view.rowHeight = -1
        XCTAssertEqual(view.rowHeight, 60)
        view.rowHeight = .nan
        XCTAssertEqual(view.rowHeight, 60)

        view.textAttributes = [.font: UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.systemGray]
        view.selectedAttributes = nil
        XCTAssertEqual(view.textAttributes[.font] as? UIFont, .systemFont(ofSize: 20))
        XCTAssertNil(view.selectedAttributes)

        view.lineColor = .systemRed
        let lines = view.subviews.filter { type(of: $0) == UIView.self }
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines.allSatisfy { $0.backgroundColor == .systemRed })

        let picker = try XCTUnwrap(wheel(in: view))
        let row = view.pickerView(picker, viewForRow: 0, forComponent: 0, reusing: nil)
        let labels = row.subviews.compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.first?.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor,
                       .systemGray)
    }

    func testReloadDatasPicksUpPropertyChanges() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        view.calendar = calendar
        view.selection = date(2024, 5, 12)
        view.type = .time
        view.reloadDatas()
        XCTAssertNil(view.configurationError)
        let picker = try XCTUnwrap(wheel(in: view))
        XCTAssertEqual(picker.numberOfComponents, 2)
        XCTAssertEqual(view.currentSelection(), date(2024, 5, 12))
    }

    // MARK: - JWDatePickerMenuHeaderView

    func testHeaderViewTitlesLocalizationAndCallbacks() throws {
        let header = JWDatePickerMenuHeaderView(frame: CGRect(x: 0, y: 0, width: 390, height: 56))
        header.locale = Locale(identifier: "en_US")
        header.type = .dateHourMinute
        XCTAssertEqual(header.cancelTitle, "Cancel")
        XCTAssertEqual(header.confirmTitle, "Done")
        XCTAssertEqual(button(in: header, titled: "Cancel") != nil, true)
        XCTAssertEqual(button(in: header, titled: "Done") != nil, true)

        let title = try XCTUnwrap(header.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(title.text, "Choose date and time")

        header.cancelTitle = "Back"
        header.confirmTitle = "OK"
        let cancel = try XCTUnwrap(button(in: header, titled: "Back"))
        let confirm = try XCTUnwrap(button(in: header, titled: "OK"))

        header.cancelNormalColor = .systemRed
        header.cancelHighlightedColor = .systemOrange
        header.confirmNormalColor = .systemBlue
        header.confirmHighlightedColor = .systemGreen
        header.cancelFont = .systemFont(ofSize: 13)
        header.confirmFont = .boldSystemFont(ofSize: 19)
        XCTAssertEqual(cancel.titleColor(for: .normal), .systemRed)
        XCTAssertEqual(cancel.titleColor(for: .highlighted), .systemOrange)
        XCTAssertEqual(confirm.titleColor(for: .normal), .systemBlue)
        XCTAssertEqual(confirm.titleColor(for: .highlighted), .systemGreen)
        XCTAssertEqual(cancel.titleLabel?.font.pointSize, 13)
        XCTAssertEqual(confirm.titleLabel?.font.pointSize, 19)

        var cancelled = 0
        var confirmed = 0
        header.cancelHandler = { cancelled += 1 }
        header.confirmHandler = { confirmed += 1 }
        cancel.sendActions(for: .touchUpInside)
        confirm.sendActions(for: .touchUpInside)
        XCTAssertEqual(cancelled, 1)
        XCTAssertEqual(confirmed, 1)

        header.attributedTitle = NSAttributedString(string: "Custom")
        XCTAssertEqual(title.attributedText?.string, "Custom")
        header.type = .time
        XCTAssertEqual(title.attributedText?.string, "Custom")
        header.attributedTitle = nil
        XCTAssertEqual(title.text, "Choose time")
    }

    func testHeaderSeparatorsInsetsAndRightToLeft() throws {
        let header = JWDatePickerMenuHeaderView(frame: CGRect(x: 0, y: 0, width: 390, height: 56))
        header.locale = Locale(identifier: "en_US")
        header.cancelTitle = "Back"
        header.confirmTitle = "OK"
        header.horizontalInset = 20
        header.lineColor = .systemRed
        header.showsTopLine = true
        header.showsBottomLine = true
        header.layoutIfNeeded()

        let lines = header.subviews.filter { type(of: $0) == UIView.self }
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines.allSatisfy { !$0.isHidden && $0.backgroundColor == .systemRed })
        XCTAssertEqual(lines.map(\.frame.height), [1, 1])

        let cancel = try XCTUnwrap(button(in: header, titled: "Back"))
        let confirm = try XCTUnwrap(button(in: header, titled: "OK"))
        XCTAssertEqual(cancel.frame.minX, 20)
        XCTAssertEqual(confirm.frame.maxX, 370)
        XCTAssertGreaterThanOrEqual(confirm.bounds.width, 44)

        header.showsTopLine = false
        XCTAssertTrue(lines[0].isHidden)
        XCTAssertFalse(lines[1].isHidden)

        header.locale = Locale(identifier: "ar")
        header.layoutIfNeeded()
        XCTAssertEqual(header.semanticContentAttribute, .forceRightToLeft)
        XCTAssertGreaterThan(cancel.frame.minX, confirm.frame.minX)
    }

    private func button(in header: UIView, titled title: String) -> UIButton? {
        header.subviews.compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == title }
    }

    // MARK: - JWDatePickerContentView

    func testContentViewAppliesConfigurationAndLayout() throws {
        let content = JWDatePickerContentView(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        try content.apply(JWDatePickerConfiguration(
            type: .dateHourMinute, selectedDate: date(2024, 5, 12, 13, 24), calendar: calendar
        ))
        XCTAssertEqual(content.pickerView.type, .dateHourMinute)
        XCTAssertEqual(content.headerView.type, .dateHourMinute)
        XCTAssertEqual(content.headerView.locale, .current)

        content.headerHeight = 56
        content.pickerHeight = 200
        content.includesBottomSafeArea = false
        content.layoutIfNeeded()
        XCTAssertEqual(content.headerView.frame.height, 56)
        XCTAssertEqual(content.pickerView.frame.minY, 56)
        XCTAssertEqual(content.pickerView.frame.height, 200)
        XCTAssertEqual(content.intrinsicContentSize.height, 256)

        content.headerHeight = 10
        content.pickerHeight = 0
        XCTAssertEqual(content.headerHeight, 56)
        XCTAssertEqual(content.pickerHeight, 200)
    }

    func testContentViewResultLifecycle() throws {
        let content = JWDatePickerContentView()
        let selected = date(2024, 5, 12, 13, 24)
        try content.apply(JWDatePickerConfiguration(selectedDate: selected, calendar: calendar))
        var results = [JWDatePickerResult]()
        content.onResult = { results.append($0) }

        content.confirmSelection()
        content.confirmSelection()
        XCTAssertEqual(results.count, 1)
        guard case let .confirmed(value) = content.result else { return XCTFail("缺少确认结果") }
        XCTAssertEqual(value, selected)

        content.beginSelection()
        XCTAssertNil(content.result)
        content.cancelSelection()
        XCTAssertEqual(results.count, 2)
        guard case .cancelled = content.result else { return XCTFail("缺少取消结果") }
    }

    // MARK: - JWDatePickerViewController

    func testViewControllerProxiesAndAppearance() throws {
        let controller = JWDatePickerViewController()
        try controller.apply(JWDatePickerConfiguration(
            type: .dateHourMinute, selectedDate: date(2024, 5, 12, 13, 24),
            minimumDate: date(2020, 1, 1), maximumDate: date(2030, 1, 1), calendar: calendar
        ))
        XCTAssertEqual(controller.type, .dateHourMinute)
        XCTAssertEqual(controller.selection, date(2024, 5, 12, 13, 24))
        XCTAssertEqual(controller.minimumDate, date(2020, 1, 1))
        XCTAssertEqual(controller.maximumDate, date(2030, 1, 1))
        XCTAssertEqual(controller.currentSelection(), date(2024, 5, 12, 13, 24))

        controller.type = .time
        XCTAssertEqual(controller.pickerView.type, .time)
        controller.type = .dateHourMinute
        controller.minimumDate = nil
        controller.maximumDate = nil
        controller.selection = date(2024, 6, 1, 8, 30)
        XCTAssertEqual(controller.commitSelection(), date(2024, 6, 1, 8, 30))

        controller.lineBackgroundColor = .systemRed
        XCTAssertEqual(controller.pickerView.lineColor, .systemRed)
        controller.textColorOfSelectedRow = .systemPink
        XCTAssertEqual(controller.textColorOfSelectedRow, .systemPink)
        controller.textColorOfOtherRow = .brown
        XCTAssertEqual(controller.textColorOfOtherRow, .brown)

        XCTAssertTrue(controller.backgroundTapDismissEnable)
        XCTAssertFalse(controller.automaticallyDismisses)
        XCTAssertEqual(controller.dimmingColor.cgColor.alpha, 0.25, accuracy: 0.01)

        controller.topCornerRadius = 12
        controller.loadViewIfNeeded()
        XCTAssertEqual(controller.view.layer.cornerRadius, 12)
        XCTAssertEqual(controller.view.layer.maskedCorners, [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }

    func testViewControllerCallbacksAndResult() throws {
        let controller = JWDatePickerViewController()
        let selected = date(2024, 5, 12, 13, 24)
        try controller.apply(JWDatePickerConfiguration(selectedDate: selected, calendar: calendar))
        var events = [String]()
        var components: DateComponents?
        controller.confirmHandler = { _ in events.append("confirm") }
        controller.confirmDateComponentsHandler = { components = $0; events.append("components") }
        controller.onResult = { result in
            switch result {
            case .confirmed: events.append("result")
            case .cancelled: events.append("cancelled")
            }
        }
        controller.contentView.beginSelection()
        controller.contentView.confirmSelection()
        XCTAssertEqual(events, ["confirm", "components", "result"])
        XCTAssertEqual(components?.year, 2024)
        XCTAssertEqual(components?.minute, 24)

        controller.contentView.beginSelection()
        controller.cancelHandler = { events.append("cancel") }
        controller.contentView.cancelSelection()
        XCTAssertEqual(Array(events.suffix(2)), ["cancel", "cancelled"])
    }

    // MARK: - SwiftUI

    func testSwiftUIInlinePickerEmbedsConfiguredView() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let selected = date(2024, 5, 12, 13, 24)
        let host = UIHostingController(rootView: JWDatePicker(
            selection: .constant(selected), type: .dateHourMinute,
            minimumDate: date(2020, 1, 1), maximumDate: date(2030, 1, 1),
            calendar: calendar, locale: Locale(identifier: "en_US")
        ))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()

        waitUntil { self.descendant(JWDatePickerView.self, in: host.view) != nil }
        guard let picker = descendant(JWDatePickerView.self, in: host.view) else {
            return XCTFail("SwiftUI 未创建 JWDatePickerView")
        }
        XCTAssertEqual(picker.type, .dateHourMinute)
        XCTAssertEqual(picker.calendar, calendar)
        XCTAssertEqual(picker.locale, Locale(identifier: "en_US"))
        XCTAssertEqual(picker.minimumDate, date(2020, 1, 1))
        XCTAssertEqual(picker.maximumDate, date(2030, 1, 1))
        XCTAssertEqual(picker.currentSelection(), selected)
    }

    func testSwiftUIModifierPresentsAndConfirms() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let host = UIHostingController(rootView: Color.clear
            .frame(width: 10, height: 10)
            .jwDatePicker(isPresented: .constant(true), selection: .constant(date(2024, 5, 12)), type: .time))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()

        let presented = waitUntil { host.presentedViewController is JWDatePickerViewController }
        XCTAssertTrue(presented, "jwDatePicker 未呈现控制器")
        guard let controller = host.presentedViewController as? JWDatePickerViewController else { return }
        XCTAssertEqual(controller.type, .time)
        XCTAssertEqual(controller.selection, date(2024, 5, 12))
        controller.contentView.confirmSelection()
    }
}
