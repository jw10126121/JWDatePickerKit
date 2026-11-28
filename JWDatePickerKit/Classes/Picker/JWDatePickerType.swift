//
//  JWDatePickerType.swift
//  JWDatePickerView
//
//  Created by linjw on 2022/7/30.
//

import Foundation

/// MARK - 日期类型
@objc public enum JWDatePickerType: Int, CaseIterable {
    
    case year
    case yearAndMonth
    case date
    case dateHour
    case dateHourMinute
    case dateHourMinuteSecond
    case monthDay
    case monthDayHour
    case monthDayHourMinute
    case monthDayHourMinuteSecond
    case time
    case timeAndSecond
    case minuteAndSecond
    case dateWeekHourMinute
    
    /// 与旧控制器的 dateAndTime 模式对应。
    public static var dateAndTime: JWDatePickerType { .dateWeekHourMinute }

    /// 使用系统语言的模式名称。
    public var name: String { localizedName() }

    public func localizedName(locale: Locale = .current) -> String {
        JWDatePickerLocalization.string("mode." + localizationKey, locale: locale)
    }

    public func localizedTitle(locale: Locale = .current) -> String {
        JWDatePickerLocalization.string("title." + localizationKey, locale: locale)
    }

    private var localizationKey: String {
        switch self {
        case .year: return "year"
        case .yearAndMonth: return "yearAndMonth"
        case .date: return "date"
        case .dateHour: return "dateHour"
        case .dateHourMinute: return "dateHourMinute"
        case .dateHourMinuteSecond: return "dateHourMinuteSecond"
        case .monthDay: return "monthDay"
        case .monthDayHour: return "monthDayHour"
        case .monthDayHourMinute: return "monthDayHourMinute"
        case .monthDayHourMinuteSecond: return "monthDayHourMinuteSecond"
        case .time: return "time"
        case .timeAndSecond: return "timeAndSecond"
        case .minuteAndSecond: return "minuteAndSecond"
        case .dateWeekHourMinute: return "dateWeekHourMinute"
        }
    }

    /// MARK - 格式
    public var stringFormat: String {
        switch self {
        case .year:
            return "yyyy"
        case .yearAndMonth:
            return "yyyy-MM"
        case .date:
            return "yyyy-MM-dd"
        case .dateHour:
            return "yyyy-MM-dd HH"
        case .dateHourMinute:
            return "yyyy-MM-dd HH:mm"
        case .dateHourMinuteSecond:
            return "yyyy-MM-dd HH:mm:ss"
        case .monthDay:
            return "MM-dd"
        case .monthDayHour:
            return "MM-dd HH"
        case .monthDayHourMinute:
            return "MM-dd HH:mm"
        case .monthDayHourMinuteSecond:
            return "MM-dd HH:mm:ss"
        case .time:
            return "HH:mm"
        case .timeAndSecond:
            return "HH:mm:ss"
        case .minuteAndSecond:
            return "mm:ss"
        case .dateWeekHourMinute:
            return "yyyy-MM-dd HH:mm"
        }
    }
    
    
    /// MARK - 分组
    public var columnCount: Int {
        switch self {
        case .year:
            return 1
        case .yearAndMonth:
            return 2
        case .date:
            return 3
        case .dateHour:
            return 4
        case .dateHourMinute:
            return 5
        case .dateHourMinuteSecond:
            return 6
        case .monthDay:
            return 2
        case .monthDayHour:
            return 3
        case .monthDayHourMinute:
            return 4
        case .monthDayHourMinuteSecond:
            return 5
        case .time:
            return 2
        case .timeAndSecond:
            return 3
        case .minuteAndSecond:
            return 2
        case .dateWeekHourMinute:
            return 3
        }
    }
}
