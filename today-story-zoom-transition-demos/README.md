# Today Story Zoom Transition Demos

这个目录包含两个独立的最低 iOS 26 Demo，用系统原生 fluid zoom transition 研究类似 App Store Today Story 的 push/pop 体验：

- `swiftui-today-story-demo/`：SwiftUI、`NavigationStack`、`matchedTransitionSource` 与 `navigationTransition(.zoom)`。
- `uikit-today-story-demo/`：UIKit、`UICollectionViewDiffableDataSource`、`UINavigationController` 与 `UIViewController.Transition.zoom`。

两个工程都使用 Swift 6、纯本地渐变、SF Symbols，以及工程内生成的循环 MP4，不依赖网络资源或第三方库。第一张 Story 用真实 `AVPlayerLayer` 验证富媒体在 zoom 和 interactive pop 中的行为。

详情支持左右分页切换六个 Story。切换后，返回转场会动态选择当前页对应的稳定 Story ID；对于列表中暂时离屏的来源，SwiftUI 会在详情覆盖期间无动画恢复列表位置，UIKit 会在 source provider 查询时按 ID 恢复 Cell。

两个实现都只使用系统返回交互，不增加 full-screen `DragGesture` / `UIPanGestureRecognizer`，因此不会与详情的纵向滚动竞争。公开 fluid zoom 的设计允许用户 grab、drag 并直接控制 transition representation；交互过程中画面可能随手指二维移动，这不是来源卡片定位错误。

## 与 App Store Today Story 的差异

用户录屏里的 App Store 返回效果更受约束：列表卡片保持原位，详情当前 viewport 沿“全屏到来源卡片”的固定路径缩小，而不是自由跟随手指移动。公开的 `NavigationTransition.zoom` / `UIViewController.Transition.zoom` 没有锁定 X/Y、禁用二维 drag 或自定义 interactive frame 插值的选项。iOS 26 新增的 UIKit zoom overload 只是支持用 `UIBarButtonItem` 提供来源，不会改变卡片转场的手势轨迹。

因此，这两个工程展示的是公开 system fluid zoom，不能仅靠公开配置变成录屏中的 App Store 固定轨迹。App Store Today 体验早于公开 zoom API；它很可能保留了产品专用或内部转场，但没有 App Store 源码证据，不能断言它具体使用了哪个私有 API。若要精确复刻固定轨迹，需要改成自定义 navigation transition 与 percent-driven interaction，这会偏离本 Demo“保留系统 interactive pop、不加竞争手势”的技术边界。
