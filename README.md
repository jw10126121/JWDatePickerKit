# JWDatePickerKit

iOS 日期时间选择器，支持 UIKit 页面内嵌、底部弹层和 SwiftUI。要求 iOS 15+、Swift 5.10（Xcode 15.3+）或 Swift 6（Xcode 16+）。

## 安装

### CocoaPods

```ruby
source 'https://gitee.com/jw10126121/JWPublicSpecs.git'
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'JWDatePickerKit', '1.0.1'
  # 使用 SwiftUI 选择器时添加
  # pod 'JWDatePickerKit/SwiftUI', '1.0.1'
end
```

使用 Swift 5 工具链时，在 `target` 内加上 `supports_swift_versions '~> 5.0'`。如果项目还有其他来自 CocoaPods 官方源的依赖，请同时保留 `source 'https://cdn.cocoapods.org/'`。执行 `pod install` 后打开生成的 `.xcworkspace`。

默认安装包含 UIKit 滚轮和底部弹层。也可以按需选用子模块，版本号同上。

| 子模块 | 适用场景 |
| --- | --- |
| `JWDatePickerKit/Picker` | 在 UIKit 页面内嵌滚轮 |
| `JWDatePickerKit/Content` | 在自己的弹层容器中嵌入带标题、取消和确定按钮的面板 |
| `JWDatePickerKit/SwiftUI` | 在 SwiftUI 页面中绑定日期 |

CocoaPods 的各子模块都使用 `import JWDatePickerKit`。

### Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，输入 `https://gitee.com/jw10126121/JWDatePickerKit.git`，选择 `1.0.1` 或更新版本。

- UIKit 添加 `JWDatePickerKit` 产品，包含滚轮和弹层。
- SwiftUI 添加 `JWDatePickerKitSwiftUI` 产品。

## UIKit

### 嵌入页面

```swift
import UIKit
import JWDatePickerKit

final class DateViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let picker = JWDatePickerView()
        picker.type = .date
        picker.selectDate = Date()
        picker.onDateChanged = { date in
            print(date)
        }

        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            picker.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            picker.heightAnchor.constraint(equalToConstant: picker.pickerViewHeight)
        ])
    }
}
```

用 `type` 切换模式，例如 `.yearAndMonth`、`.dateHourMinute` 或 `.time`。用 `currentSelectedDate()` 读取当前值。如果页面有自己的确定按钮，点击时可调用 `commitSelection()`，从当前滚轮位置取得最终日期。

### 底部弹层

在 `UIViewController` 的方法中展示选择器。

```swift
let picker = JWDatePickerViewController()
picker.datePickerMode = .dateHourMinute
picker.defaultDate = Date()
picker.automaticallyDismisses = true
picker.confirmHandler = { date in
    print(date)
}
present(picker, animated: true)
```

用 `cancelHandler` 处理取消。如果希望在同一个回调里区分确认和取消，可改用 `onResult`，处理 `.confirmed(Date)` 和 `.cancelled`。

如果页面已有弹层容器，可以嵌入 `JWDatePickerContentView`，使用 `onResult` 接收结果。复用同一面板时，开始下一次选择前调用 `beginSelection()`。

## SwiftUI

```swift
import SwiftUI
import JWDatePickerKitSwiftUI

struct DateForm: View {
    @State private var date = Date()

    var body: some View {
        VStack {
            JWDatePicker(selection: $date, type: .date)
            Text(date, style: .date)
        }
    }
}
```

通过 CocoaPods 安装时，将 `import JWDatePickerKitSwiftUI` 改为 `import JWDatePickerKit`。使用 `minimumDate` 和 `maximumDate` 限制范围，通过 `locale` 指定显示语言。

## 自定义

### 日期范围、时区和语言

`minimumDate` 和 `maximumDate` 可以单独设置，传入 `nil` 清除对应限制。需要同时更新日期、上下限和日历时，推荐一次调用 `apply(_:)`。下面是 UIKit 的生日选择示例，`picker` 可以是 `JWDatePickerView` 或 `JWDatePickerViewController`。

```swift
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
let now = Date()

do {
    try picker.apply(JWDatePickerConfiguration(
        type: .date,
        selectedDate: calendar.date(byAdding: .year, value: -18, to: now),
        minimumDate: calendar.date(from: DateComponents(year: 1900, month: 1, day: 1)),
        maximumDate: now,
        calendar: calendar,
        locale: Locale(identifier: "zh_CN"),
        selectionPolicy: .startOfDay
    ))
} catch {
    print("日期范围设置失败：\(error)")
}
```

在 `.date` 模式下，`.startOfDay` 按配置的时区返回当天起始时间。展示结果时，可让格式化器使用同一时区。

### 滚轮样式与循环滚动

在内嵌滚轮上设置样式，或通过弹层控制器的 `pickerView` 设置。

```swift
picker.type = .time
picker.rowHeight = 44
picker.lineColor = .separator
picker.loopingComponents = [.hour, .minute]
picker.textAttributes = [
    .font: UIFont.systemFont(ofSize: 18),
    .foregroundColor: UIColor.secondaryLabel
]
picker.selectedAttributes = [
    .font: UIFont.boldSystemFont(ofSize: 20),
    .foregroundColor: UIColor.label
]
```

### 弹层外观

在调用 `present` 前设置圆角、高度和标题。这里的 `controller` 是 `JWDatePickerViewController`。

```swift
controller.topCornerRadius = 20
controller.contentView.headerHeight = 52
controller.contentView.pickerHeight = 216
controller.headerView.attributedTitle = NSAttributedString(string: "选择出发时间")
```

## 本地调试

克隆本仓库和 [JWDialogManager](https://gitee.com/jw10126121/JWDialogManager) 到同一个父目录，JWDialogManager 使用 `0.1.2` 或兼容版本。在本仓库根目录运行 `pod install`，打开 `JWDatePickerKit.xcworkspace`，选择 `JWDatePickerKit-Example` scheme 和 iOS 模拟器。示例包含生日选择、循环滚动和各日期模式，可直接验证自定义效果。

要在业务项目中调试本地源码，CocoaPods 可将 Podfile 中的版本号替换为路径。SwiftPM 可在 Xcode 中添加本地包。

```ruby
pod 'JWDatePickerKit', :path => '../JWDatePickerKit'
```

### 运行测试

在 Xcode 中选中示例 scheme 后按 `⌘U`。也可在终端运行，先用 `xcrun simctl list devices booted` 获取模拟器 ID。

```bash
xcodebuild test -workspace JWDatePickerKit.xcworkspace \
  -scheme JWDatePickerKit-Example \
  -destination 'platform=iOS Simulator,id=<模拟器 ID>'
```

示例默认使用 Swift 5 模式。使用 Swift 6 工具链时，在命令末尾加上 `SWIFT_VERSION=6.0` 即可切换模式。

### 常见问题

- 安装时找不到版本，可检查 Podfile 中的源，再运行 `pod install --repo-update`。
- 通过代码设置初始值后，可用 `currentSelectedDate()` 读取实际值。`onDateChanged` 由用户滚动触发。
- 日期超出范围时会调整到最近的边界。上下限顺序有误时会保留上次有效设置，可检查 `configurationError`。

## 许可证

[MIT](LICENSE)
