# SwiftUI Shape/View/Style/Color Demo 设计

## 目标

创建一个聚焦的 iOS demo project，用来说明 SwiftUI 里 `Shape`、`View`、`Style` / `ShapeStyle` 和 `Color` 之间的关系。这个 demo 会作为博客配套示例：读者应当能在第一屏理解概念层级，再通过小型交互例子把关系具体化。

## 项目结构

- 目录：`swiftui-shape-view-style-color/`
- App 和 scheme：`SwiftUIShapeViewStyleColor`
- Bundle prefix：`com.huahuahu.demo`
- 工具链：XcodeGen，使用仓库标准的 `project.yml` 和 `.xcodebuildmcp/config.yaml`
- 最低平台：iOS 26.0，Swift 6.0

项目沿用仓库里的独立 demo 结构：

```text
swiftui-shape-view-style-color/
  README.md
  project.yml
  .xcodebuildmcp/config.yaml
  SwiftUIShapeViewStyleColor/
  SwiftUIShapeViewStyleColorTests/
```

## 用户体验

第一屏是一个紧凑的教学界面：

1. 关系图包含四张概念卡片：

`Shape`：描述几何形状，例如 `Circle`、`RoundedRectangle` 或自定义 shape。`View`：SwiftUI 可以放入层级并渲染出来的节点。`Style` / `ShapeStyle`：定义 shape 如何被填充、描边或绘制。`Color`：具体的颜色值，同时也可以作为一种 `ShapeStyle`。
2. 分段 picker 在三个实验之间切换：

`Shape becomes View`：展示 `Shape` 被当作 `View` 使用后，如何通过 `fill`、`stroke` 或 layout modifier 变得可见。`Style paints Shape`：切换填充和描边 style，说明几何形状和视觉外观是两个独立决策。`Color as ShapeStyle`：展示 `Color` 作为最简单的 `ShapeStyle`，并在有帮助时与 gradient 或 material 对比。

这个 demo 不做深层导航。读者应当能在一个屏幕里读懂主题，并在交互时始终看到核心关系。

## 架构

使用边界清晰的小型 SwiftUI 组件：

- `ContentView`：负责整体 layout 和少量选择状态。
- `RelationshipDiagram`：渲染概念关系图。
- `ConceptCard`：渲染单个概念及其短说明。
- `ExperimentPicker`：选择当前实验。
- `ShapeBecomesViewExperiment`、`StylePaintsShapeExperiment` 和 `ColorAsShapeStyleExperiment`：分别负责一个聚焦演示。
- `ConceptNode` 和 `Experiment`：纯 Swift model，供 UI 和测试复用。

状态只包含当前实验、当前 shape、当前 style 和当前 color。这些值使用 enum 或简单 value type 表达，因此非法 picker 状态不可表示。

## 数据流

用户选择会更新 `ContentView` 或当前 experiment view 里的本地 SwiftUI state。SwiftUI 重新计算 body，并把选中的值传给 shape/style 渲染 helper。这里不引入 router、持久化、网络或异步流程。

概念图和实验元数据来自静态 model data。这样教学文案可以被测试，也方便在不阅读 view hierarchy 的情况下检查关键关系。

## 错误处理

这个 demo 没有外部输入，也没有需要恢复的运行时失败。错误避免主要依赖 experiment、shape 和 style 的 type-safe enum。UI 不应依赖字符串匹配来控制流程。

## 测试

在 `SwiftUIShapeViewStyleColorTests` 中使用 Swift Testing 做聚焦检查：

- 概念节点按预期教学顺序出现。
- 每个概念都有非空说明。
- 每个实验都有 title、summary 和稳定 identity。
- 预期关系边存在：`Shape -> View`、`Style -> Shape` 和 `Color -> ShapeStyle`。

UI snapshot testing 不在这个 demo 的范围内。

## 验证

实现完成后：

1. 在 demo 目录运行 `xcodegen generate`。
2. 对生成的 project 使用 XcodeBuildMCP defaults。
3. 通过 XcodeBuildMCP `test_sim` 运行 simulator tests。

## 不包含的范围

- 完整 SwiftUI reference guide。
- 深层导航或多 app screen。
- 自定义绘制性能比较。
- 低于仓库当前 iOS 26 demo baseline 的兼容性工作。