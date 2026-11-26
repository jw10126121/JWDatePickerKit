# JWDatePickerKit

[![CI Status](https://img.shields.io/travis/10126121@qq.com/JWDatePickerKit.svg?style=flat)](https://travis-ci.org/10126121@qq.com/JWDatePickerKit)
[![Version](https://img.shields.io/cocoapods/v/JWDatePickerKit.svg?style=flat)](https://cocoapods.org/pods/JWDatePickerKit)
[![License](https://img.shields.io/cocoapods/l/JWDatePickerKit.svg?style=flat)](https://cocoapods.org/pods/JWDatePickerKit)
[![Platform](https://img.shields.io/cocoapods/p/JWDatePickerKit.svg?style=flat)](https://cocoapods.org/pods/JWDatePickerKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

JWDatePickerKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'JWDatePickerKit'
```

## Author

jw10126121, 10126121@qq.com

## License

JWDatePickerKit is available under the MIT license. See the LICENSE file for more info.

## 模块与升级

CocoaPods 默认安装选择器和弹层控制器。只需嵌入滚轮时，可以单独安装 Picker 子模块。

```ruby
pod 'JWDatePickerKit'           # Picker 和 Controller
pod 'JWDatePickerKit/Picker'    # 仅选择器
```

两个子模块使用同一个 Swift 模块名 `JWDatePickerKit`。`Controller` 依赖 `Picker` 和 XBDialog，`Picker` 不依赖第三方库。项目不再依赖 PGDatePickerFix 和 PGPickerView。子模块是同一个 Pod 的安装选项，现有的独立 `JWDatePickerView` Pod 不会自动更新或重定向。

```swift
import JWDatePickerKit

let picker = JWDatePickerView()
picker.type = .dateHourMinute
picker.selectDate = Date()
picker.minimumDate = Date()
picker.onDateChanged = { date in
    print(date)
}
// 将 picker 加入视图层级并设置约束。
```

`selectDate` 为 nil 时使用当前选择。设置最小或最大日期会将当前选择限制在有效范围内，设回 nil 可以移除该限制。最小日期大于最大日期时暂时忽略两个限制。未显示的日期分量保留在当前日期中，选择器使用其 `calendar` 和 `locale` 配置。日期星期模式在未设置相应边界时使用当前选中日期所在年的起止日期。

### 从旧控制器迁移

`datePickerMode` 的类型由 `PGDatePickerMode` 改为 `JWDatePickerType`，请移除 `import PGDatePicker` 并替换显式类型引用。大部分枚举成员名称相同，旧的 `.dateAndTime` 可以通过 Swift 别名继续使用，也可以改为 `.dateWeekHourMinute`。此变更需要重新编译，使用 Objective-C 的调用方应将枚举类型改为 `JWDatePickerType`，对应日期星期模式为 `JWDatePickerTypeDateWeekHourMinute`。

从独立 `JWDatePickerView` 迁移时，将 Pod 和 `import JWDatePickerView` 改为上述 Picker 子模块和 `import JWDatePickerKit`。公开的 `JWDatePickerView`、`JWDatePickerType`、`reloadDatas()` 和 `currentSelectedDate()` 仍可使用。原项目中的辅助类型和协议未纳入此模块。
