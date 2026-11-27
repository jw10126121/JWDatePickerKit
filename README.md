# JWDatePickerKit

JWDatePickerKit 是一个基于 Swift 和 UIKit 的日期时间选择组件，提供可嵌入页面的滚轮选择器，以及带取消、确定按钮的底部弹层控制器。

## 功能

- 支持年、年月、日期、日期时间、月日、时间及日期星期等 14 种选择模式。
- 可以设置初始日期、最小日期和最大日期，也可以设置日历、时区与语言环境。
- 可以设置滚轮行高、文字属性和分隔线颜色，并通过回调获取用户的选择。
- 每个日期分量都可以单独切换为循环滚动。
- 支持 CocoaPods 和 Swift Package Manager。Picker 适合嵌入自定义界面，Content 提供带头部的面板，Controller 提供现成的底部弹层。
- 提供 SwiftUI `JWDatePicker`，通过 `Binding<Date>` 同步日期选择。

## 环境要求

- iOS 15.0 及以上，使用支持 Swift Package Manager 的 Xcode 工具链。
- 核心控件基于 UIKit，可在 SwiftUI 项目中通过 `JWDatePickerKitSwiftUI` 产品使用 `JWDatePicker`。
- 示例工程通过 CocoaPods 管理依赖。

## 安装

### CocoaPods

在 Podfile 中选择一种安装方式。

```ruby
# 完整组件，包括滚轮选择器和底部弹层控制器
pod 'JWDatePickerKit'

# 或者只安装可嵌入的滚轮选择器
# pod 'JWDatePickerKit/Picker'

# 可嵌入现有弹层容器的完整面板
# pod 'JWDatePickerKit/Content'

# SwiftUI 的内嵌选择器
# pod 'JWDatePickerKit/SwiftUI'

# 也可以显式安装弹层子模块，它会自动引入 Content 和 Picker
# pod 'JWDatePickerKit/Controller'
```

在 Podfile 所在目录执行 `pod install`，然后打开生成的 `.xcworkspace`。无论选择哪个子模块，Swift 中都使用同一个模块名。

```swift
import JWDatePickerKit
```

| 子模块 | 包含内容 | 依赖 |
| --- | --- | --- |
| `Picker` | `JWDatePickerView`、`JWDatePickerType`、`JWDatePickerConfiguration`（含 `JWDatePickerSelectionPolicy`、`JWDatePickerConfigurationError`）、`JWDatePickerLocalization` 及多语言资源 | UIKit |
| `Content` | `JWDatePickerContentView`、`JWDatePickerMenuHeaderView`、`JWDatePickerResult` | `Picker`、UIKit |
| `SwiftUI` | `JWDatePicker`，以 `Binding<Date>` 连接选择器 | `Picker`、SwiftUI |
| `Controller` | `JWDatePickerViewController` | `Content`、XBDialog |

完整安装默认包含 `Controller`，并通过它引入 `Picker`。这些子模块属于同一个 CocoaPods Pod。原独立 `JWDatePickerView` Pod 的版本不会随本仓库的修改自动更新。

### Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，输入仓库地址，并选择包含 `Package.swift` 的分支或版本。添加 `JWDatePickerKit` 产品以使用 Picker 和 Content，添加 `JWDatePickerKitSwiftUI` 产品以使用 SwiftUI 包装器。

SwiftPM 的核心产品不包含 `JWDatePickerViewController`。该控制器依赖的 XBDialog 1.6.0 尚未提供 Swift Package manifest。CocoaPods 中仍可照常使用完整控制器。

```swift
import JWDatePickerKit
import JWDatePickerKitSwiftUI

struct DateForm: View {
    @State private var selectedDate = Date()

    var body: some View {
        JWDatePicker(selection: $selectedDate, type: .date)
    }
}
```

当前仓库的改动在发布新版本前，可以通过本地路径体验。

```ruby
pod 'JWDatePickerKit', :path => '/本地路径/JWDatePickerKit'
# 只使用选择器时
# pod 'JWDatePickerKit/Picker', :path => '/本地路径/JWDatePickerKit'
```

## 底部弹层用法

`JWDatePickerViewController` 使用 `present` 展示。下面的代码可以放在一个 `UIViewController` 中。

```swift
import UIKit
import JWDatePickerKit

func showDatePicker() {
    let picker = JWDatePickerViewController()
    picker.datePickerMode = .dateHourMinute
    picker.defaultDate = Date()

    // 可按需设置范围。此处允许选择从当前时间起的一年内的日期。
    let now = Date()
    picker.minimumDate = now
    picker.maximumDate = Calendar.current.date(byAdding: .year, value: 1, to: now)

    picker.cancelHandler = { [weak picker] in
        picker?.dismiss(animated: true, completion: nil)
    }

    picker.confirmHandler = { [weak picker] date in
        print("选择的日期：", date)
        picker?.dismiss(animated: true, completion: nil)
    }

    present(picker, animated: true, completion: nil)
}
```

