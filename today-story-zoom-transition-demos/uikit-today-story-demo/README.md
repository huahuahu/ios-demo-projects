# UIKit Today Story Demo

## 展示内容

最低运行系统为 iOS 26，使用 `UICollectionViewDiffableDataSource` 展示 Story 卡片，并通过同一个 `UINavigationController` push 到详情。从 iOS 18 引入的 `UIViewController.Transition.zoom(options:sourceViewProvider:)` 提供连续、可取消的 interactive pop。

详情使用 `UIPageViewController` 左右切换 Story。完成切页后会更新 `currentStory`；zoom `sourceViewProvider` 在每次返回开始时读取当前 ID，并动态恢复/查询对应 Cell。工程没有添加 hit-test 容器、自定义返回 recognizer、gesture delegate 或 failure requirement，也没有通过 `interactiveDismissShouldBegin` 人为限制返回区域；横向分页与 iOS 26 navigation pop 使用系统默认仲裁。

`sourceViewProvider` 每次都根据稳定 `Story.ID` 查询当前 Cell；来源离屏时先无动画滚回并重新获取 Cell，仍失败则返回 `nil`，让系统安全退化而不崩溃。Reduce Motion 开启时使用系统 cross-dissolve。

第一张 Story 使用工程内的 `Resources/story-motion.mp4`。`StoryPlaybackStore` 在 Cell 和详情控制器之外持有同一个 `AVQueuePlayer` / `AVPlayerLooper`，来源和目标的 `AVPlayerLayer` 共享播放时间轴；复用 Cell 时只 detach renderer，不 pause、seek 或替换 `AVPlayerItem`。系统关闭 Video Auto-Play 时保持暂停。

详情 hero 已经滚出屏幕后，pop 缩放的是详情控制器的当前 viewport，不会先把 `UIScrollView` 滚回顶部。interactive pop 取消后原 content offset 保持不变。工程不安装额外的 pan recognizer，只保留 `UINavigationController` 的系统左边缘返回手势。

公开 UIKit zoom API 的 `ZoomOptions` 只有 alignment rect 配置，没有 live-video transition-view provider；Apple 也没有承诺转场 representation 必定逐帧更新。因此本 Demo 能保证播放器时钟连续，并已在当前 Simulator 观察到画面持续变化，但不把它宣称为跨系统版本保证。

## 环境

- Xcode 26+
- Swift 6
- iOS 26+
- XcodeGen 2.46+

## 生成与运行

```bash
xcodegen generate
open UIKitTodayStoryDemo.xcodeproj
```

Scheme：`UIKitTodayStoryDemo`

传入 `--force-source-offscreen` 启动参数后，进入详情会把来源 Cell 主动滚出可见区域，用于验证 fallback。

## 代码导览

- `Domain/Story.swift`：稳定 ID 与本地样例。
- `Features/StoryList/`：diffable collection、Cell 与动态来源查询。
- `Features/StoryDetail/`：长内容、关闭按钮与 fallback 测试入口。
- `Support/StoryPlaybackStore.swift`：稳定播放器 owner 和循环播放。
- `Support/PlayerSurfaceView.swift`：`AVPlayerLayer` renderer。
- `Support/GradientView.swift`：适配 Dark Mode 的本地渐变。

## 验证产物

- 首页：`artifacts/uikit-home.jpg`
- 详情：`artifacts/uikit-detail.jpg`
- video、详情滚动、左滑取消与返回：`artifacts/uikit-video-scroll-interactive-pop.mp4`
- XcodeBuildMCP：2 tests passed，0 failed（unit + XCUITest）
