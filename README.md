# JWDatePickerKit

iOS 日期时间选择器，支持 UIKit 页面内嵌、底部弹层和 SwiftUI。与 `JWTextPickerKit` 共用同一套 [API 公约](API_CONVENTIONS.md)。

**环境要求**　iOS 15+。Swift 5.10（Xcode 15.3+）或 Swift 6（Xcode 16+）。

## 安装

### Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，输入：

```text
https://gitee.com/jw10126121/JWDatePickerKit.git
```

版本选择 `1.2.0` 或更新版本。产品按用途选择：

| 用法 | 产品 | 导入模块 |
| --- | --- | --- |
| UIKit 内嵌与底部弹层 | `JWDatePickerKit` | `JWDatePickerKit` |
| SwiftUI | `JWDatePickerKitSwiftUI` | `JWDatePickerKitSwiftUI` |

短名产品 `JWDatePicker` / `JWDatePickerSwiftUI` 也可用。

### CocoaPods

```ruby
source 'https://gitee.com/jw10126121/JWPublicSpecs.git'
source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'
use_frameworks!

target 'YourApp' do
  pod 'JWDatePickerKit', '~> 1.0'
  # 使用 SwiftUI 时添加
  # pod 'JWDatePickerKit/SwiftUI', '~> 1.0'

  # 使用 Xcode 15 时取消下一行的注释
  # supports_swift_versions '~> 5.0'
end
```

执行 `pod install` 后打开生成的 `.xcworkspace`。

| 子模块 | 适用场景 |
| --- | --- |
| `JWDatePickerKit/Core` | 在 UIKit 页面内嵌滚轮 |
| `JWDatePickerKit/Content` | 在自己的弹层容器中嵌入头部与滚轮面板 |
| `JWDatePickerKit/Controller`（默认） | 带 JWDialogManager 转场的底部弹层 |
| `JWDatePickerKit/SwiftUI` | 在 SwiftUI 中绑定日期 |

旧子模块名 `JWDatePickerKit/Picker` 保留为 `Core` 的别名。所有子模块都使用 `import JWDatePickerKit`。

## UIKit

### 页面内嵌

```swift
import UIKit
import JWDatePickerKit

let picker = JWDatePickerView()
picker.type = .date
picker.selection = Date()
picker.onDateChanged = { date in print(date) }

// 高度使用 picker.pickerViewHeight，读取当前值用 currentSelectedDate()
```

用 `type` 切换模式，例如 `.yearAndMonth`、`.dateHourMinute`、`.time`。点击页面自己的确定按钮时调用 `commitSelection()`，从滚轮当前位置取得最终日期。

### 底部弹层

```swift
let picker = JWDatePickerViewController()
picker.type = .dateHourMinute
picker.selection = Date()
picker.automaticallyDismisses = true
picker.confirmHandler = { date in print(date) }
picker.cancelHandler = { print("已取消") }
picker.onResult = { result in
    switch result {
    case .confirmed(let date): print(date)
    case .cancelled: break
    }
}
present(picker, animated: true)
```

`onResult` 是确认与取消的统一入口，`confirmHandler` / `cancelHandler` 是便捷回调。模式、选中值与点击背景关闭分别使用 `type`、`selection` 与 `backgroundTapDismissEnable`。

如果页面已有弹层容器，可嵌入 `JWDatePickerContentView`，复用同一面板时在开始新一轮选择前调用 `beginSelection()`。

## SwiftUI

```swift
import SwiftUI
import JWDatePickerKitSwiftUI

struct DateForm: View {
    @State private var date = Date()

    var body: some View {
        JWDatePicker(selection: $date, type: .date)
        Text(date, style: .date)
    }
}
```

也可以通过 `.jwDatePicker` 以底部弹层呈现：

```swift
struct DateForm: View {
    @State private var date = Date()
    @State private var showPicker = false

    var body: some View {
        Button("选择日期") { showPicker = true }
            .jwDatePicker(isPresented: $showPicker, selection: $date, type: .date) { selected in
                print(selected)
            }
    }
}
```

通过 CocoaPods 安装时改为 `import JWDatePickerKit`。可用 `minimumDate`、`maximumDate` 限制范围，用 `locale` 指定显示语言。

## 配置与自定义

需要同时更新日期、上下限和日历时，推荐一次调用 `apply(_:)`：

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

滚轮样式通过 `rowHeight`、`lineColor`、`textAttributes`、`selectedAttributes`、`loopingComponents` 设置；弹层外观通过 `topCornerRadius`、`dimmingColor`、`contentView.headerHeight` 和 `contentView.pickerHeight` 设置。

## 本地调试

克隆本仓库与 [JWDialogManager](https://gitee.com/jw10126121/JWDialogManager) 到同一父目录，在仓库根目录运行 `pod install`，打开 `JWDatePickerKit.xcworkspace`，选择 `JWDatePickerKit-Example` scheme。业务项目中可把版本号替换为 `pod 'JWDatePickerKit', :path => '../JWDatePickerKit'`。

切换 Swift 6 语言模式时，在构建命令末尾加 `SWIFT_VERSION=6.0`。

## 常见问题

- 找不到版本：检查 Podfile 源，执行 `pod install --repo-update`。
- `onDateChanged` 只由用户滚动触发；代码设置初始值后请用 `currentSelectedDate()` 读取。
- 日期超出范围会调整到最近边界；上下限顺序有误时保留上次有效设置，可检查 `configurationError`。

## 许可证

[MIT](LICENSE)