取消和确定按钮会调用对应的回调，业务方可以在回调中关闭弹层。`backgoundTapDismissEnable` 默认是 `true`，点击背景时会调用 `cancelHandler` 并关闭弹层。设置为 `false` 可以禁用背景点击关闭。注意该属性名沿用历史拼写（少一个 `r`），调用时请使用 `backgoundTapDismissEnable`。

如需取得日期分量，可以设置 `confirmDateComponentsHandler`。两个确定回调都设置时，点击确定会先调用 `confirmHandler`，再调用 `confirmDateComponentsHandler`。

```swift
picker.confirmDateComponentsHandler = { components in
    print("年：", components.year ?? 0)
    print("月：", components.month ?? 0)
    print("日：", components.day ?? 0)
    print("时：", components.hour ?? 0)
    print("分：", components.minute ?? 0)
    print("秒：", components.second ?? 0)
}
```

控制器属性如下。

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `datePickerMode` | `JWDatePickerType` | 选择模式，默认 `.date` |
| `defaultDate` | `Date` | 初始日期，默认当前时间 |
| `minimumDate`、`maximumDate` | `Date?` | 日期上下限，传入 `nil` 可清除对应限制 |
| `backgoundTapDismissEnable` | `Bool` | 是否允许点击背景关闭，默认 `true`；属性名沿用历史拼写 |
| `lineBackgroundColor` | `UIColor` | 滚轮选中区域分隔线颜色 |
| `textColorOfSelectedRow` | `UIColor` | 选中行文字颜色 |
| `textColorOfOtherRow` | `UIColor` | 其他行文字颜色 |
| `cancelHandler` | `(() -> Void)?` | 取消回调 |
| `confirmHandler` | `((Date) -> Void)?` | 确定时返回日期 |
| `confirmDateComponentsHandler` | `((DateComponents) -> Void)?` | 确定时返回日期分量 |

控制器公开只读的 `contentView`、`pickerView` 和 `headerView`，可以直接配置面板高度、滚轮和头部样式。`automaticallyDismisses` 默认 `false`，设为 `true` 后，按钮回调会自动关闭弹层。`topCornerRadius` 控制顶部圆角，`dimmingColor` 控制遮罩颜色。底部安全区从本次呈现的容器计算。

一次展示只发送一次确认或取消结果。控制器直接被外部关闭时也会发送取消结果。可以用 `onResult` 接收 `.confirmed(Date)` 或 `.cancelled`，它在对应旧回调之后执行。旧的日期回调和日期分量回调均保留。

### 生日场景

```swift
let controller = JWDatePickerViewController()
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = .current
try controller.apply(JWDatePickerConfiguration(
    type: .date,
    selectedDate: savedBirthday ?? Date(),
    minimumDate: calendar.date(from: DateComponents(year: 1940, month: 1, day: 1)),
    maximumDate: Date(),
    calendar: calendar,
    locale: Locale(identifier: "zh_CN"),
    selectionPolicy: .startOfDay
))
controller.automaticallyDismisses = true
controller.topCornerRadius = 24
controller.contentView.headerHeight = 50
controller.contentView.pickerHeight = 216
controller.headerView.attributedTitle = NSAttributedString(
    string: "选择日期",
    attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
)
controller.headerView.cancelFont = .systemFont(ofSize: 14)
controller.headerView.confirmFont = .systemFont(ofSize: 14)
controller.pickerView.rowHeight = 40
controller.pickerView.columnWidth = { _, _ in 100 }
controller.pickerView.textAttributes = [.font: UIFont.systemFont(ofSize: 22)]
controller.confirmHandler = { date in
    // 在此保存生日。取消时沿用已有值。
}
present(controller, animated: true)
```

滚轮使用系统 `UIPickerView` 的选中区域背景，`lineColor` 控制额外绘制的上下分隔线。

`.startOfDay` 仅作用于 `.date`，使用配置日历所在时区的当天零点作为返回值，日期上下限也按同一日历日判断。默认 `.preserveComponents` 保留未展示的时、分、秒和小数秒。

### 嵌入已有弹层

安装 `JWDatePickerKit/Content`，把 `JWDatePickerContentView` 加入业务容器，使用其固有高度或设置与 `headerHeight + pickerHeight + 底部安全区` 一致的高度。它默认包含底部安全区，容器自行处理时可设 `includesBottomSafeArea = false`。

