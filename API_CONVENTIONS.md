# JW 选择器共同 API 公约

本公约适用于 JWDatePickerKit 和 JWTextPickerKit。安装示例、选项构造和旧库迁移步骤见各自的 README。

## 组件与入口

| 职责 | JWDatePickerKit | JWTextPickerKit |
| --- | --- | --- |
| UIKit 内嵌滚轮 | `JWDatePickerView` | `JWTextPickerView` |
| 可嵌入面板 | `JWDatePickerContentView` | `JWTextPickerContentView` |
| 底部弹层 | `JWDatePickerViewController` | `JWTextPickerViewController` |
| 头部视图 | `JWDatePickerMenuHeaderView` | `JWTextPickerMenuHeaderView` |
| 批量配置 | `JWDatePickerConfiguration` | `JWTextPickerConfiguration` |
| 最终结果 | `JWDatePickerResult` | `JWTextPickerResult` |
| SwiftUI 内联 | `JWDatePicker(selection:type:)` | `JWTextPicker(selection:type:items:)` |
| SwiftUI 弹层 | `.jwDatePicker(isPresented:selection:type:)` | `.jwTextPicker(isPresented:selection:type:items:)` |

## 配置、读取和提交

| API | 含义 | 日期 | 文本 |
| --- | --- | --- | --- |
| `type` | 滚轮模式 | 日期或时间显示模式 | 显示一至三列 |
| `selection` | 设置选中位置，或作为 SwiftUI 绑定值 | `Date`，滚轮和配置允许传入 `nil` | 从 0 开始的 `(first, second, third)` 索引 |
| `apply(_:)` | 一次应用模式、数据和选择 | 验证日期范围，失败时抛出错误并保留上次有效配置 | 更新选项和索引，越界索引收敛到有效范围 |
| `currentSelection()` | 读取当前已同步的值 | `Date` | `JWTextPickerSelection?` |
| `commitSelection()` | 先同步滚轮位置，再返回最终值 | `Date` | `JWTextPickerSelection?` |
| `onSelectionChanged` | 响应滚轮发出的用户选中事件 | `Date` | `JWTextPickerSelection` |

`currentSelection()` 和 `commitSelection()` 在 UIKit 滚轮和弹层控制器上均可使用。直接设置配置或调用 `commitSelection()` 不会主动触发 `onSelectionChanged`。选中变化回调与弹层最终结果各自独立。

### 文本级联

- 每列索引相对于当前父项的子列表。父项发生滚轮选中变化时，后续列归零。一次 `apply(_:)` 可以指定整条路径。
- 有选项的列将索引收敛到有效范围。空列的索引为 `0`，相应选项为 `nil`。首列为空时，读取和提交均返回 `nil`。
- `.one` 返回首列选项，`.two` 最多返回前两列，`.three` 最多返回三列。即使数据树包含下级，隐藏列对应的结果字段也为 `nil`。这一规则适用于 UIKit、SwiftUI 和 RxSwift，包括兼容回调。索引配置仍可为隐藏列保留有效位置，便于恢复列数。

## 弹层结果和关闭

一轮选择最多产生一次最终结果。UIKit 控制器每次呈现时开始新一轮。业务方复用嵌入式面板时，先调用 `contentView.beginSelection()`。面板用 `confirmSelection()`、`cancelSelection()` 结束本轮，并通过 `result` 和 `onResult` 提供最终结果。

| 操作 | 本轮没有最终结果时 | UIKit 弹层关闭规则 |
| --- | --- | --- |
| 点击确认 | 提交滚轮位置并发送 `.confirmed`。文本首列为空时继续等待选择或取消 | 有确认结果且 `automaticallyDismisses` 为 `true` 时自动关闭 |
| 点击取消 | 发送 `.cancelled` | `automaticallyDismisses` 为 `true` 时自动关闭 |
| 点击背景 | `backgroundTapDismissEnable` 为 `true` 时发送 `.cancelled` | 允许时关闭 |
| 调用 UIKit 的 `dismiss` | 关闭完成后补发 `.cancelled` | 由调用方关闭 |

`backgroundTapDismissEnable` 默认开启，`automaticallyDismisses` 默认关闭。本轮已有最终结果时，后续关闭不会再次发送结果。UIKit 控制器先调用对应的 `confirmHandler` 或 `cancelHandler`，再调用控制器的 `onResult`。同时设置两种回调时，两者都会收到同一次操作。日期的 `confirmDateComponentsHandler` 使用配置中的日历，文本的 `backgroundTapCancelHandler` 是独立的背景点击通知。

