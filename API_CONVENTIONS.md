# JW picker 系列 API 公约

JWDatePickerKit 与 JWTextPickerKit 对齐视图职责、选择状态、弹层交互和分发方式。

| 职责 | JWDatePickerKit | JWTextPickerKit |
| --- | --- | --- |
| UIKit 内联滚轮 | `JWDatePickerView` | `JWTextPickerView` |
| 可嵌入面板 | `JWDatePickerContentView` | `JWTextPickerContentView` |
| 底部弹层 | `JWDatePickerViewController` | `JWTextPickerViewController` |
| 头部视图 | `JWDatePickerMenuHeaderView` | `JWTextPickerMenuHeaderView` |
| 最终结果 | `JWDatePickerResult` | `JWTextPickerResult` |
| SwiftUI 内联视图 | `JWDatePicker(selection:)` | `JWTextPicker(selection:type:items:)` |
| SwiftUI 弹层 | `.jwDatePicker(isPresented:selection:)` | `.jwTextPicker(isPresented:selection:type:items:)` |

## 选择与结果

- 用 `type` 指定显示模式或列数，用 `selection` 设置选中值。日期使用 `Date`，文本的各级索引从 0 开始。
- 两库均用 `apply(_:)` 批量配置。日期传 `JWDatePickerConfiguration`，范围无效时抛出错误并保留上次配置。文本传 `JWTextPickerConfiguration`，索引自动收敛。
- 读取当前值用 `currentSelection()`，确认时用 `commitSelection()`。通过滚轮的 `onSelectionChanged` 监听已选项变化。
- 每轮通过 `onResult` 发送一次 `.confirmed` 或 `.cancelled`。UIKit 也提供 `confirmHandler` / `cancelHandler`。复用嵌入面板时用 `beginSelection()` 开始新一轮。
- `backgroundTapDismissEnable` 控制点背景关闭，`automaticallyDismisses` 控制确认和取消按钮是否自动关闭。两库均使用弹层所在容器的安全区。
- SwiftUI 弹层在确认时写回绑定的 `selection`。文本的 RxSwift 入口是 `rxShowTextPicker(items:selection:...)`，确认时返回 `JWTextPickerSelection`。

## 样式

两库默认使用 17 pt 滚轮文字、50 pt 行高、50 pt 头部、250 pt 滚轮和 24 pt 顶部圆角。选中框内用系统青色，框外用语义灰色。选中和未选中文字默认使用同一字体，头部和滚轮分隔线默认隐藏。

弹层都通过 `textColorOfSelectedRow`、`textColorOfOtherRow` 和 `topCornerRadius` 自定义外观。独立滚轮使用 `textAttributes` 和 `selectedAttributes`。文本库另外提供 `JWTextPickerStyle`。

## 安装

- 最低系统版本为 iOS 15。SwiftPM 提供 Swift 5.10 与 Swift 6 清单。
- CocoaPods 使用 `Core`、`Content`、`Controller` 和 `SwiftUI`。文本额外提供 `RxSwift`。带弹层的模块依赖 `JWDialogManager ~> 0.1.3`。
- SwiftPM 主产品使用 `JWDatePickerKit` / `JWTextPickerKit`，扩展附加 `SwiftUI` 或 `RxSwift` 后缀。现有短名和 CocoaPods 子模块别名可继续使用。
- 从旧文本库切换时，按照 JWTextPickerKit README 中的迁移表更新依赖、模型和调用。版本示例与各项目 podspec 同步。