```swift
let panel = JWDatePickerContentView()
try panel.apply(configuration)
panel.pickerHeight = 216
panel.onResult = { result in
    switch result {
    case .confirmed(let date): print(date)
    case .cancelled: break
    }
}
```

每轮选择只发送一次 `onResult`。重新使用同一面板前调用 `beginSelection()`。独立面板的展示和关闭由业务容器处理。

## 嵌入页面用法

只需要滚轮选择器时，安装 `JWDatePickerKit/Picker` 即可。选择器是一个 `UIView`，可以使用 Auto Layout 加入页面。

```swift
import UIKit
import JWDatePickerKit

final class DateFormViewController: UIViewController {
    private let datePicker = JWDatePickerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.type = .date
        datePicker.selectDate = Date()
        datePicker.onDateChanged = { date in
            print("滚轮选择：", date)
        }
        view.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: datePicker.pickerViewHeight)
        ])
    }

    func saveDate() {
        guard let date = datePicker.currentSelectedDate() else { return }
        print("保存日期：", date)
    }
}
```

`onDateChanged` 在用户滚动并选中有效日期时调用。通过代码设置 `selectDate`、日期范围或模式会刷新滚轮，但不会调用该回调。可以随时通过 `currentSelectedDate()` 读取当前日期。确认时使用 `commitSelection()` 固定当前滚轮行并读取各列，控制器和完整面板已自动调用。

### 设置初始日期和范围

```swift
let calendar = Calendar.current
let now = Date()
let oneMonthLater = calendar.date(byAdding: .month, value: 1, to: now)

picker.minimumDate = now
picker.maximumDate = oneMonthLater
picker.selectDate = now

// 清除限制
picker.minimumDate = nil
picker.maximumDate = nil
```

- 设置日期、模式、范围、日历或语言环境时，选择器会自动刷新。也可以主动调用 `reloadDatas()`。设置范围和初始日期时，建议先设置范围，再设置初始日期。
- 初始日期超出有效范围时，当前选择会调整到最近的边界。
- 最小日期大于最大日期时，拒绝此次配置并保留上次有效的配置和选择。`configurationError` 返回 `.invalidDateRange`，下次配置成功后清空。更新成组边界时使用 `try picker.apply(JWDatePickerConfiguration(...))`，验证通过后整体应用，避免逐项赋值产生中间无效范围。控制器和完整面板也提供同名方法。
- 将 `selectDate` 设为 `nil` 后，选择器沿用当前选择，并在刷新时将该选择写回 `selectDate`。
- 年份模式未设置对应边界时，默认年份范围从 1900 至 2100。当前选中年份超出该范围时会扩展范围以包含它。
- 日期星期模式的日期列在未设置对应边界时，使用当前选择所在年的年初或年末。

### 日历、时区和语言

`calendar` 决定日期分量的计算方式，时区通过 `Calendar.timeZone` 设置。`locale` 用于月份、日期星期、数字、单位、模式名称以及弹窗标题和按钮文案。内置简繁中文、英语、日语、韩语、法语、德语、西班牙语与阿拉伯语，缺少翻译时回退到英文。可以使用 `localizedName(locale:)` 和 `localizedTitle(locale:)` 获取指定语言的模式名称与标题。滚轮默认按本地化文本测量列宽，并为日期星期列预留所需空间。

```swift
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
picker.calendar = calendar
picker.locale = Locale(identifier: "zh_CN")
```

选择器返回的是 `Date`，展示或保存为字符串时，应按业务需要设置格式化器的日历、时区和语言环境。

```swift
let formatter = DateFormatter()
formatter.calendar = calendar
formatter.timeZone = calendar.timeZone
formatter.locale = Locale(identifier: "zh_CN")
formatter.dateFormat = "yyyy-MM-dd HH:mm"

if let date = picker.currentSelectedDate() {
    print(formatter.string(from: date))
}
```

`Date` 包含完整的日期和时间。模式没有显示的日期分量保留在当前选择中。例如，`.time` 只显示时、分，返回值仍包含日期和秒。生日场景可以将 `selectionPolicy` 设为 `.startOfDay`，其余归零或替换需求可使用 `Calendar` 处理。

### 设置滚轮样式

```swift
picker.rowHeight = 44
picker.lineColor = .lightGray
picker.loopingComponents = [.hour, .minute]
picker.textAttributes = [
    .font: UIFont.systemFont(ofSize: 18),
    .foregroundColor: UIColor.gray
]
picker.selectedAttributes = [
    .font: UIFont.boldSystemFont(ofSize: 20),
    .foregroundColor: UIColor.black
]
```

