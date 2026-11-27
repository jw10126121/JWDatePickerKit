import Foundation

/// `.date` 模式的日期与范围解释方式。
public enum JWDatePickerSelectionPolicy {
    /// 保留未显示的日期分量，范围按完整时间判断。
    case preserveComponents
    /// 使用日历中的当天起始时间，范围按天判断。其他模式仍保留完整时间。
    case startOfDay
}

public enum JWDatePickerConfigurationError: Error, Equatable {
    case invalidDateRange
}

/// 一次应用日期配置，避免逐项设置产生中间选择状态。
public struct JWDatePickerConfiguration {
    public var type: JWDatePickerType
    public var selectedDate: Date?
    public var minimumDate: Date?
    public var maximumDate: Date?
    public var calendar: Calendar
    public var locale: Locale
    public var selectionPolicy: JWDatePickerSelectionPolicy

    public init(
        type: JWDatePickerType = .date,
        selectedDate: Date? = nil,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        calendar: Calendar = .current,
        locale: Locale = .current,
        selectionPolicy: JWDatePickerSelectionPolicy = .preserveComponents
    ) {
        self.type = type
        self.selectedDate = selectedDate
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.calendar = calendar
        self.locale = locale
        self.selectionPolicy = selectionPolicy
    }

    internal func normalized(_ date: Date) -> Date {
        if type == .date && selectionPolicy == .startOfDay {
            return calendar.startOfDay(for: date)
        }
        return date
    }

    internal func validate() throws {
        if let minimumDate, let maximumDate,
           normalized(minimumDate) > normalized(maximumDate) {
            throw JWDatePickerConfigurationError.invalidDateRange
        }
    }
}
