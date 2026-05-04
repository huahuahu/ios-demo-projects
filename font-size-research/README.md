# Font Size Research

这个 demo project 用来调研 iOS 上不同字体大小的可读性、层级感和排版密度。

它提供一个 SwiftUI 示例页面，把常见文本角色放在同一屏里对比：caption、body、headline、title 和 large title。这个 demo 可以被博客文章引用，用来说明 iOS 字体大小选择、Dynamic Type 适配和紧凑界面排版取舍。

## 环境

- Xcode 26.0 或更新版本
- iOS 26.0 或更新版本
- XcodeGen
- XcodeBuildMCP

## 生成项目

```bash
xcodegen generate
```

生成后可以打开：

```bash
open FontSizeResearch.xcodeproj
```

## 运行和测试

优先使用 XcodeBuildMCP：

```bash
xcodebuildmcp simulator test
```

也可以用 Xcode 直接运行 `FontSizeResearch` scheme。

## 关键文件

- `FontSizeResearch/ContentView.swift`: 字体大小对比界面
- `FontSizeResearch/FontSample.swift`: 字体样本模型
- `.xcodebuildmcp/config.yaml`: XcodeBuildMCP 默认 project、scheme 和 simulator 配置

