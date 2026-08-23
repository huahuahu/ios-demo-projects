# SwiftUI Today Story Demo

## 展示内容

最低运行系统为 iOS 26，使用从 iOS 18 引入的 SwiftUI 系统导航转场，把 `LazyVStack` 中任意 Story 卡片连续放大为可滚动详情，并支持系统 interactive pop 的取消与完成。稳定的 `Story.ID` 同时交给来源和目标，保证滚动后仍回到正确卡片。

详情使用 iOS 26 横向 `ScrollView`、`scrollTargetBehavior(.paging)` 与 `scrollPosition(id:)` 左右切换 Story。当前 page ID 动态驱动 `navigationTransition(.zoom(sourceID:in:))`；切页时，被详情覆盖的列表会无动画滚到当前来源卡片，因此从任意页使用关闭按钮或系统返回，都会缩回当前页对应卡片。工程没有添加 `DragGesture`、透明 hit-test surface 或自定义手势优先级，让 `NavigationStack` 与横向 ScrollView 使用系统默认仲裁。

Reduce Motion 由系统导航转场自动适配；界面使用语义字体、动态颜色、SF Symbols 和最小 44pt 控件。

第一张 Story 使用工程内的 `Resources/story-motion.mp4`。`StoryPlaybackStore` 在卡片和详情之外持有同一个 `AVQueuePlayer` / `AVPlayerLooper`，两个 `AVPlayerLayer` renderer 共享播放时间轴；push、pop 或 interactive pop 取消时都不会重建 `AVPlayerItem` 或 seek。系统关闭 Video Auto-Play 时保持暂停。

详情顶部媒体滚出屏幕后返回时，系统不会先修改 `ScrollView` 的位置；当前可见 viewport 整体缩回来源卡片。interactive pop 取消后仍保留原来的 scroll offset。工程没有添加 full-screen drag，只使用 `NavigationStack` 自带的左边缘返回手势。

公开 SwiftUI zoom API 没有承诺 transition representation 一定逐帧采样 live video。因此本 Demo 能保证共享播放时钟不暂停，并已在当前 Simulator 观察到画面持续变化；不能把这一现象当成所有 iOS 版本上的 API 合约。

## 环境

- Xcode 26+
- Swift 6
- iOS 26+
- XcodeGen 2.46+

## 生成与运行

```bash
xcodegen generate
open SwiftUITodayStoryDemo.xcodeproj
```

Scheme：`SwiftUITodayStoryDemo`

## 代码导览

- `Domain/Story.swift`：稳定 ID 与本地样例数据。
- `Features/StoryList/`：`NavigationStack`、`NavigationLink`、来源卡片。
- `Features/StoryDetail/`：zoom 目标、长内容与关闭按钮。
- `Support/StoryPlaybackStore.swift`：稳定播放器 owner 和循环播放。
- `Support/PlayerLayerView.swift`：SwiftUI 中的 `AVPlayerLayer` renderer。
- `Support/StoryPalette.swift`：适配 Dark Mode 的本地渐变。

## 验证产物

- 首页：`artifacts/swiftui-home.jpg`
- 详情：`artifacts/swiftui-detail.jpg`
- video、详情滚动、左滑取消与返回：`artifacts/swiftui-video-scroll-interactive-pop.mp4`
- XcodeBuildMCP：2 tests passed，0 failed（unit + XCUITest）
