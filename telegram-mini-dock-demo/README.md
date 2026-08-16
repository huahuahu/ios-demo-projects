# Telegram Mini Dock Demo

一个聚焦的 UIKit Demo，用来学习 Telegram iOS 风格的页面最小化 Dock：文件页面可以缩进标签栏下方；多个文件可以展开为带透视的卡片栈；界面使用 iOS 26 原生 Liquid Glass。

## 展示内容

- 根容器同时管理 `UITabBarController`、全屏文件页和全局 Mini Dock。
- 没有最小化文件时只显示正常标签栏。
- 文件最小化时使用 snapshot 从全屏移动到底部，并保留原 ViewController 以便恢复。
- 一个文件时点击 Dock 直接恢复；两个以上文件时先展开 3D 卡片栈。
- 展开状态支持纵向浏览、横向左滑关闭、点击卡片恢复、点击背景收起。
- `UIGlassEffect` 用于文件标题条和 Dock 标题条；系统 Tab Bar 自动采用 iOS 26 外观。

这个 Demo 参考 Telegram iOS 公开源码中的交互机制，但源码为独立实现，没有复制 Telegram 的实现文件。

## 环境

- Xcode 26 或更新版本
- iOS 26.0+
- XcodeGen
- XcodeBuildMCP（用于仓库内验证）

## 生成与打开

```bash
cd telegram-mini-dock-demo
xcodegen generate
open TelegramMiniDockDemo.xcodeproj
```

## 学习步骤

1. 启动 App，默认进入“聊天”标签。
2. 打开 `message.txt`，点击右上角向下箭头将文件最小化。
3. 再打开另外两个文件，并分别最小化。
4. 点击底部 Dock，观察卡片从收起状态展开为透视栈。
5. 左滑一张卡片关闭它，或点击卡片恢复为全屏。
6. 切换到“联系人”或“设置”，确认 Dock 跨 Tab 保留。

## 测试

```bash
xcodebuild test \
  -project TelegramMiniDockDemo.xcodeproj \
  -scheme TelegramMiniDockDemo \
  -destination 'platform=iOS Simulator,name=TelegramMiniDockDemo iPhone 17 Pro Max,OS=latest'
```

## 代码导览

- `Domain/MiniDockLayout.swift`：卡片间距、旋转角度、透视矩阵和 Dock 高度。
- `Domain/MiniDockTitleFormatter.swift`：多个文件收起后的标题规则。
- `Features/MiniDock/DemoRootViewController.swift`：根容器、Tab、文件页和 Dock 的所有权边界。
- `Features/MiniDock/MinimizedContainerViewController.swift`：最小化列表、展开/收起、关闭和恢复状态。
- `Features/MiniDock/MiniDockCardView.swift`：snapshot 卡片、标题和横滑手势。
- `Features/MiniDock/DocumentViewController.swift`：可最小化文件页面。
- `Support/GlassFactory.swift`：UIKit Liquid Glass 与玻璃按钮的集中创建。
- `docs/architecture.md`：实现流程和 Telegram 对照笔记。