| 属性或方法 | 说明 |
| --- | --- |
| `type` | 选择模式，默认 `.date` |
| `selectDate` | 初始或当前选择的日期 |
| `minimumDate`、`maximumDate` | 日期上下限 |
| `calendar` | 日期计算使用的日历，默认 `.current` |
| `locale` | 文本显示使用的语言环境，默认 `.current` |
| `rowHeight` | 滚轮行高，默认 40 点 |
| `loopingComponents` | 需要循环滚动的日期分量集合，默认为空集合 |
| `textAttributes` | 普通行文字属性，默认 20 点系统标签色字体 |
| `selectedAttributes` | 选中行文字属性，默认使用 `textAttributes` |
| `lineColor` | 选中区域分隔线颜色 |
| `pickerViewHeight` | 滚轮的固有高度，可用于布局 |
| `onDateChanged` | 用户选择日期后的回调 |
| `reloadDatas()` | 重新读取配置并刷新滚轮 |
| `currentSelectedDate()` | 返回当前选择的 `Date?` |

循环滚动按日期分量配置，不影响其他列。也可以使用 `setLooping(_:for:)` 和 `isLooping(for:)` 逐列切换或查询状态。

## 选择模式

弹层通过 `datePickerMode` 设置，嵌入式选择器通过 `type` 设置。两者均使用 `JWDatePickerType`。

| 模式 | 显示内容 |
| --- | --- |
| `.year` | 年 |
| `.yearAndMonth` | 年、月 |
| `.date` | 年、月、日 |
| `.dateHour` | 年、月、日、时 |
| `.dateHourMinute` | 年、月、日、时、分 |
| `.dateHourMinuteSecond` | 年、月、日、时、分、秒 |
| `.monthDay` | 月、日 |
| `.monthDayHour` | 月、日、时 |
| `.monthDayHourMinute` | 月、日、时、分 |
| `.monthDayHourMinuteSecond` | 月、日、时、分、秒 |
| `.time` | 时、分 |
| `.timeAndSecond` | 时、分、秒 |
| `.minuteAndSecond` | 分、秒 |
| `.dateWeekHourMinute` | 日期及星期、时、分 |

Swift 中的 `.dateAndTime` 是 `.dateWeekHourMinute` 的兼容别名。`JWDatePickerType.allCases` 可用于枚举所有模式，`name`、`stringFormat` 和 `section` 分别提供模式名称、参考日期格式和滚轮列数。

## 从旧版本迁移

### 从旧版 JWDatePickerKit 迁移

旧版控制器的 `datePickerMode` 使用 `PGDatePickerMode`。当前版本改用 `JWDatePickerType`，并移除了 PGDatePickerFix 和 PGPickerView 依赖。请删除代码中的 `import PGDatePicker`，并替换显式声明的类型。

```swift
// 旧写法
// import PGDatePicker
// let mode: PGDatePickerMode = .dateHourMinute

// 当前写法
import JWDatePickerKit
let mode: JWDatePickerType = .dateHourMinute
```

大多数模式名称相同。旧的 Swift `.dateAndTime` 调用可以继续使用，也可以改为 `.dateWeekHourMinute`。这一类型变更需要重新编译调用方。Objective-C 调用方需要使用 `JWDatePickerType`，日期星期模式对应 `JWDatePickerTypeDateWeekHourMinute`。

### 从独立 JWDatePickerView 迁移

将 Podfile 中的 `JWDatePickerView` 替换为 `JWDatePickerKit/Picker`，然后将 `import JWDatePickerView` 改为 `import JWDatePickerKit`。`JWDatePickerView`、`JWDatePickerType`、`reloadDatas()` 和 `currentSelectedDate()` 可在新模块中使用。原项目的辅助类型和协议未纳入新模块，直接使用过这些类型的代码需要调整。

## 运行示例

克隆仓库后，在项目根目录执行。

```bash
pod install
open JWDatePickerKit.xcworkspace
```

在 Xcode 中选择 `JWDatePickerKit-Example` scheme 和目标设备，运行示例。示例首行提供生日场景，可检查确认、取消和再次打开恢复选择，其余行列出全部 14 种模式。生日值保存在示例页面的内存中。

示例页面第二行是循环滚动演示，打开后小时和分钟列会循环滚动，其他日期分量保持普通滚轮行为。

## 作者与许可证

作者为 jw10126121，邮箱为 10126121@qq.com。

项目使用 MIT 许可证，具体内容请查看 [LICENSE](LICENSE)。
