# iOS Demo Projects

这个仓库用于存放和 iOS 开发有关的 demo project。

这些 demo project 通常会被博客文章引用，用来展示某个 iOS 技术点、实现思路、实验结论或完整示例。每个 demo 尽量保持独立，方便从对应博客跳转后直接阅读、运行和验证。

## 目录约定

每个 demo project 建议使用单独目录存放，例如：

```text
demo-name/
  README.md
  DemoName.xcodeproj
  DemoName/
  DemoNameTests/
```

如果 demo 需要特殊运行方式，请在对应目录下补充自己的 `README.md`，说明：

- 这个 demo 对应的博客文章或主题
- Xcode、iOS SDK 和最低系统版本要求
- 依赖管理方式，例如 Swift Package Manager、CocoaPods 或 Carthage
- 运行、构建或测试方式
- 关键文件和实现说明

## 使用说明

博客文章引用 demo 时，建议直接链接到具体 demo 目录，而不是仓库根目录。这样读者可以更快找到和文章相关的代码。

## 维护原则

- demo 应尽量小而完整，聚焦一个明确主题。
- 避免在 demo 中混入无关实验代码。
- 如果 demo 依赖外部服务、环境变量或账号配置，请在对应目录说明清楚。
- 已被博客引用的 demo 不建议随意重写目录结构，避免链接失效。
