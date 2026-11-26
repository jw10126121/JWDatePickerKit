import XCTest
import JWDatePickerKit
import UIKit
import PGDatePicker
import PGPickerView

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testDatePickerViewControllerLoads() {
        let controller = JWDatePickerViewController()
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func testDatePickerViewControllerCanBePresented() {
        guard let rootController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            XCTFail("The example app has no root view controller")
            return
        }

        let controller = JWDatePickerViewController()
        rootController.present(controller, animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        XCTAssertTrue(controller.presentingViewController === rootController)
        controller.dismiss(animated: false)
    }

    func testAllDatePickerModesCanBeSelected() {
        guard let rootController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            XCTFail("The example app has no root view controller")
            return
        }

        let modes: [PGDatePickerMode] = [
            .year, .yearAndMonth, .date, .dateHour, .dateHourMinute,
            .dateHourMinuteSecond, .monthDay, .monthDayHour, .monthDayHourMinute,
            .monthDayHourMinuteSecond, .time, .timeAndSecond, .minuteAndSecond, .dateAndTime
        ]

        for mode in modes {
            let controller = JWDatePickerViewController()
            controller.datePickerMode = mode
            rootController.present(controller, animated: false)
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))

            XCTAssertTrue(controller.presentingViewController === rootController, "Failed to present mode \\(mode)")
            controller.view.layoutIfNeeded()

            guard let pickerView = findPickerView(in: controller.view) else {
                XCTFail("No picker view was created for mode \\(mode)")
                controller.dismiss(animated: false)
                continue
            }

            for component in 0..<pickerView.numberOfComponents {
                let numberOfRows = pickerView.numberOfRows(inComponent: component)
                if numberOfRows > 1 {
                    pickerView.selectRow(1, inComponent: component, animated: false)
                }
            }

            controller.dismiss(animated: false)
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
    }

    func testDatePickerIgnoresMissingDateComponents() {
        let controller = JWDatePickerViewController()
        let datePicker = PGDatePicker()
        controller.datePicker(datePicker, didSelectDate: nil)
    }

    private func findPickerView(in view: UIView) -> PGPickerView? {
        if let pickerView = view as? PGPickerView {
            return pickerView
        }

        for subview in view.subviews {
            if let pickerView = findPickerView(in: subview) {
                return pickerView
            }
        }

        return nil
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
