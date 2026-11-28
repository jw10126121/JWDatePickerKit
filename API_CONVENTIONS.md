# JW picker 系列 API 公约

本公约同时适用于 `JWDatePickerKit` 与 `JWTextPickerKit`，目标是让两个库在命名、安装、回调和版本节奏上保持一致。旧 `JWTextPickerManager` 1.x 遵循零破坏迁移；新 `JWTextPickerKit` 1.2.0 采用统一后的干净 API，不再保留旧别名。

## 1. 命名公式

所有公开符号使用：`JW` + 域（`Date` / `Text`）+ 角色（`View` / `ContentView` / `ViewController` / `Configuration` / `Result`）+ 类型后缀。

| 角色 | JWDatePickerKit | JWTextPickerKit | 说明 |
| --- | --- | --- | --- |
| 内嵌滚轮 | `JWDatePickerView` | `JWTextPickerView` | 可嵌入业务页面 |
| 可嵌入面板 | `JWDatePickerContentView` | `JWTextPickerContentView`（规划中） | 头部 + 滚轮 + 安全区 |
| 底部弹层 | `JWDatePickerViewController` | `JWTextPickerViewController` | 依赖 JWDialogManager |
| 头部视图 | `JWDatePickerMenuHeaderView` | `JWTextPickerMenuHeaderView` | 取消 / 标题 / 确定 |
| 配置对象 | `JWDatePickerConfiguration`（数据） | `JWTextPickerStyle`（样式） | 各自表达数据约束与外观样式 |
| 结果枚举 | `JWDatePickerResult` | `JWTextPickerResult` | `.confirmed` / `.cancelled` |
| 模式 / 列数 | `JWDatePickerType` | `JWTextPickerType` | 统一属性名 `type` |
| 数据模型 | `Date` / `DateComponents` | `JWTextPickerItem`、`JWTextPickerItemProtocol` | 公开符号统一 JW 前缀 |

## 2. 属性与方法

- 模式属性统一叫 `type`；旧 `datePickerMode` 保留为别名。
- 选中值属性统一叫 `selection`；旧 `selectedIndexs` 保留为别名。
- 配置统一通过 `apply(_:) throws` 一次性应用；失败时保留上一次有效配置。
- 提交滚轮位置统一用 `commitSelection()`，读取当前值用 `currentSelectedDate()` / `currentSelection()`。
- 一次性结果统一通过 `onResult`；便捷回调用 `confirmHandler` / `cancelHandler`。
- 点击背景关闭的属性统一为 `backgroundTapDismissEnable`。
- SwiftUI：内联视图用 `JWDatePicker(selection:)` / `JWTextPicker(selection:items:)`，弹层入口用 `.jwDatePicker(...)` / `.jwTextPicker(...)`；对应模块产品名 `JW*SwiftUI`。
- RxSwift 扩展产品名统一为 `JW*RxSwift`，入口方法 `rxShow*Picker(items:...)`。

## 3. 回调签名

```swift
public enum JWDatePickerResult {
    case confirmed(Date)
    case cancelled
}

public enum JWTextPickerResult {
    case confirmed(first: JWTextPickerItemProtocol, second: JWTextPickerItemProtocol?, third: JWTextPickerItemProtocol?)
    case cancelled
}

public var onResult: ((JWTextPickerResult) -> Void)?
public var confirmHandler: ((Selection) -> Void)?
public var cancelHandler: (() -> Void)?
```

确认与取消统一通过 `onResult` 上报，`confirmHandler` / `cancelHandler` 为便捷回调。

## 4. 安装与分发

- CocoaPods 源同时列 JWPublicSpecs 和官方 CDN；两个库首个发布版本均为 1.2.0，统一写 `~> 1.2`。
- SPM 产品名以 `JWDatePickerKit` / `JWTextPickerKit` 系列为主，`JWDatePicker` / `JWTextPicker` 等短名作为别名保留。
- Pod 子模块统一为 `Core` / `Content` / `Controller` / `SwiftUI` / `RxSwift`；旧子模块名保留为只含依赖的别名。
- 最低系统版本 iOS 15；Swift 5.10 与 Swift 6 双工具链；公共弹层依赖 `JWDialogManager ~> 0.1.3`。
- 两个库版本号同步发布，README 版本号随 podspec 同步更新。

## 5. 迁移策略

1. 阶段一（旧库 1.2.x）：新名称与旧名称并存，旧名称标记 deprecated；文档全面切换到新名称。
2. 阶段二（新库 1.2.0）：`JWTextPickerKit` 以干净 API 发布，以 `JWTextPickerViewController` 为唯一主入口；旧 `JWTextPickerManager` pod 与仓库保留给存量用户。
3. 任何阶段都不静默改变旧 API 的行为与回调次数。
