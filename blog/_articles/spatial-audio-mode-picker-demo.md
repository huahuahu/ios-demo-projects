---
title: 用 SwiftUI 复刻空间音频模式选择器的连续 Liquid Glass 动画
description: 从一段参考录屏出发，用状态、稳定的 View 身份、几何插值和 iOS 26 Liquid Glass 复刻圆形按钮展开、模式切换与收起动画。
summary: 拆解 SwiftUI 如何让同一个玻璃外壳、选中圆和模式图标在收起与展开状态之间连续变形，并记录真实 Simulator 验证中发现的分层问题。
category: Investigation
tag: SwiftUI Animation
date: 2026-08-30
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/spatial-audio-mode-picker-demo
result_url: https://github.com/huahuahu/ios-demo-projects/blob/main/spatial-audio-mode-picker-demo/docs/animation-preview.mp4
---

## 我想复刻的不是一个静态控件

这次实验来自一段空间音频模式选择器的录屏。控件在收起时只是一个圆形按钮，点按后会横向展开成三个模式；继续选择不同模式，蓝色选中圆会在槽位之间滑动；再次点按当前模式，三个选项又会聚回中央并收起。

第一眼最容易注意到的是 iOS 26 的 Liquid Glass 材质，但真正让动画舒服的并不只是玻璃效果，而是几个对象在整个过程中都保持了连续身份：

- 圆形按钮和展开后的胶囊像是同一块材质被拉长；
- 选中背景不是三个圆互相淡入淡出，而是同一个圆在移动；
- 当前模式的图标不会消失再出现，而是从中央移动到自己的槽位；
- 位置、颜色、透明度和缩放发生在同一次状态变化中。

我没有尝试推断系统控件内部的私有实现。这个 Demo 只是根据录屏中可以观察到的运动关系，使用公开 SwiftUI API 复刻它的动画语言。

## 最终效果

下面的录屏包括完整的一轮展开、左右切换和收起：

<video controls muted playsinline preload="metadata" style="max-width: 100%; border-radius: 12px;">
  <source src="{{ '/spatial-audio-mode-picker-demo/assets/animation-preview.mp4' | relative_url }}" type="video/mp4">
  你的浏览器不支持直接播放这个视频，可以查看 Demo 目录中的录屏文件。
</video>

展开并选中“头部跟踪”后的状态如下：

![空间音频模式选择器展开并选中头部跟踪]({{ '/spatial-audio-mode-picker-demo/assets/head-tracking-expanded.jpg' | relative_url }})

Demo 的交互规则很短：点按紧凑按钮展开，点按其他模式切换，再次点按当前模式收起。实现时，我把这三个动作看成同一套状态机，而不是三个互不相关的动画。

## 状态只回答两个问题

`SpatialAudioPickerModel` 里只有两个核心状态：

```swift
@MainActor
@Observable
final class SpatialAudioPickerModel {
    private(set) var isExpanded: Bool
    private(set) var selectedMode: SpatialAudioMode
}
```

`isExpanded` 回答控件当前是展开还是收起，`selectedMode` 回答当前选中的模式。页面创建并拥有这个 Model：

```swift
struct SpatialAudioDemoScreen: View {
    @State private var model = SpatialAudioPickerModel()
}
```

点击逻辑也集中在 Model 中：

```swift
func handleTap(on mode: SpatialAudioMode) {
    guard isExpanded else {
        isExpanded = true
        return
    }

    if selectedMode == mode {
        isExpanded = false
    } else {
        selectedMode = mode
    }
}
```

因此三种操作分别变成：

1. 收起状态点按当前按钮：只修改 `isExpanded`，不修改选择。
2. 展开状态点按其他模式：只修改 `selectedMode`，继续保持展开。
3. 展开状态再次点按当前模式：只把 `isExpanded` 改回 `false`。

这里没有保存外壳宽度、选中圆坐标或每个图标的透明度。这些都是可以从两个业务状态推导出来的展示值。状态越少，多个动画属性越不容易互相失去同步。

## 关键判断：不要做两套控件

如果分别写一个 `CollapsedPicker` 和一个 `ExpandedPicker`，再用条件分支切换，SwiftUI 看到的通常是旧 View 被移除、新 View 被插入。即使加上 opacity 或 transition，也很容易得到“一个消失、另一个出现”的感觉。

这个 Demo 采用相反思路：外壳和选中圆长期存在，只改变它们的可动画属性。

结构可以简化成：

```text
SpatialAudioModePicker
├── GlassEffectContainer
│   ├── 同一个玻璃外壳
│   └── 同一个玻璃选中圆
├── 三个固定槽位中的图标按钮
└── 收起摘要 / 展开标签
```