SwiftUI 内联视图在用户选择后更新绑定，弹层在确认后写回绑定。用户取消时调用 `onCancel` 并保留绑定值。业务方将 `isPresented` 设为 `false` 时，弹层关闭且不触发业务取消回调。

文本的 RxSwift 入口为 `rxShowTextPicker(items:selection:...)`。确认时发出一个 `JWTextPickerSelection` 后完成。取消或无法呈现时直接完成。

## 默认外观

| 项目 | 默认值 |
| --- | --- |
| 滚轮文字 | 17 pt，选中和普通文字共用字体 |
| 选中与普通文字色 | 框内 `.systemTeal`，框外 `.secondaryLabel` |
| 行高、头部高度、滚轮高度 | 50 pt、50 pt、250 pt |
| 顶部圆角与底部安全区 | 24 pt，使用弹层所在容器的安全区 |
| 分隔线 | 头部和滚轮默认隐藏 |

选中色按选中框的几何边界实时裁切。同一行文字经过边界时，框内外可同时呈现不同颜色。控制器可通过 `textColorOfSelectedRow`、`textColorOfOtherRow` 和 `topCornerRadius` 调整外观。独立滚轮使用 `textAttributes` 和 `selectedAttributes`，选中属性覆盖普通属性的对应键。文本还提供 `JWTextPickerStyle`。

## 安装与导入

最低系统版本为 iOS 15。SwiftPM 提供 Swift 5.10 和 Swift 6 清单。

| 分发方式 | 产品或子模块 | 能力与导入 |
| --- | --- | --- |
| CocoaPods | `/Core` | 内嵌滚轮，导入对应的 `JW*PickerKit` |
| CocoaPods | `/Content` | 头部和可嵌入面板，包含 `Core`，导入对应的 `JW*PickerKit` |
| CocoaPods | `/Controller` | 底部弹层，包含 `Content`，是默认子模块，导入对应的 `JW*PickerKit` |
| CocoaPods | `/SwiftUI` | SwiftUI 内联和弹层，包含 `Controller`，导入对应的 `JW*PickerKit` |
| CocoaPods | `JWTextPickerKit/RxSwift` | 文本 RxSwift 弹层，包含 `Controller`，导入 `JWTextPickerKit` 和 `RxSwift` |
| SwiftPM | `JWDatePickerKit`、`JWTextPickerKit` | 包含 UIKit 滚轮、面板和弹层，导入同名模块 |
| SwiftPM | `JWDatePickerKitSwiftUI`、`JWTextPickerKitSwiftUI` | 包含 SwiftUI 内联和弹层，导入主模块及对应扩展模块 |
| SwiftPM | `JWTextPickerKitRxSwift` | 文本 RxSwift 弹层，导入 `JWTextPickerKit`、`JWTextPickerKitRxSwift` 和 `RxSwift` |

所有带 UIKit 弹层的产品使用 `JWDialogManager` 0.1.3 或以上且低于 0.2.0。CocoaPods 的 `Core` 和 `Content` 可单独集成。

## 兼容入口

| 范围 | 兼容入口 | 新代码使用 |
| --- | --- | --- |
| 日期读值和回调 | `currentSelectedDate()`、`onDateChanged` | `currentSelection()`、`onSelectionChanged` |
| 日期配置 | `selectedDate` 属性及初始化参数 | `selection` |
| 文本批量配置 | `apply(type:items:selection:)` | `apply(JWTextPickerConfiguration(...))` |
| 文本 SwiftUI | `items:` 在 `type:` 前的内联初始化器，旧参数顺序或三参数确认回调的弹层重载 | `selection:`、`type:`、`items:` 顺序和 `JWTextPickerSelection` 回调 |
| 文本 RxSwift | `selectedType:` 重载和结果元组 | `selection:` 和 `JWTextPickerSelection` |
| CocoaPods | `JWDatePickerKit/Picker`、`JWTextPickerKit/Base` | 日期 `/Core`、文本 `/Controller` |
| SwiftPM | 现有 `JWDatePicker`、`JWTextPicker` 及其扩展短名产品 | 带 `Kit` 的产品名，导入模块名与安装表一致 |

## 发布前检查

修改公约时同步更新两库。从任一仓库根目录运行 `sh scripts/check-api-conventions.sh ../另一个仓库` 校验两份文件，再运行两个示例的模拟器测试。发布前核对 podspec、安装示例和实际发布版本，并在迁移说明中列出行为变化。
