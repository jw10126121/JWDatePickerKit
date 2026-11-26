import UIKit

/// 可单独嵌入的日期选择器。未显示的日期分量保留在当前选择中。
public final class JWDatePickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    public var type: JWDatePickerType = .date { didSet { reloadDatas() } }
    public var selectDate: Date? { didSet { reloadDatas() } }
    public var minimumDate: Date? { didSet { reloadDatas() } }
    public var maximumDate: Date? { didSet { reloadDatas() } }
    public var calendar: Calendar = .current { didSet { reloadDatas() } }
    public var locale: Locale = .current { didSet { reloadDatas() } }
    public var rowHeight: CGFloat = 40 {
        didSet {
            topLinePosition?.constant = -rowHeight / 2
            bottomLinePosition?.constant = rowHeight / 2
            picker.reloadAllComponents()
        }
    }
    public var textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.black
    ] { didSet { picker.reloadAllComponents() } }
    public var selectedAttributes: [NSAttributedString.Key: Any]? { didSet { picker.reloadAllComponents() } }
    public var lineColor: UIColor = UIColor(white: 0.72, alpha: 1) {
        didSet { topLine.backgroundColor = lineColor; bottomLine.backgroundColor = lineColor }
    }
    public var pickerViewHeight: CGFloat { return picker.intrinsicContentSize.height }
    public var onDateChanged: ((Date) -> Void)?

    private let picker = UIPickerView()
    private let topLine = UIView()
    private let bottomLine = UIView()
    private var currentDate = Date()
    private var values: [[Int]] = []
    private var isUpdating = false
    private var topLinePosition: NSLayoutConstraint?
    private var bottomLinePosition: NSLayoutConstraint?
    private var previousWidth: CGFloat = 0
    private var weekRowCount = 0
    private let components: [Calendar.Component] = [.year, .month, .day, .hour, .minute, .second]

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        picker.dataSource = self
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(picker)
        for line in [topLine, bottomLine] {
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = lineColor
            line.isUserInteractionEnabled = false
            addSubview(line)
        }
        let pixel = 1 / UIScreen.main.scale
        topLinePosition = topLine.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -rowHeight / 2)
        bottomLinePosition = bottomLine.centerYAnchor.constraint(equalTo: centerYAnchor, constant: rowHeight / 2)
        NSLayoutConstraint.activate([topLinePosition!, bottomLinePosition!])
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: leadingAnchor), picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.topAnchor.constraint(equalTo: topAnchor), picker.bottomAnchor.constraint(equalTo: bottomAnchor),
            topLine.leadingAnchor.constraint(equalTo: leadingAnchor), topLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: pixel),
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor), bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: pixel)
        ])
        reloadDatas()
    }

    public override var intrinsicContentSize: CGSize { picker.intrinsicContentSize }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if previousWidth != bounds.width {
            previousWidth = bounds.width
            rebuild()
        }
    }

    private var visibleComponents: [Calendar.Component] {
        switch type {
        case .year: return [.year]
        case .yearAndMonth: return [.year, .month]
        case .date: return [.year, .month, .day]
        case .dateHour: return [.year, .month, .day, .hour]
        case .dateHourMinute: return [.year, .month, .day, .hour, .minute]
        case .dateHourMinuteSecond: return components
        case .monthDay: return [.month, .day]
        case .monthDayHour: return [.month, .day, .hour]
        case .monthDayHourMinute: return [.month, .day, .hour, .minute]
        case .monthDayHourMinuteSecond: return [.month, .day, .hour, .minute, .second]
        case .time: return [.hour, .minute]
        case .timeAndSecond: return [.hour, .minute, .second]
        case .minuteAndSecond: return [.minute, .second]
        case .dateWeekHourMinute: return [.day, .hour, .minute]
        }
    }

    private var dateBounds: (Date?, Date?) {
        if let min = minimumDate, let max = maximumDate, min > max { return (nil, nil) }
        return (minimumDate, maximumDate)
    }

    private func clamped(_ date: Date) -> Date {
        let (min, max) = dateBounds
        if let min = min, date < min { return min }
        if let max = max, date > max { return max }
        return date
    }

    /// 重新读取配置并更新滚轮。
    public func reloadDatas() {
        guard !isUpdating else { return }
        isUpdating = true
        currentDate = clamped(selectDate ?? currentDate)
        rebuild()
        selectDate = currentDate
        isUpdating = false
    }

    public func currentSelectedDate() -> Date? { currentDate }

    private func rebuild() {
        values = visibleComponents.enumerated().map { index, component in
            if type == .dateWeekHourMinute && index == 0 {
                let interval = weekBounds()
                weekRowCount = max(0, calendar.dateComponents([.day], from: interval.0, to: interval.1).day ?? 0) + 1
                return []
            }
            return availableValues(for: component)
        }
        picker.reloadAllComponents()
        for (index, component) in visibleComponents.enumerated() {
            let value: Int
            if type == .dateWeekHourMinute && index == 0 {
                value = calendar.dateComponents([.day], from: weekBounds().0, to: calendar.startOfDay(for: currentDate)).day ?? 0
            } else {
                value = calendar.component(component, from: currentDate)
            }
            if type == .dateWeekHourMinute && index == 0 {
                if value >= 0 && value < weekRowCount { picker.selectRow(value, inComponent: index, animated: false) }
            } else if let row = values[index].firstIndex(of: value) {
                picker.selectRow(row, inComponent: index, animated: false)
            }
        }
    }

    private func weekBounds() -> (Date, Date) {
        let year = calendar.component(.year, from: currentDate)
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? currentDate
        let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start) ?? currentDate
        let (min, max) = dateBounds
        return (calendar.startOfDay(for: min ?? start), calendar.startOfDay(for: max ?? end))
    }

    private func availableValues(for component: Calendar.Component) -> [Int] {
        let range: ClosedRange<Int>
        switch component {
        case .year:
            let year = calendar.component(.year, from: currentDate)
            let lower = dateBounds.0.map { calendar.component(.year, from: $0) } ?? min(1900, year)
            let upper = dateBounds.1.map { calendar.component(.year, from: $0) } ?? max(2100, year)
            range = min(lower, upper)...max(lower, upper)
        case .month:
            let months = calendar.range(of: .month, in: .year, for: currentDate) ?? 1..<13
            range = months.lowerBound...(months.upperBound - 1)
        case .day: range = 1...(calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 31)
        case .hour: range = 0...23
        default: range = 0...59
        }
        return range.filter { value in
            guard let date = replacing(component, with: value) else { return false }
            guard let interval = calendar.dateInterval(of: component, for: date) else { return false }
            let (min, max) = dateBounds
            return (min == nil || interval.end > min!) && (max == nil || interval.start <= max!)
        }
    }

    private func replacing(_ component: Calendar.Component, with value: Int) -> Date? {
        var parts = calendar.dateComponents(Set(components + [.era]), from: currentDate)
        parts.setValue(value, for: component)
        if component == .year || component == .month {
            let desiredDay = parts.day ?? 1
            parts.day = 1
            guard let first = calendar.date(from: parts), let days = calendar.range(of: .day, in: .month, for: first) else { return nil }
            parts.day = min(desiredDay, days.count)
        }
        guard let date = calendar.date(from: parts), calendar.component(component, from: date) == value else { return nil }
        return date
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int { visibleComponents.count }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if type == .dateWeekHourMinute && component == 0 { return weekRowCount }
        return component < values.count ? values[component].count : 0
    }
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowHeight }
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        bounds.width / CGFloat(max(visibleComponents.count, 1))
    }
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        let value = type == .dateWeekHourMinute && component == 0 ? row : values[component][row]
        var title = String(value)
        if type == .dateWeekHourMinute && component == 0, let date = calendar.date(byAdding: .day, value: value, to: weekBounds().0) {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate("MMM d EEE")
            title = formatter.string(from: date)
        } else if locale.languageCode == "zh" {
            let unit: String
            switch visibleComponents[component] {
            case .year: unit = "年"
            case .month: unit = "月"
            case .day: unit = "日"
            case .hour: unit = "时"
            case .minute: unit = "分"
            default: unit = "秒"
            }
            title += unit
        }
        let selected = pickerView.selectedRow(inComponent: component) == row
        label.attributedText = NSAttributedString(string: title, attributes: selected ? (selectedAttributes ?? textAttributes) : textAttributes)
        return label
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard component >= 0, component < values.count, row >= 0,
              row < self.pickerView(pickerView, numberOfRowsInComponent: component) else { return }
        let value = type == .dateWeekHourMinute && component == 0 ? row : values[component][row]
        let date: Date?
        if type == .dateWeekHourMinute && component == 0 {
            let start = weekBounds().0
            let selectedDay = calendar.date(byAdding: .day, value: value, to: start)
            let time = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
            date = selectedDay.flatMap { calendar.date(byAdding: time, to: $0) }
        } else {
            date = replacing(visibleComponents[component], with: value)
        }
        guard let selected = date else { return }
        currentDate = clamped(selected)
        isUpdating = true
        selectDate = currentDate
        rebuild()
        isUpdating = false
        onDateChanged?(currentDate)
    }
}
