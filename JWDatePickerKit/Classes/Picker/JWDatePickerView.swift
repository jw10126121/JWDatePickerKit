import UIKit

/// 可单独嵌入的日期选择器。未显示的日期分量保留在当前选择中。
public final class JWDatePickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    public var type: JWDatePickerType = .date { didSet { reloadDatas() } }
    public var selectDate: Date? { didSet { reloadDatas() } }
    public var minimumDate: Date? { didSet { reloadDatas() } }
    public var maximumDate: Date? { didSet { reloadDatas() } }
    public var calendar: Calendar = .current { didSet { reloadDatas() } }
    public var locale: Locale = .current { didSet { reloadDatas() } }
    public var selectionPolicy: JWDatePickerSelectionPolicy = .preserveComponents { didSet { reloadDatas() } }
    /// 最近一次被拒绝的配置错误。成功配置后清空。
    public private(set) var configurationError: JWDatePickerConfigurationError?
    /// 返回指定列的宽度。未设置时根据本地化文本宽度分配。
    public var columnWidth: ((Int, CGFloat) -> CGFloat)? { didSet { rebuild() } }
    public var rowHeight: CGFloat = 40 {
        didSet {
            guard rowHeight.isFinite, rowHeight > 0 else {
                rowHeight = oldValue
                return
            }
            topLinePosition?.constant = -rowHeight / 2
            bottomLinePosition?.constant = rowHeight / 2
            picker.reloadAllComponents()
        }
    }
    public var textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.label
    ] { didSet { rebuild() } }
    public var selectedAttributes: [NSAttributedString.Key: Any]? { didSet { rebuild() } }
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
    private var lastValidConfiguration = JWDatePickerConfiguration()
    private var topLinePosition: NSLayoutConstraint?
    private var bottomLinePosition: NSLayoutConstraint?
    private var previousWidth: CGFloat = 0
    private var weekRowCount = 0
    private var preferredColumnWidths: [CGFloat] = []
    private let numberFormatter = NumberFormatter()
    private let monthFormatter = DateFormatter()
    private let weekFormatter = DateFormatter()
    private var localizedUnits: [String: String] = [:]
    internal var onConfigurationChanged: (() -> Void)?
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

    public var configuration: JWDatePickerConfiguration {
        JWDatePickerConfiguration(
            type: type, selectedDate: selectDate, minimumDate: minimumDate,
            maximumDate: maximumDate, calendar: calendar, locale: locale,
            selectionPolicy: selectionPolicy
        )
    }

    private var dateBounds: (Date?, Date?) {
        let configuration = self.configuration
        return (minimumDate.map(configuration.normalized), maximumDate.map(configuration.normalized))
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
        do {
            try apply(configuration)
        } catch {
            configurationError = error as? JWDatePickerConfigurationError
            updateProperties(lastValidConfiguration)
        }
    }

    /// 验证成功后原子应用配置。失败时保留之前的配置和选择。
    public func apply(_ configuration: JWDatePickerConfiguration) throws {
        do {
            try configuration.validate()
        } catch {
            configurationError = error as? JWDatePickerConfigurationError
            throw error
        }
        updateProperties(configuration)
        isUpdating = true
        currentDate = clamped(configuration.normalized(selectDate ?? currentDate))
        selectDate = currentDate
        lastValidConfiguration = self.configuration
        configurationError = nil
        rebuild()
        isUpdating = false
        onConfigurationChanged?()
    }

    private func updateProperties(_ configuration: JWDatePickerConfiguration) {
        isUpdating = true
        type = configuration.type
        selectDate = configuration.selectedDate
        minimumDate = configuration.minimumDate
        maximumDate = configuration.maximumDate
        calendar = configuration.calendar
        locale = configuration.locale
        selectionPolicy = configuration.selectionPolicy
        isUpdating = false
    }

    public func currentSelectedDate() -> Date? { currentDate }

    /// 固定滚轮当前选中行，并统一读取所有列，供确认按钮使用。
    @discardableResult
    public func commitSelection() -> Date {
        resolveSelection()
        return currentDate
    }

    private func resolveSelection() {
        isUpdating = true
        defer { isUpdating = false }
        // 必须先读取全部列。刷新任意一列都会使尚在减速的其他列丢失当前位置。
        let selectedRows = visibleComponents.indices.map { picker.selectedRow(inComponent: $0) }
        let selectedValues = visibleComponents.enumerated().compactMap { index, component -> (Calendar.Component, Int)? in
            let row = selectedRows[index]
            guard row >= 0, row < self.pickerView(picker, numberOfRowsInComponent: index) else { return nil }
            let value = type == .dateWeekHourMinute && index == 0 ? row : values[index][row]
            return (component, value)
        }
        // 在替换行数据之前停止旧的减速动画，避免旧月份的行索引继续参与回调。
        for (index, row) in selectedRows.enumerated() {
            if row >= 0 && row < self.pickerView(picker, numberOfRowsInComponent: index) {
                picker.selectRow(row, inComponent: index, animated: false)
            }
        }
        var date = currentDate
        for (component, value) in selectedValues {
            if type == .dateWeekHourMinute && component == .day {
                let day = calendar.date(byAdding: .day, value: value, to: weekBounds().0)
                if let day, calendar.isDate(day, inSameDayAs: date) { continue }
                let time = calendar.dateComponents([.hour, .minute, .second], from: date)
                date = day.flatMap { calendar.date(byAdding: time, to: $0) } ?? date
            } else {
                let resolvedValue: Int
                if component == .day, let days = calendar.range(of: .day, in: .month, for: date) {
                    resolvedValue = min(value, days.upperBound - 1)
                } else {
                    resolvedValue = value
                }
                if calendar.component(component, from: date) != resolvedValue {
                    date = replacing(component, with: resolvedValue, in: date) ?? date
                }
            }
        }
        currentDate = clamped(configuration.normalized(date))
        selectDate = currentDate
        lastValidConfiguration = configuration
        rebuild()
    }

    private func rebuild() {
        for unit in ["year", "month", "day", "hour", "minute", "second"] {
            localizedUnits[unit] = JWDatePickerLocalization.string("unit." + unit, locale: locale)
        }
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.maximumFractionDigits = 0
        for formatter in [monthFormatter, weekFormatter] {
            formatter.calendar = calendar
            formatter.locale = locale
            formatter.timeZone = calendar.timeZone
        }
        monthFormatter.dateFormat = "LLL"
        weekFormatter.setLocalizedDateFormatFromTemplate("MMM d EEE")
        values = visibleComponents.enumerated().map { index, component in
            if type == .dateWeekHourMinute && index == 0 {
                let interval = weekBounds()
                weekRowCount = max(0, calendar.dateComponents([.day], from: interval.0, to: interval.1).day ?? 0) + 1
                return []
            }
            return availableValues(for: component)
        }
        updatePreferredColumnWidths()
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

    private func replacing(_ component: Calendar.Component, with value: Int, in date: Date? = nil) -> Date? {
        var parts = calendar.dateComponents(Set(components + [.era]), from: date ?? currentDate)
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
    private func rowTitle(value: Int, component index: Int) -> String {
        let component = visibleComponents[index]
        if type == .dateWeekHourMinute && index == 0,
           let date = calendar.date(byAdding: .day, value: value, to: weekBounds().0) {
            return weekFormatter.string(from: date)
        }
        let number = numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
        let usesDateUnits = ["zh", "ja", "ko"].contains(locale.languageCode ?? "")
        if component == .month && !usesDateUnits,
           let date = replacing(.month, with: value) {
            return monthFormatter.string(from: date)
        }
        if usesDateUnits || [.hour, .minute, .second].contains(component) {
            let unit: String
            switch component {
            case .year: unit = "year"
            case .month: unit = "month"
            case .day: unit = "day"
            case .hour: unit = "hour"
            case .minute: unit = "minute"
            default: unit = "second"
            }
            let suffix = localizedUnits[unit] ?? ""
            return number + (usesDateUnits ? "" : " ") + suffix
        }
        return number
    }

    private func updatePreferredColumnWidths() {
        let font = textAttributes[.font] as? UIFont ?? .systemFont(ofSize: 20)
        let selectedFont = selectedAttributes?[.font] as? UIFont ?? font
        preferredColumnWidths = visibleComponents.indices.map { index in
            let candidates = type == .dateWeekHourMinute && index == 0 ? Array(0..<min(weekRowCount, 366)) : values[index]
            let width = candidates.map { value -> CGFloat in
                let title = rowTitle(value: value, component: index) as NSString
                return max(title.size(withAttributes: [.font: font]).width,
                           title.size(withAttributes: [.font: selectedFont]).width)
            }.max() ?? 0
            return max(visibleComponents.count <= 3 ? 88 : 44, width + 16)
        }
    }

    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let availableWidth = max(0, bounds.width)
        if let width = columnWidth?(component, availableWidth), width.isFinite, width > 0 {
            return min(width, availableWidth)
        }
        guard component < preferredColumnWidths.count else { return 0 }
        let total = preferredColumnWidths.reduce(0, +)
        let contentWidth = max(0, availableWidth - 32)
        let scale = min(1, contentWidth / max(total, 1))
        return preferredColumnWidths[component] * scale
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        let value = type == .dateWeekHourMinute && component == 0 ? row : values[component][row]
        let title = rowTitle(value: value, component: component)
        let selectedValue: Int
        if type == .dateWeekHourMinute && component == 0 {
            selectedValue = calendar.dateComponents([.day], from: weekBounds().0, to: calendar.startOfDay(for: currentDate)).day ?? 0
        } else {
            selectedValue = calendar.component(visibleComponents[component], from: currentDate)
        }
        let selected = selectedValue == value
        label.attributedText = NSAttributedString(string: title, attributes: selected ? (selectedAttributes ?? textAttributes) : textAttributes)
        return label
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard component >= 0, component < values.count, row >= 0,
              row < self.pickerView(pickerView, numberOfRowsInComponent: component) else { return }
        // reload 后旧滚轮可能迟到的回调不能覆盖新的选择。
        guard !isUpdating, pickerView.selectedRow(inComponent: component) == row else { return }
        resolveSelection()
        onDateChanged?(currentDate)
    }
}
