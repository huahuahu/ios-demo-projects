# Observation View Invalidation Demo

一个聚焦的 SwiftUI demo，用来验证 `@Observable` 属性变化后，父视图与三个子视图的 `init`、`body` 实际执行范围。

## Blog Topic

SwiftUI Observation 的属性访问追踪、视图失效边界，以及“重新构造 View 值”和“重新计算 body”的区别。

## What It Shows

- 实验 A：父视图只传递 model，三个子视图分别在自己的 `body` 中读取 `name`、`age`、`score`。
- 实验 B：父视图把 `name`、`score` 作为普通值传递，但用 `@Bindable` 生成 `$model.age`，把 `age` 作为 `Binding<Int>` 传递。
- 同一个按钮同时驱动两组实验，便于在日志中直接对比。
- model mutation、实验视图 `init` 和 `body` 日志统一带 `OBS-DEMO` 前缀。

## Requirements

- Xcode with iOS 26 SDK
- XcodeGen 2.46 or later
- XcodeBuildMCP for simulator validation

## Generate and Open

```bash
xcodegen generate
open ObservationViewInvalidationDemo.xcodeproj
```

## Run the Experiment

1. 运行 app。
2. 打开 Xcode Console 并搜索 `OBS-DEMO`。
3. 先点击任意属性一次，让首次布局与懒加载完成。
4. 清空已有日志。
5. 点击“姓名”“年龄”或“分数”中的一个按钮。
6. 对比 `DirectPropertyView[...]`、`ParentReadObservationSection`、`SnapshotPropertyView[...]` 与 `BindingAgePropertyView[age]` 的日志。

`INIT` 只表示 SwiftUI 重新构造了一个轻量的 `View` 值；`BODY` 表示重新计算视图描述。它们都不直接等于底层 UIKit view 被销毁或重建。

## Observed Result

原始普通值版本在 Xcode 26.5、iOS 26.5 Simulator 的稳定状态下，修改 `age` 得到：

```text
OBS-DEMO MODEL age: 18 -> 19
OBS-DEMO BODY  DirectPropertyView[age]
OBS-DEMO BODY  ParentReadObservationSection
OBS-DEMO INIT  SnapshotPropertyView[name]
OBS-DEMO INIT  SnapshotPropertyView[age]
OBS-DEMO INIT  SnapshotPropertyView[score]
OBS-DEMO BODY  SnapshotPropertyView[age]
```

这组日志说明：

- 实验 A 只有读取 `age` 的子视图 `body` 重新执行；三个子视图的 `init` 都没有执行。
- 实验 B 因为属性在父视图读取，父 `body` 重新执行，三个子视图的构造表达式都会运行，所以三个 `init` 都执行。
- 实验 B 中只有输入值变化的 `age` 子视图 `body` 执行；SwiftUI 在这次稳定更新中跳过了输入不变的 `name` 和 `score` 子视图 `body`。
- 首次布局、懒加载、环境变化等仍可能产生额外 `body` 调用。精确调用次数不是 SwiftUI API 契约。

去掉时间戳后的同一份日志保存在 `samples/age-mutation.log`。

当前版本把实验 B 的 `age` 改成 `Binding<Int>`。它使用 `@Bindable var model` 和 `$model.age`，没有使用手写的 `Binding(get:set:)`。稳定状态下再次修改 `age` 得到：

```text
OBS-DEMO MODEL age: 19 -> 20
OBS-DEMO BODY  DirectPropertyView[age]
OBS-DEMO BODY  ParentReadObservationSection
OBS-DEMO INIT  SnapshotPropertyView[name]
OBS-DEMO INIT  BindingAgePropertyView[age]
OBS-DEMO INIT  SnapshotPropertyView[score]
OBS-DEMO BODY  BindingAgePropertyView[age]
```

在当前 iOS 26.5 / SwiftUI 实现中，在父 `body` 中取得 `$model.age` 仍然让父视图依赖 `age`。因此父 `body` 和三个子视图的构造表达式仍会运行；SwiftUI diff 之后，只有真正读取变化值的 `BindingAgePropertyView[age].body` 执行，输入不变的 `name`、`score` 子视图 `body` 被跳过。

新的实测结果保存在 `samples/age-binding-mutation.log`。

## Test

```bash
xcodebuild test \
  -project ObservationViewInvalidationDemo.xcodeproj \
  -scheme ObservationViewInvalidationDemo \
  -destination 'platform=iOS Simulator,name=ObservationViewInvalidationDemo iPhone 17 Pro Max,OS=latest'
```

模型测试使用 Swift Testing，验证每个按钮只修改目标 observable 属性，并验证重置行为。

## Key Files

- `ObservationViewInvalidationDemo/Domain/ObservationDemoModel.swift`：三个 observable 属性与按钮操作。
- `ObservationViewInvalidationDemo/Features/ObservationFlow/DirectObservationSection.swift`：子视图直接读取属性的实验。
- `ObservationViewInvalidationDemo/Features/ObservationFlow/ParentReadObservationSection.swift`：父视图读取属性后传值的实验。
- `ObservationViewInvalidationDemo/Features/ObservationFlow/BindingAgePropertyView.swift`：通过 `Binding<Int>` 读取年龄的子视图。
- `ObservationViewInvalidationDemo/Support/DemoLifecycleLog.swift`：统一的 `OBS-DEMO` 日志入口。
- `ObservationViewInvalidationDemoTests/Domain/ObservationDemoModelTests.swift`：独立、可重复的模型测试。
- `samples/age-mutation.log`：一次稳定状态的实测日志样本。
- `samples/age-binding-mutation.log`：`age` 改为 Binding 后的实测日志样本。
