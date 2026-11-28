# JW picker 系列 API 公约

本公约同时适用于 `JWDatePickerKit` 与 `JWTextPickerManager`，目标是让两个库在命名、安装、回调和版本节奏上保持一致。改动遵循**零破坏**原则：新增名称先用起来，旧名称保留至少一个 minor 版本并标记 deprecated。

## 1. 命名公式

所有公开符号使用：`JW` + 域（`Date` / `Text`）+ 角色（`View` / `ContentView` / `ViewController` / `Configuration` / `Result`）+ 类型后缀。

| 角色 | JWDatePickerKit | JWTextPickerManager | 说明 |
| --- | --- | --- | --- |
| 内嵌滚轮 | `JWDatePickerView` | `JWTextPickerView`（旧 `JWPickerView`） | 可嵌入业务页面 |
| 可嵌入面板 | `JWDatePickerContentView` | `JWTextPickerContentView`（规划中） | 头部 + 滚轮 + 安全区 |
| 底部弹层 | `JWDatePickerViewController` | `JWTextPickerViewController`（旧 `JWPickerViewController`） | 依赖 JWDialogManager |
| 头部视图 | `JWDatePickerMenuHeaderView` | `JWTextPickerMenuHeaderView`（旧 `JWPickerMenuHeaderView`） | 取消 / 标题 / 确定 |
| 配置对象 | `JWDatePickerConfiguration` | `JWTextPickerConfiguration`（旧 `JWTextPickerViewConfig`） | 一次性应用配置 |
| 结果枚举 | `JWDatePickerResult` | `JWTextPickerResult` | `.confirmed` / `.cancelled` |
| 模式 / 列数 | `JWDatePickerType` | `JWTextPickerType`（旧 `JWTextPickerColumnsType`） | 统一属性名 `type` |
| 数据模型 | `Date` / `DateComponents` | `JWTextPickerItem`（旧 `PickerTextModel`）、`JWTextPickerItemProtocol` | 公开符号统一 JW 前缀 |

## 2. 属性与方法

- 模式属性统一叫 `type`。
- 选中值属性统一叫 `selection`。
- 配置统一通过 `apply(_:) throws` 一次性应用；失败时保留上一次有效配置。
- 提交滚轮位置统一用 `commitSelection()`，读取当前值用 `currentSelectedDate()` / `currentSelection()`。
- 一次性结果统一通过 `onResult`；便捷回调用 `confirmHandler` / `cancelHandler`。
- 点击背景关闭的属性统一为 `backgroundTapDismissEnable`。
- SwiftUI：内联视图用 `JW*Picker(selection:)`，弹层入口用 `.jw*Picker(...)`；对应模块产品名 `JW*SwiftUI`。
- RxSwift 扩展产品名统一为 `JW*RxSwift`，入口方法 `rxShow*Picker`。

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

旧式 `confirmCallBack` / `cancelCallBack` 继续生效，与新回调按「旧 → 新 → onResult」顺序触发，不会重复或丢失。

## 4. 安装与分发

- CocoaPods 源同时列 JWPublicSpecs 和官方 CDN；初始版本统一写 `~> 1.0`。
- SPM 地址统一为 Gitee 仓库；保留旧产品名，同时提供 `JW*Picker` / `JW*SwiftUI` / `JW*RxSwift` 新产品名。
- Pod 子模块统一为 `Core` / `Content` / `Controller` / `SwiftUI` / `RxSwift`；旧子模块名保留为只含依赖的别名。
- 最低系统版本 iOS 15；Swift 5.10 与 Swift 6 双工具链；公共弹层依赖 `JWDialogManager ~> 0.1.3`。
- 两个库版本号同步发布，README 版本号随 podspec 同步更新。

## 5. 迁移策略

1. 阶段一（1.2.x）：新名称与旧名称并存，旧名称标记 deprecated；文档全面切换到新名称。
2. 阶段二（2.0）：如业务侧完成迁移，再考虑移除旧名称，并把 `JWTextPickerManager` 改名为 `JWTextPickerKit`；届时旧 pod 以转发壳形式保留。
3. 任何阶段都不静默改变旧 API 的行为与回调次数。