SwiftUI 在状态改变后重新计算 `body`。只要对象在结构中的身份稳定，而 `frame`、`offset`、`tint`、`scale` 或 `opacity` 的目标值发生变化，动画事务就可以在旧值和新值之间插值。

## 同一个外壳从圆长成胶囊

外壳一直是一个 `Color.clear` 加 `glassEffect`：

```swift
Color.clear
    .frame(
        width: isExpanded ? 300 : 68,
        height: 68
    )
    .glassEffect(.regular.interactive(), in: .capsule)
```

Shape 始终是 `.capsule`，高度始终为 68 pt。收起时宽度也是 68 pt，所以它看起来是圆；展开时宽度变为 300 pt，看起来就是横向胶囊。

这不是圆形 View 和胶囊 View 的 crossfade，而是同一块玻璃的宽度从 68 变为 300。弹簧动画会连续改变 frame，Liquid Glass 则跟随 frame 重新塑形，于是得到一种材质被拉开的感觉。

整个控件的外层画布始终保持 300 pt 宽。变化的只是画布中央那块玻璃外壳，这样展开前后中心点不会漂移，也不会推动页面其他布局。

## 同一个选中圆沿三个槽位移动

选中状态同样没有为三个模式分别创建背景。`SpatialAudioSelectionIndicator` 是唯一一个 54 × 54 pt 的玻璃圆：

```swift
SpatialAudioSelectionIndicator(...)
    .offset(x: selectionOffset)
```

三个模式都有稳定的 `index`，槽位宽度是 92 pt。展开状态下，选中圆的位置通过一条公式得到：

```swift
Double(selectedMode.index - 1) * 92
```

对应关系是：

| 模式 | index | X offset |
| --- | ---: | ---: |
| 关闭 | 0 | -92 |
| 固定 | 1 | 0 |
| 头部跟踪 | 2 | +92 |

收起时 offset 固定为 0，选中圆回到控件中央。切换模式时，`selectedMode` 改变，SwiftUI 对 offset 的旧值和新值做插值，所以圆会沿同一条轨道连续滑动。

这里不需要三个独立背景，也不需要 `matchedGeometryEffect`。当目标只是一个对象在已知槽位间移动时，稳定对象加数值化 offset 会更直接。

## 颜色和位置在同一次变化中更新

选中圆的颜色也直接来自 `selectedMode`：

```swift
private var tint: Color {
    if mode.isSpatialAudioEnabled {
        .blue
    } else {
        .white.opacity(0.16)
    }
}
```

“固定”和“头部跟踪”都代表空间音频开启，因此使用蓝色；“关闭”使用低透明度的白色。选择“关闭”时，offset 和 tint 会在同一个动画事务中改变，于是选中圆一边向左移动，一边从蓝色过渡到灰色。

这也是状态驱动动画很方便的地方：代码只描述新状态下“它应该在哪里、是什么颜色”，不需要自己写逐帧颜色计算，也不用单独协调位移动画和颜色动画的开始时间。

## 图标为什么像从中央散开

图标层由三个固定宽度为 92 pt 的槽位组成：

```swift
HStack(spacing: 0) {
    ForEach(SpatialAudioMode.allCases) { mode in
        ZStack {
            if isExpanded || selectedMode == mode {
                SpatialAudioModeButton(...)
                    .offset(x: optionOffset(for: mode))
                    .transition(optionTransition(for: mode))
            }
        }
        .frame(width: 92, height: 68)
    }
}
```

展开时，每个按钮的额外 offset 都是 0，它们自然位于左、中、右三个槽位。收起时只保留当前按钮，并使用下面的公式把它移动到整体中央：

```swift
Double(1 - mode.index) * 92
```

例如左侧按钮本来位于 -92，再增加 +92 后正好回到 0；右侧按钮本来位于 +92，增加 -92 后同样回到 0。无论当前选择哪一种模式，收起后的图标都落在控件中央。

展开时，当前图标从中央移动回自己的槽位，另外两个图标通过组合 transition 出现：

```swift
.offset(...)
.combined(with: .scale(scale: 0.72))
.combined(with: .opacity)
```

所以视觉结果不是三个按钮突然出现，而是它们从中央附近向两侧散开，同时由小变大、由透明变清晰。

固定槽位始终存在，但收起时透明按钮本身并不存在。这一点除了让布局稳定，也避免 VoiceOver 或点击系统在中央发现三个重叠的按钮。

## 为展开和切换使用不同的节奏

外壳展开包含明显的尺寸变化，需要稍长一点的动画；选中圆左右切换则应该更干脆。Demo 为它们设置了两套 spring：

```swift
static let expansionAnimation = Animation.spring(
    response: 0.34,
    dampingFraction: 0.82
)

static let selectionAnimation = Animation.spring(
    response: 0.24,
    dampingFraction: 0.86
)
```

点击时根据动作选择动画：

