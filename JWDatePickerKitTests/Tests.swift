import XCTest
import UIKit
@testable import JWDatePickerKit

@MainActor
final class Tests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func wheel(_ view: UIView) -> UIPickerView {
        if let picker = view as? UIPickerView { return picker }
        for child in view.subviews {
            if let picker = findWheel(child) { return picker }
        }
        fatalError("Picker missing")
    }

    private func findWheel(_ view: UIView) -> UIPickerView? {
        if let picker = view as? UIPickerView { return picker }
        for child in view.subviews {
            if let picker = findWheel(child) { return picker }
        }
        return nil
    }

    func testAllModesAndDefaultDate() {
        let date = self.date(2024, 2, 29, 12, 30)
        for type in JWDatePickerType.allCases {
            let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
            view.calendar = calendar
            view.type = type
            view.selection = date
            XCTAssertEqual(view.currentSelectedDate(), date)
            let picker = wheel(view)
            XCTAssertEqual(picker.numberOfComponents, type.columnCount)
            for component in 0..<picker.numberOfComponents {
                XCTAssertGreaterThan(picker.numberOfRows(inComponent: component), 0)
            }
        }
    }

    func testAllModesStayWithinRangeWhenSelectingRows() {
        let minimum = date(2024, 2, 28, 10, 20)
        let maximum = date(2024, 3, 2, 14, 40)
        for type in JWDatePickerType.allCases {
            let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
            view.calendar = calendar
            view.type = type
            view.minimumDate = minimum
            view.maximumDate = maximum
            view.selection = date(2024, 2, 29, 12, 30)
            let picker = wheel(view)
            for component in 0..<picker.numberOfComponents {
                let row = picker.numberOfRows(inComponent: component) - 1
                XCTAssertGreaterThanOrEqual(row, 0)
                picker.selectRow(row, inComponent: component, animated: false)
                view.pickerView(picker, didSelectRow: row, inComponent: component)
                let selected = view.currentSelectedDate()!
                XCTAssertGreaterThanOrEqual(selected, minimum)
                XCTAssertLessThanOrEqual(selected, maximum)
            }
        }
    }

    func testBoundsCanBeClearedAndDateIsClamped() {
        let view = JWDatePickerView()
        view.calendar = calendar
        view.selection = date(2024, 1, 1)
        view.minimumDate = date(2024, 3, 1)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 3, 1))
        view.minimumDate = nil
        view.selection = date(2024, 1, 1)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 1, 1))
    }

    func testYearChangeClampsLeapDay() {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
        view.calendar = calendar
        view.selection = date(2024, 2, 29)
        let picker = wheel(view)
        let yearRow = picker.selectedRow(inComponent: 0) + 1
        picker.selectRow(yearRow, inComponent: 0, animated: false)
        view.pickerView(picker, didSelectRow: yearRow, inComponent: 0)
        XCTAssertEqual(view.currentSelectedDate(), date(2025, 2, 28))
    }

    func testDateAndTimeRangeAcrossDays() {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
        view.calendar = calendar
        view.type = .dateWeekHourMinute
        view.minimumDate = date(2024, 2, 28, 10)
        view.maximumDate = date(2024, 3, 1, 15)
        view.selection = date(2024, 2, 29, 12)
        let picker = wheel(view)
        XCTAssertEqual(picker.numberOfRows(inComponent: 0), 3)
        picker.selectRow(2, inComponent: 0, animated: false)
        view.pickerView(picker, didSelectRow: 2, inComponent: 0)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 3, 1, 12))
    }

    func testConfirmReturnsDefaultWithoutScrolling() {
        let controller = JWDatePickerViewController()
        let expected = date(2024, 2, 29, 12, 30)
        controller.selection = expected
        controller.loadViewIfNeeded()
        var actual: Date?
        var components: DateComponents?
        controller.confirmHandler = { actual = $0 }
        controller.confirmDateComponentsHandler = { components = $0 }
        let header = controller.headerView
        let button = header.subviews.compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == header.confirmTitle }!
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(actual, expected)
        XCTAssertNotNil(components)
    }

    func testControllerLoads() {
        let controller = JWDatePickerViewController()
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func testAtomicInvalidRangePreservesSelectionAndConfiguration() throws {
        let view = JWDatePickerView()
        let valid = JWDatePickerConfiguration(selectedDate: date(2000, 2, 29),
            minimumDate: date(1940, 1, 1), maximumDate: date(2024, 1, 1), calendar: calendar)
        try view.apply(valid)
        let invalid = JWDatePickerConfiguration(type: .time, selectedDate: date(2030, 1, 1),
            minimumDate: date(2030, 1, 1), maximumDate: date(2020, 1, 1))
        XCTAssertThrowsError(try view.apply(invalid))
        XCTAssertEqual(view.configurationError, .invalidDateRange)
        XCTAssertEqual(view.type, .date)
        XCTAssertEqual(view.currentSelectedDate(), valid.selectedDate)
        XCTAssertEqual(view.minimumDate, valid.minimumDate)
        view.maximumDate = date(1930, 1, 1)
        XCTAssertEqual(view.maximumDate, valid.maximumDate)
        XCTAssertEqual(view.configurationError, .invalidDateRange)
        try view.apply(valid)
        XCTAssertNil(view.configurationError)
    }

    func testDateOnlyUsesCalendarDayForBoundsAndResult() throws {
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 2, 29, 16),
            minimumDate: date(2024, 2, 29, 20), maximumDate: date(2024, 2, 29, 10),
            calendar: calendar, selectionPolicy: .startOfDay))
        XCTAssertEqual(view.commitSelection(), date(2024, 2, 29))
        XCTAssertEqual(wheel(view).numberOfRows(inComponent: 2), 1)
    }

    func testDayPolicyHandlesTimeZoneAndDaylightSaving() throws {
        var local = calendar
        local.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let selected = local.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 14))!
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: selected, calendar: local, selectionPolicy: .startOfDay))
        XCTAssertEqual(view.commitSelection(), local.startOfDay(for: selected))
        XCTAssertEqual(local.component(.day, from: view.commitSelection()), 10)
    }

    func testConfirmReadsWheelRowsBeforeDelegateCallback() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 414, height: 216))
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2000, 5, 14),
            minimumDate: date(1940, 1, 1), maximumDate: date(2024, 12, 31), calendar: calendar))
        let picker = wheel(view)
        picker.selectRow(picker.selectedRow(inComponent: 0) + 1, inComponent: 0, animated: false)
        picker.selectRow(5, inComponent: 1, animated: false)
        XCTAssertEqual(view.commitSelection(), date(2001, 6, 14))
    }

    func testLoopingCanBeConfiguredPerComponentAndMapsRowsToValues() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 414, height: 216))
        try view.apply(JWDatePickerConfiguration(type: .dateHour,
            selectedDate: date(2024, 2, 29, 12), calendar: calendar))
        view.setLooping(true, for: .hour)
        XCTAssertTrue(view.isLooping(for: .hour))

        let picker = wheel(view)
        let hourComponent = 3
        XCTAssertEqual(picker.numberOfRows(inComponent: hourComponent), 10_000)
        let selectedRow = picker.selectedRow(inComponent: hourComponent)
        picker.selectRow(selectedRow + 1, inComponent: hourComponent, animated: false)
        view.pickerView(picker, didSelectRow: selectedRow + 1, inComponent: hourComponent)
        XCTAssertEqual(calendar.component(.hour, from: view.commitSelection()), 13)

        view.setLooping(false, for: .hour)
        XCTAssertFalse(view.isLooping(for: .hour))
        XCTAssertEqual(picker.numberOfRows(inComponent: hourComponent), 24)
    }

    func testLoopingWheelRestylesOldAndNewRows() throws {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 390, height: 250))
        try view.apply(JWDatePickerConfiguration(type: .time, selectedDate: date(2024, 2, 29, 12), calendar: calendar))
        view.setLooping(true, for: .hour)
        view.selectedAttributes = [.foregroundColor: UIColor.magenta]
        let picker = wheel(view)
        let row = picker.selectedRow(inComponent: 0)
        let first = view.pickerView(picker, viewForRow: row, forComponent: 0, reusing: nil)
        let second = view.pickerView(picker, viewForRow: row + 1, forComponent: 0, reusing: nil)
        let labels = try [first, second].map { view in
            try XCTUnwrap(view.subviews.compactMap { $0 as? UILabel }.first)
        }

        picker.selectRow(row + 1, inComponent: 0, animated: false)
        view.pickerView(picker, didSelectRow: row + 1, inComponent: 0)
        let colors = labels.map { $0.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor }
        XCTAssertEqual(colors, [.secondaryLabel, .magenta])
    }

    func testSelectionBandClipsAtTheFrameBoundary() throws {
        let view = JWDatePickerView()
        view.selectedAttributes = [.foregroundColor: UIColor.magenta]
        let wheel = wheel(view)
        let index = wheel.selectedRow(inComponent: 0)
        let row = try XCTUnwrap(view.pickerView(wheel, viewForRow: index, forComponent: 0, reusing: nil) as? JWDatePickerRowView)
        wheel.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        wheel.addSubview(row)
        defer { row.removeFromSuperview() }
        row.frame = CGRect(x: 100, y: 50, width: 100, height: 40)
        row.layoutIfNeeded()
        row.updateClip(in: wheel, height: 40)

        let labels = row.subviews.compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.count, 2)
        let normal = try XCTUnwrap(labels.first)
        let highlighted = try XCTUnwrap(labels.last)
        let mask = try XCTUnwrap(highlighted.layer.mask as? CAShapeLayer)
        XCTAssertEqual(mask.path?.boundingBox, CGRect(x: 0, y: 30, width: 100, height: 10))
        XCTAssertEqual((normal.layer.mask as? CAShapeLayer)?.fillRule, .evenOdd)
        XCTAssertEqual(normal.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor,
                       .secondaryLabel)
        XCTAssertEqual(highlighted.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor,
                       .magenta)

        row.frame.origin.y = 80
        row.updateClip(in: wheel, height: 40)
        XCTAssertFalse(highlighted.isHidden)
        XCTAssertTrue(normal.isHidden)
        row.frame.origin.y = 120
        row.updateClip(in: wheel, height: 40)
        XCTAssertTrue(highlighted.isHidden)
        XCTAssertFalse(normal.isHidden)
    }

    func testUntouchedConfirmPreservesSubsecondsAndHiddenComponents() throws {
        for type in JWDatePickerType.allCases {
            let selected = date(2024, 2, 29, 12, 30).addingTimeInterval(0.125)
            let view = JWDatePickerView()
            try view.apply(JWDatePickerConfiguration(type: type, selectedDate: selected, calendar: calendar))
            XCTAssertEqual(view.commitSelection(), selected, "Mode \(type)")
        }
    }

    func testContentSendsOneResultAndCanBeginAgain() {
        let content = JWDatePickerContentView()
        var results = [JWDatePickerResult]()
        content.onResult = { results.append($0) }
        content.confirmSelection()
        content.confirmSelection()
        content.cancelSelection()
        XCTAssertEqual(results.count, 1)
        content.beginSelection()
        content.cancelSelection()
        content.confirmSelection()
        XCTAssertEqual(results.count, 2)
        guard case .cancelled = results.last! else { return XCTFail("Expected cancellation") }
    }

    func testControllerCallbacksAreOnceOnlyAndUseConfiguredCalendar() throws {
        let controller = JWDatePickerViewController()
        try controller.apply(JWDatePickerConfiguration(selectedDate: date(2000, 5, 14, 12), calendar: calendar))
        var calls: [String] = []
        var components: DateComponents?
        controller.confirmHandler = { _ in calls.append("confirm") }
        controller.cancelHandler = { calls.append("cancel") }
        controller.confirmDateComponentsHandler = {
            components = $0
            calls.append("components")
        }
        controller.onResult = { result in
            guard case .confirmed = result else { return XCTFail("Expected confirmation") }
            calls.append("result")
        }
        controller.contentView.confirmSelection()
        controller.contentView.cancelSelection()
        XCTAssertEqual(calls, ["confirm", "components", "result"])
        XCTAssertEqual(components?.hour, 12)
    }

    func testPanelLayoutAndDimensionValidation() {
        let content = JWDatePickerContentView(frame: CGRect(x: 0, y: 0, width: 414, height: 266))
        content.pickerHeight = 216
        content.headerHeight = 50
        content.layoutIfNeeded()
        XCTAssertEqual(content.headerView.frame.height, 50)
        XCTAssertEqual(content.pickerView.frame.minY, 50)
        XCTAssertEqual(content.pickerView.frame.height, 216)
        content.headerHeight = 10
        content.pickerHeight = .nan
        content.pickerView.rowHeight = -1
        XCTAssertEqual(content.headerHeight, 50)
        XCTAssertEqual(content.pickerHeight, 216)
        XCTAssertEqual(content.pickerView.rowHeight, 50)
        content.pickerView.columnWidth = { _, _ in 100 }
        XCTAssertEqual(content.pickerView.pickerView(wheel(content), widthForComponent: 0), 100)
    }


    func testExternalDismissalCancelsAndControllerCanBePresentedAgain() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let controller = JWDatePickerViewController()
        var cancellations = 0
        var confirmations = 0
        controller.cancelHandler = { cancellations += 1 }
        controller.confirmHandler = { _ in confirmations += 1 }
        root.present(controller, animated: false)
        try await Task.sleep(nanoseconds: 100_000_000)
        controller.dismiss(animated: false)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(cancellations, 1)
        root.present(controller, animated: false)
        try await Task.sleep(nanoseconds: 100_000_000)
        controller.automaticallyDismisses = true
        controller.contentView.confirmSelection()
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(confirmations, 1)
        XCTAssertEqual(cancellations, 1)
        XCTAssertNil(root.presentedViewController)
    }

    func testLegacyButtonsKeepPresentationUntilCallerDismisses() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let controller = JWDatePickerViewController()
        root.present(controller, animated: false)
        try await Task.sleep(nanoseconds: 100_000_000)
        controller.contentView.confirmSelection()
        XCTAssertTrue(root.presentedViewController === controller)
        controller.dismiss(animated: false)
    }


    func testCommitClampsStaleDayAfterMonthOrYearScroll() throws {
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 1, 31), calendar: calendar))
        wheel(view).selectRow(1, inComponent: 1, animated: false)
        XCTAssertEqual(view.commitSelection(), date(2024, 2, 29))
        let picker = wheel(view)
        picker.selectRow(picker.selectedRow(inComponent: 0) + 1, inComponent: 0, animated: false)
        XCTAssertEqual(view.commitSelection(), date(2025, 2, 28))
    }

    func testMonthCallbackPreservesUncommittedDayWheelPosition() throws {
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 5, 31), calendar: calendar,
                                               selectionPolicy: .startOfDay))
        let picker = wheel(view)
        // 日列已滑至 12 日，但其 didSelectRow 尚未触发，此时月列先结束。
        picker.selectRow(11, inComponent: 2, animated: false)
        picker.selectRow(5, inComponent: 1, animated: false)
        var changes = [Date]()
        view.onDateChanged = { changes.append($0) }
        view.pickerView(picker, didSelectRow: 5, inComponent: 1)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 6, 12))
        XCTAssertEqual(picker.selectedRow(inComponent: 2), 11)
        XCTAssertEqual(changes, [date(2024, 6, 12)])
        XCTAssertEqual(view.commitSelection(), date(2024, 6, 12))
    }

    func testDayCallbackIncludesMonthWheelBeforeItsCallback() throws {
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 1, 31), calendar: calendar))
        let picker = wheel(view)
        picker.selectRow(1, inComponent: 1, animated: false)
        picker.selectRow(13, inComponent: 2, animated: false)
        view.pickerView(picker, didSelectRow: 13, inComponent: 2)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 2, 14))
        XCTAssertEqual(view.commitSelection(), date(2024, 2, 14))
    }

    func testOverlappingWheelsClampOnlyInvalidDaysAndRespectBirthdayBounds() throws {
        let view = JWDatePickerView()
        for day in [12, 29, 30, 31] {
            try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 1, 31), calendar: calendar))
            let picker = wheel(view)
            picker.selectRow(day - 1, inComponent: 2, animated: false)
            picker.selectRow(1, inComponent: 1, animated: false)
            view.pickerView(picker, didSelectRow: 1, inComponent: 1)
            XCTAssertEqual(view.commitSelection(), date(2024, 2, min(day, 29)))
        }
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 4, 30),
            minimumDate: date(1940, 1, 1), maximumDate: date(2024, 5, 10), calendar: calendar,
            selectionPolicy: .startOfDay))
        let picker = wheel(view)
        picker.selectRow(11, inComponent: 2, animated: false)
        picker.selectRow(4, inComponent: 1, animated: false)
        view.pickerView(picker, didSelectRow: 4, inComponent: 1)
        XCTAssertEqual(view.commitSelection(), date(2024, 5, 10))
    }

    func testLocalizedModesUnitsAndHeaderFollowConfiguration() throws {
        let content = JWDatePickerContentView()
        for identifier in ["zh_CN", "zh_TW", "en_US", "ja_JP", "ko_KR", "fr_FR", "de_DE", "es_ES", "ar_SA"] {
            let locale = Locale(identifier: identifier)
            for type in JWDatePickerType.allCases {
                try content.apply(JWDatePickerConfiguration(type: type, selectedDate: date(2024, 5, 12, 13, 24),
                                                           calendar: calendar, locale: locale))
                XCTAssertFalse(type.localizedName(locale: locale).hasPrefix("mode."))
                let title = type.localizedTitle(locale: locale)
                XCTAssertFalse(title.hasPrefix("title."))
                XCTAssertEqual(content.headerView.locale, locale)
                let labels = content.headerView.subviews.compactMap { $0 as? UILabel }
                XCTAssertEqual(labels.first?.text, title)
                for width: CGFloat in [320, 390, 768] {
                    content.frame = CGRect(x: 0, y: 0, width: width, height: 300)
                    content.layoutIfNeeded()
                    content.headerView.layoutIfNeeded()
                    let picker = wheel(content)
                    let widths = (0..<type.columnCount).map { content.pickerView.pickerView(picker, widthForComponent: $0) }
                    XCTAssertLessThanOrEqual(widths.reduce(0, +), width)
                    XCTAssertTrue(widths.allSatisfy { $0 > 0 })
                    let buttons = content.headerView.subviews.compactMap { $0 as? UIButton }
                    for button in buttons {
                        XCTAssertFalse(button.frame.intersects(labels.first!.frame))
                        XCTAssertGreaterThanOrEqual(button.bounds.width, 44)
                    }
                }
            }
        }
        try content.apply(JWDatePickerConfiguration(type: .timeAndSecond, selectedDate: date(2024, 5, 12, 13, 24),
            calendar: calendar, locale: Locale(identifier: "en_US")))
        let picker = wheel(content)
        let hour = content.pickerView.pickerView(picker, viewForRow: 13, forComponent: 0, reusing: nil).subviews.compactMap { $0 as? UILabel }.first!
        let minute = content.pickerView.pickerView(picker, viewForRow: 24, forComponent: 1, reusing: nil).subviews.compactMap { $0 as? UILabel }.first!
        XCTAssertEqual(hour.text, "13 hr")
        XCTAssertEqual(minute.text, "24 min")
        content.headerView.cancelTitle = "Custom cancel"
        content.pickerView.locale = Locale(identifier: "ja_JP")
        XCTAssertEqual(content.headerView.cancelTitle, "Custom cancel")
        XCTAssertEqual(content.headerView.confirmTitle, "完了")
    }

    func testExamplePresentsEveryModeWithLocalizedTitleAndFitsPanel() async throws {
        let root = try XCTUnwrap(UIStoryboard(name: "Main", bundle: .main).instantiateInitialViewController())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.loadViewIfNeeded()
        let table = try XCTUnwrap(root.view.subviews.compactMap { $0 as? UITableView }.first)
        defer { window.isHidden = true }
        for row in 0...(JWDatePickerType.allCases.count + 1) {
            window.overrideUserInterfaceStyle = row.isMultiple(of: 2) ? .light : .dark
            table.delegate?.tableView?(table, didSelectRowAt: IndexPath(row: row, section: 0))
            try await Task.sleep(nanoseconds: 400_000_000)
            let controller = try XCTUnwrap(root.presentedViewController as? JWDatePickerViewController)
            controller.view.layoutIfNeeded()
            let mode: JWDatePickerType
            if row == 0 {
                mode = .date
            } else if row == 1 {
                mode = .dateHourMinute
                XCTAssertTrue(controller.pickerView.isLooping(for: .hour))
                XCTAssertTrue(controller.pickerView.isLooping(for: .minute))
            } else {
                mode = JWDatePickerType.allCases[row - 2]
            }
            XCTAssertEqual(controller.type, mode)
            XCTAssertEqual(controller.headerView.attributedTitle?.string, mode.localizedTitle())
            XCTAssertEqual(controller.pickerView.locale, Locale.current)
            XCTAssertEqual(controller.contentView.headerHeight, 50)
            XCTAssertEqual(controller.contentView.pickerHeight, 250)
            XCTAssertEqual(controller.topCornerRadius, 24)
            XCTAssertEqual(controller.textColorOfSelectedRow, .systemTeal)
            XCTAssertEqual(controller.textColorOfOtherRow, .secondaryLabel)
            XCTAssertLessThanOrEqual(controller.contentView.pickerView.frame.maxY, controller.view.bounds.height)
            XCTAssertEqual(controller.pickerView.lineColor, .clear)
            let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: controller.view.bounds).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            })
            attachment.name = "\(Locale.current.identifier)-\(row)-\(mode)"
            attachment.lifetime = .keepAlways
            add(attachment)
            controller.dismiss(animated: false)
        }
    }

    func testLateDayCallbackCannotOverwriteSynchronizedSelection() throws {
        let view = JWDatePickerView()
        try view.apply(JWDatePickerConfiguration(selectedDate: date(2024, 5, 31), calendar: calendar))
        let picker = wheel(view)
        picker.selectRow(11, inComponent: 2, animated: false)
        picker.selectRow(5, inComponent: 1, animated: false)
        var callbacks = 0
        view.onDateChanged = { _ in callbacks += 1 }
        view.pickerView(picker, didSelectRow: 5, inComponent: 1)
        // 日列刷新后，旧减速动画的 30 日回调迟到。
        view.pickerView(picker, didSelectRow: 29, inComponent: 2)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 6, 12))
        XCTAssertEqual(callbacks, 1)
    }

    func testHeaderSeparatorDefaultsAndIndependentVisibility() throws {
        let header = JWDatePickerMenuHeaderView(frame: CGRect(x: 0, y: 0, width: 390, height: 56))
        header.layoutIfNeeded()
        let lines = header.subviews.filter { type(of: $0) == UIView.self }
        XCTAssertEqual(lines.count, 2)
        let top = try XCTUnwrap(lines.first)
        let bottom = try XCTUnwrap(lines.last)
        XCTAssertFalse(header.showsTopLine)
        XCTAssertFalse(header.showsBottomLine)
        XCTAssertTrue(top.isHidden)
        XCTAssertTrue(bottom.isHidden)

        header.showsTopLine = true
        XCTAssertFalse(top.isHidden)
        XCTAssertTrue(bottom.isHidden)
        header.showsBottomLine = true
        XCTAssertFalse(top.isHidden)
        XCTAssertFalse(bottom.isHidden)
        XCTAssertEqual(top.frame.minY, 0)
        XCTAssertEqual(bottom.frame.maxY, header.bounds.height)
        XCTAssertEqual(top.frame.height, 1)
        XCTAssertEqual(bottom.frame.height, 1)
        header.lineColor = .systemRed
        XCTAssertEqual(top.backgroundColor, .systemRed)
        XCTAssertEqual(bottom.backgroundColor, .systemRed)
        header.showsTopLine = false
        XCTAssertTrue(top.isHidden)
        XCTAssertFalse(bottom.isHidden)
        header.showsBottomLine = false
        XCTAssertTrue(bottom.isHidden)
    }

    func testHeaderSeparatorsRenderInsideRoundedPanel() throws {
        let controller = JWDatePickerViewController()
        controller.topCornerRadius = 24
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 300)
        let header = controller.headerView
        header.lineColor = .red

        func render() throws -> CGImage {
            controller.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds)
            let image = renderer.image { context in
                controller.view.layer.render(in: context.cgContext)
            }
            return try XCTUnwrap(image.cgImage)
        }

        func pixel(in image: CGImage, y: Int) throws -> [UInt8] {
            let sample = try XCTUnwrap(image.cropping(to: CGRect(x: image.width / 2, y: y, width: 1, height: 1)))
            var color = [UInt8](repeating: 0, count: 4)
            try color.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                    bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(sample, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            return color
        }

        for style in [UIUserInterfaceStyle.light, .dark] {
            controller.overrideUserInterfaceStyle = style
            header.showsTopLine = true
            header.showsBottomLine = true
            let visible = try render()
            let scale = CGFloat(visible.width) / controller.view.bounds.width
            let bottomY = Int(header.frame.maxY * scale) - 1
            XCTAssertEqual(try pixel(in: visible, y: 0), [255, 0, 0, 255])
            XCTAssertEqual(try pixel(in: visible, y: bottomY), [255, 0, 0, 255])

            header.showsTopLine = false
            header.showsBottomLine = false
            let hidden = try render()
            XCTAssertNotEqual(try pixel(in: hidden, y: 0), [255, 0, 0, 255])
            XCTAssertNotEqual(try pixel(in: hidden, y: bottomY), [255, 0, 0, 255])
        }
    }

}
