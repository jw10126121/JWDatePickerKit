import XCTest
import UIKit
import JWDatePickerKit

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
            view.selectDate = date
            XCTAssertEqual(view.currentSelectedDate(), date)
            let picker = wheel(view)
            XCTAssertEqual(picker.numberOfComponents, type.section)
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
            view.selectDate = date(2024, 2, 29, 12, 30)
            let picker = wheel(view)
            for component in 0..<picker.numberOfComponents {
                let row = picker.numberOfRows(inComponent: component) - 1
                XCTAssertGreaterThanOrEqual(row, 0)
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
        view.selectDate = date(2024, 1, 1)
        view.minimumDate = date(2024, 3, 1)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 3, 1))
        view.minimumDate = nil
        view.selectDate = date(2024, 1, 1)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 1, 1))
    }

    func testYearChangeClampsLeapDay() {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
        view.calendar = calendar
        view.selectDate = date(2024, 2, 29)
        let picker = wheel(view)
        let yearRow = picker.selectedRow(inComponent: 0) + 1
        view.pickerView(picker, didSelectRow: yearRow, inComponent: 0)
        XCTAssertEqual(view.currentSelectedDate(), date(2025, 2, 28))
    }

    func testDateAndTimeRangeAcrossDays() {
        let view = JWDatePickerView(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
        view.calendar = calendar
        view.type = .dateWeekHourMinute
        view.minimumDate = date(2024, 2, 28, 10)
        view.maximumDate = date(2024, 3, 1, 15)
        view.selectDate = date(2024, 2, 29, 12)
        let picker = wheel(view)
        XCTAssertEqual(picker.numberOfRows(inComponent: 0), 3)
        view.pickerView(picker, didSelectRow: 2, inComponent: 0)
        XCTAssertEqual(view.currentSelectedDate(), date(2024, 3, 1, 12))
    }

    func testConfirmReturnsDefaultWithoutScrolling() {
        let controller = JWDatePickerViewController()
        let expected = date(2024, 2, 29, 12, 30)
        controller.defaultDate = expected
        controller.loadViewIfNeeded()
        var actual: Date?
        var components: DateComponents?
        controller.confirmHandler = { actual = $0 }
        controller.confirmDateComponentsHandler = { components = $0 }
        let header = controller.view.subviews.compactMap { $0 as? JWDatePickerMenuHeaderView }.first!
        let button = header.subviews.compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == "确定" }!
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(actual, expected)
        XCTAssertNotNil(components)
    }

    func testControllerLoads() {
        let controller = JWDatePickerViewController()
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}