```swift
withAnimation(
    model.isExpanded && model.selectedMode != mode
        ? SpatialAudioDesign.selectionAnimation
        : SpatialAudioDesign.expansionAnimation
) {
    model.handleTap(on: mode)
}
```

展开和收起使用 `expansionAnimation`，已经展开时选择其他模式使用更快的 `selectionAnimation`。标签没有继续使用 spring，而是用 0.16 秒 `easeOut` 做透明度和缩放切换，避免整个控件的所有元素同时弹跳。

按钮按下时还会缩放到 0.9、透明度降到 0.62；选中变化通过 `.symbolEffect(.bounce.byLayer, value: isSelected)` 添加一次轻微 follow-through，并用 `.sensoryFeedback(.selection, trigger: selectedMode)` 提供选择反馈。这些都是次级细节，主运动仍然由外壳和选中圆承担。

## 实际运行后发现：玻璃层和图标层要分开

最初实现把图标也放进 `GlassEffectContainer`。代码逻辑没有问题，但在 Simulator 截图中，SF Symbols 会受到玻璃前景折射影响，边缘显得不够清晰。

最终层级调整为：

- `GlassEffectContainer` 只包含外壳和选中圆，让两块玻璃共享容器并产生连续材质效果；
- 三个图标按钮放在更高的独立层，用普通白色前景渲染；
- 标签放在控件下方，不参与玻璃融合。

这次修改不是从 API 名称推断出来的，而是根据真实 Simulator 截图做出的视觉迭代。Liquid Glass 负责材质，清晰的图标层负责信息；把所有内容都塞进玻璃容器，并不会自动得到更好的效果。

## Reduce Motion 和 VoiceOver 不能最后再补

模式选择器包含明显的大范围位移，所以 Demo 读取了 `accessibilityReduceMotion`：

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

开启 Reduce Motion 后，外壳宽度、选中圆位置和图标散开不再执行 spring 动画，Symbol bounce 也会通过 `.symbolEffectsRemoved(reduceMotion)` 被移除。标签只保留约 0.12 秒的透明度切换，不再执行明显位移和缩放。

颜色也不是唯一的选中线索。开启“无需颜色区分”后，选中圆会增加白色描边：

```swift
Circle()
    .strokeBorder(
        differentiateWithoutColor ? Color.white : Color.clear,
        lineWidth: 2
    )
```

图标按钮使用带文本的 `Label`，视觉上通过 `.labelStyle(.iconOnly)` 只显示图标，但 VoiceOver 仍能得到模式名称、当前选中状态和操作提示。收起时只有当前按钮可访问，展开后才暴露三个模式按钮。

## 验证什么，不能只看 Build 成功

这个效果的主要风险不是编译错误，而是动画对象身份、图层顺序和可访问性树是否符合预期。因此验证分成几层：

- 单元测试验证三种点击规则，以及模式的稳定顺序和激活语义；
- XcodeBuildMCP 最终运行 5 个测试，结果为 5 passed、0 failed；
- Demo 在专用 `iPhone 17 Pro Max`、iOS 26.5 Simulator 上完成 Build & Run；
- 实际交互检查了展开、左右切换、蓝灰变色和收起；
- 逐帧查看录屏，确认外壳和选中圆没有通过不连续的淡入淡出“换对象”；
- UI 自动化检查收起状态只有一个按钮，展开后有三个模式按钮。

测试通过只能证明状态逻辑没有破坏；Build & Run 只能证明 App 可以运行；玻璃折射是否让图标发糊、弹簧节奏是否自然，仍然需要真实的 Simulator 画面来判断。

## 我学到的核心结论

第一，复刻这类动画时，先识别哪些视觉元素在用户眼中是“同一个东西”。保持这些 View 的结构身份，再动画可插值属性，通常比创建多套状态 View 更自然。

第二，布局最好可以写成公式。三个槽位的选中位置是 `(index - 1) × slotWidth`，收起时的图标补偿是 `(1 - index) × slotWidth`。当位置来自模式顺序，而不是一堆独立 magic number，展开、切换和收起会自然互为逆过程。

第三，动画节奏应该跟动作语义一致。容器展开需要表现材质形变，允许稍长的 spring；模式切换只是短距离选择，应该更快；标签只需要淡出淡入，不必抢主动画的注意力。

最后，Liquid Glass 是材质层，不是动画设计本身。真正建立连续感的是稳定的对象身份、少量状态、统一的几何关系和同步的动画事务。把这些关系处理清楚后，`glassEffect` 才会成为加分项，而不是掩盖结构问题的滤镜。

完整工程位于 `spatial-audio-mode-picker-demo`。运行后可以依次尝试“关闭 → 固定 → 头部跟踪 → 收起”，观察同一个选中圆的位置和 tint 如何随 `selectedMode` 同步变化。
