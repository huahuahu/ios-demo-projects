# UIKit 附件面板渐进露出实现计划

> **给 agentic workers：** 必须使用子技能 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 按任务执行。本计划使用 checkbox（`- [ ]`）追踪步骤。

**目标：** 把 UIKit tab 里生硬的 custom input view 切换，改成类似微信的 app-owned attachment panel 露出效果：点击 Attach 时输入框失焦，系统键盘下滑，附件面板从键盘区域逐步露出。

**架构：** `UIKitKeyboardViewController` 不再通过隐藏 first responder + custom `UIInputView` 展示附件源，而是在普通 view hierarchy 中持有 `attachmentPanel`。文本输入模式下 composer 跟随 `keyboardLayoutGuide`；附件模式下 composer 贴在 `attachmentPanel` 顶部，并在 `draftTextField.resignFirstResponder()` 触发键盘下滑时同步露出面板。附件按钮继续复用 `AttachmentSource` 和 `KeyboardDemoState`。

**技术栈：** Swift 6.0、UIKit、Swift Testing、XcodeGen；构建/测试优先使用 XcodeBuildMCP。

## 全局约束

- 只修改 `keyboard-handling-tabs`，不要改其他 demo。
- 保持 `project.yml` 配置：iOS deployment target `26.0`、Swift version `6.0`、bundle ID `com.huahuahu.demo.KeyboardHandlingTabs`。
- 不新增第三方依赖。
- SwiftUI tab 不在本次范围内。
- 点击 Attach 时，如果输入框处于 focus，必须让 `draftTextField` resign first responder。
- 系统键盘应该向下动画消失，而不是被另一个 input view 硬替换。
- attachment panel 应该随着键盘下滑逐步露出。
- 保持现有消息、draft、Send、Emoji、Clear、Dismiss 和 attachment token 行为。
- 除非用户明确要求，否则不要在当前 workspace 里创建 commit。
- 测试优先使用 XcodeBuildMCP；fallback shell 命令：`cd keyboard-handling-tabs && xcodebuild test -project KeyboardHandlingTabs.xcodeproj -scheme KeyboardHandlingTabs -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'`。

---

## 文件结构

- 删除 `keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputHostView.swift`：隐藏 first-responder host 不再需要。
- 删除 `keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputView.swift`：附件 UI 改为普通 controller-owned panel。
- 修改 `keyboard-handling-tabs/KeyboardHandlingTabs/UIKitKeyboardViewController.swift`：新增 `attachmentPanel`、panel 约束、键盘 frame 记录和附件模式切换。
- 修改 `keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitTestHelpers.swift`：新增通过 accessibility identifier 查找 view/label 的测试 helper。
- 替换 `keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitKeyboardViewControllerAttachmentInputTests.swift`：改为测试 app-owned attachment panel 行为。
- 删除 `keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputHostViewTests.swift`：对应生产类型会被删除。
- 删除 `keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputViewTests.swift`：对应生产类型会被删除。
- 修改 `keyboard-handling-tabs/README.md`：把 UIKit attachment 描述从 custom input view 替换改成键盘下滑露出 panel。
- 修改 `keyboard-handling-tabs/docs/ui-preview.html`：更新 UIKit preview 文案。
- 运行 `xcodegen generate` 重新生成 `keyboard-handling-tabs/KeyboardHandlingTabs.xcodeproj/project.pbxproj`。

---

### Task 1：为 reveal panel 契约补上失败测试

**文件：**
- 修改：`keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitTestHelpers.swift`
- 替换：`keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitKeyboardViewControllerAttachmentInputTests.swift`
- 删除：`keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputHostViewTests.swift`
- 删除：`keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputViewTests.swift`

**接口：**
- 消费：`KeyboardAction.attach.title`、`KeyboardAction.dismissKeyboard.title`、`AttachmentSource.photoLibrary.rawValue`、`AttachmentSource.photoLibrary.token`
- 产出测试契约：
  - `UIView.accessibilityIdentifier == "UIKitAttachmentPanel"`
  - `UIView.accessibilityIdentifier == "UIKitAttachmentPanelTitle"`
  - `UIView.accessibilityIdentifier == "UIKitAttachmentPanelOptions"`
  - controller hierarchy 里不再有运行时类型名为 `AttachmentInputHostView` 的 view
  - Attach 会让 `UITextField` resign first responder

- [ ] **Step 1：扩展 UIKit 测试 helper**

把 `keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitTestHelpers.swift` 替换成：

```swift
import UIKit

@MainActor
extension UIView {
    func allSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.allSubviews() }
    }

    func allButtons() -> [UIButton] {
        allSubviews().compactMap { $0 as? UIButton }
    }

    func allLabels() -> [UILabel] {
        allSubviews().compactMap { $0 as? UILabel }
    }

    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        allSubviews().compactMap { $0 as? T }.first
    }

    func subview(withAccessibilityIdentifier identifier: String) -> UIView? {
        allSubviews().first { $0.accessibilityIdentifier == identifier }
    }

    func label(withAccessibilityIdentifier identifier: String) -> UILabel? {
        allLabels().first { $0.accessibilityIdentifier == identifier }
    }

    func button(named title: String) -> UIButton? {
        allButtons().first { button in
            button.configuration?.title == title || button.title(for: .normal) == title
        }
    }
}
```

- [ ] **Step 2：替换 controller 测试**

把 `keyboard-handling-tabs/KeyboardHandlingTabsTests/UIKitKeyboardViewControllerAttachmentInputTests.swift` 替换成：

```swift
import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct UIKitKeyboardViewControllerAttachmentInputTests {
    @Test
    func controllerInstallsAppOwnedAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let titleLabel = try #require(controller.view.label(withAccessibilityIdentifier: "UIKitAttachmentPanelTitle"))
            let optionsStack = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanelOptions"))

            #expect(panel.isHidden)
            #expect(titleLabel.text == "Choose attachment source")
            let hostViews = controller.view.allSubviews().filter { view in
                String(describing: type(of: view)) == "AttachmentInputHostView"
            }

            #expect(optionsStack is UIStackView)
            #expect(hostViews.isEmpty)
        }
    }

    @Test
    func attachActionResignsFocusedTextFieldAndShowsAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            #expect(draftTextField.becomeFirstResponder())
            #expect(draftTextField.isFirstResponder)

            attachButton.sendActions(for: .touchUpInside)

            #expect(!draftTextField.isFirstResponder)
            #expect(!panel.isHidden)
            #expect(panel.alpha == 1)
        }
    }

    @Test
    func beginningTextFieldEditingHidesVisibleAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)

            #expect(panel.isHidden)
        }
    }

    @Test
    func selectingAttachmentSourceUpdatesDraftAndDismissesAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let photoButton = try #require(controller.view.button(named: AttachmentSource.photoLibrary.rawValue))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            photoButton.sendActions(for: .touchUpInside)

            #expect(draftTextField.text == AttachmentSource.photoLibrary.token)
            #expect(panel.isHidden)
        }
    }

    @Test
    func dismissActionHidesAttachmentPanelWhenPanelIsActive() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            dismissButton.sendActions(for: .touchUpInside)

            #expect(panel.isHidden)
        }
    }

    private func makeVisibleController() throws -> (UIWindow, UIKitKeyboardViewController) {
        let windowScene = try #require(
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        )
        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.screen.bounds
        let controller = UIKitKeyboardViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        return (window, controller)
    }
}
```

- [ ] **Step 3：删除过时测试**

删除：

```text
keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputHostViewTests.swift
keyboard-handling-tabs/KeyboardHandlingTabsTests/AttachmentInputViewTests.swift
```

- [ ] **Step 4：重新生成 Xcode project**

运行：

```bash
cd keyboard-handling-tabs
xcodegen generate
```

预期：`KeyboardHandlingTabs.xcodeproj/project.pbxproj` 不再引用被删除的测试文件。

- [ ] **Step 5：运行 focused tests，确认按预期失败**

运行：

```bash
cd keyboard-handling-tabs
xcodebuild test -project KeyboardHandlingTabs.xcodeproj -scheme KeyboardHandlingTabs -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:KeyboardHandlingTabsTests/UIKitKeyboardViewControllerAttachmentInputTests
```

预期：测试失败，因为生产代码还没有实现 `"UIKitAttachmentPanel"`。

---

### Task 2：用 app-owned attachment panel 替换 custom input view 切换

**文件：**
- 修改：`keyboard-handling-tabs/KeyboardHandlingTabs/UIKitKeyboardViewController.swift`
- 删除：`keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputHostView.swift`
- 删除：`keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputView.swift`
- 修改生成文件：`keyboard-handling-tabs/KeyboardHandlingTabs.xcodeproj/project.pbxproj`

**接口：**
- 消费：`AttachmentSource.allCases`、`AttachmentSource.rawValue`、`AttachmentSource.symbolName`、`KeyboardDemoState.selectAttachmentSource(_:)`
- 产出：
  - `attachmentPanel.accessibilityIdentifier = "UIKitAttachmentPanel"`
  - `titleLabel.accessibilityIdentifier = "UIKitAttachmentPanelTitle"`
  - `optionsStackView.accessibilityIdentifier = "UIKitAttachmentPanelOptions"`
  - Attach action 调用 `draftTextField.resignFirstResponder()`
  - text field 开始编辑时隐藏 attachment panel

- [ ] **Step 1：删除过时生产文件**

删除：

```text
keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputHostView.swift
keyboard-handling-tabs/KeyboardHandlingTabs/AttachmentInputView.swift
```

- [ ] **Step 2：替换 first-responder host 属性为 panel 状态**

在 `keyboard-handling-tabs/KeyboardHandlingTabs/UIKitKeyboardViewController.swift` 中，把现有属性：

```swift
    private lazy var attachmentInputView = AttachmentInputView { [weak self] source in
        self?.selectAttachmentSource(source)
    }
    private lazy var attachmentInputHostView = AttachmentInputHostView(inputView: attachmentInputView)
```

替换为：

```swift
    private let attachmentPanel = UIView()
    private var composerBottomToKeyboardConstraint: NSLayoutConstraint?
    private var composerBottomToAttachmentPanelConstraint: NSLayoutConstraint?
    private var attachmentPanelBottomConstraint: NSLayoutConstraint?
    private var attachmentPanelHeightConstraint: NSLayoutConstraint?
    private var isAttachmentPanelVisible = false
    private var lastVisibleKeyboardHeight: CGFloat = 291

    private enum AttachmentPanelLayout {
        static let minimumHeight: CGFloat = 180
    }
```

- [ ] **Step 3：在 view loading 中配置 attachment panel**

在 `viewDidLoad` 中，把：

```swift
        configureAttachmentInputHost()
        configureScrollView()
```

替换为：

```swift
        configureAttachmentPanel()
        configureScrollView()
        observeKeyboardFrameChanges()
```

- [ ] **Step 4：保存 composer 到 keyboardLayoutGuide 的约束**

在 `configureComposer()` 中，先新增：

```swift
        let composerKeyboardConstraint = composerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        composerBottomToKeyboardConstraint = composerKeyboardConstraint
```

再把 activation array 里的：

```swift
            composerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
```

替换为：

```swift
            composerKeyboardConstraint,
```

- [ ] **Step 5：用 `configureAttachmentPanel()` 替换 `configureAttachmentInputHost()`**

删除整个 `configureAttachmentInputHost()` 方法，新增：

```swift
    private func configureAttachmentPanel() {
        attachmentPanel.translatesAutoresizingMaskIntoConstraints = false
        attachmentPanel.accessibilityIdentifier = "UIKitAttachmentPanel"
        attachmentPanel.backgroundColor = .systemBackground
        attachmentPanel.isHidden = true
        attachmentPanel.alpha = 0
        view.addSubview(attachmentPanel)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        attachmentPanel.addSubview(divider)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "UIKitAttachmentPanelTitle"
        titleLabel.text = "Choose attachment source"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        attachmentPanel.addSubview(titleLabel)

        let optionsStackView = UIStackView()
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.accessibilityIdentifier = "UIKitAttachmentPanelOptions"
        optionsStackView.axis = .horizontal
        optionsStackView.spacing = 12
        optionsStackView.distribution = .fillEqually
        attachmentPanel.addSubview(optionsStackView)

        for source in AttachmentSource.allCases {
            let button = UIButton(type: .system)
            button.configuration = .tinted()
            button.configuration?.title = source.rawValue
            button.configuration?.image = UIImage(systemName: source.symbolName)
            button.configuration?.imagePadding = 8
            button.configuration?.imagePlacement = .top
            button.titleLabel?.numberOfLines = 0
            let selectedSource = source
            button.addAction(
                UIAction { [weak self] _ in
                    self?.selectAttachmentSource(selectedSource)
                },
                for: .touchUpInside
            )
            optionsStackView.addArrangedSubview(button)
        }

        let panelBottomConstraint = attachmentPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let panelHeightConstraint = attachmentPanel.heightAnchor.constraint(equalToConstant: lastVisibleKeyboardHeight)
        let composerPanelConstraint = composerContainer.bottomAnchor.constraint(equalTo: attachmentPanel.topAnchor)

        attachmentPanelBottomConstraint = panelBottomConstraint
        attachmentPanelHeightConstraint = panelHeightConstraint
        composerBottomToAttachmentPanelConstraint = composerPanelConstraint
        composerPanelConstraint.isActive = false

        NSLayoutConstraint.activate([
            attachmentPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            attachmentPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelBottomConstraint,
            panelHeightConstraint,

            divider.leadingAnchor.constraint(equalTo: attachmentPanel.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: attachmentPanel.trailingAnchor),
            divider.topAnchor.constraint(equalTo: attachmentPanel.topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / max(view.traitCollection.displayScale, 1)),

            titleLabel.leadingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: attachmentPanel.topAnchor, constant: 16),

            optionsStackView.leadingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            optionsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: attachmentPanel.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
```

- [ ] **Step 6：记录键盘 frame，用于面板高度**

在配置方法附近新增：

```swift
    private func observeKeyboardFrameChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
```

在 action handler 附近新增：

```swift
    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = view.window
        else {
            return
        }

        let convertedEndFrame = view.convert(endFrame, from: window.screen.coordinateSpace)
        let keyboardHeight = max(0, view.bounds.maxY - convertedEndFrame.minY - view.safeAreaInsets.bottom)
        if keyboardHeight > 0 {
            lastVisibleKeyboardHeight = keyboardHeight
            if !isAttachmentPanelVisible {
                attachmentPanelHeightConstraint?.constant = max(
                    AttachmentPanelLayout.minimumHeight,
                    keyboardHeight
                )
            }
        }
    }
```

在 `configureComposer()` 前新增：

```swift
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
```

- [ ] **Step 7：替换 Attach 处理**

把 `showAttachmentInputView()` 替换为：

```swift
    private func showAttachmentPanel() {
        guard !isAttachmentPanelVisible else {
            return
        }

        isAttachmentPanelVisible = true
        attachmentPanelHeightConstraint?.constant = max(
            AttachmentPanelLayout.minimumHeight,
            lastVisibleKeyboardHeight
        )
        attachmentPanel.isHidden = false
        attachmentPanel.alpha = 1

        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = true
        view.layoutIfNeeded()

        if draftTextField.isFirstResponder {
            draftTextField.resignFirstResponder()
        }
    }
```

把 `handle(_:)` 里的 `.attach` 分支改为：

```swift
        case .attach:
            showAttachmentPanel()
```

- [ ] **Step 8：替换 Dismiss 和附件源选择行为**

把 `dismissActiveInputSurface()` 替换为：

```swift
    private func dismissActiveInputSurface() {
        if isAttachmentPanelVisible {
            hideAttachmentPanel(animated: true)
        } else {
            view.endEditing(true)
        }
    }
```

把 `selectAttachmentSource(_:)` 替换为：

```swift
    private func selectAttachmentSource(_ source: AttachmentSource) {
        state.selectAttachmentSource(source)
        hideAttachmentPanel(animated: false)
        applyState(scrollToBottom: false)
    }
```

新增 helper：

```swift
    private func hideAttachmentPanel(animated: Bool) {
        guard isAttachmentPanelVisible else {
            return
        }

        isAttachmentPanelVisible = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
        composerBottomToKeyboardConstraint?.isActive = true

        let updates = {
            self.attachmentPanel.alpha = 0
            self.view.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            self.attachmentPanel.isHidden = true
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: updates,
                completion: completion
            )
        } else {
            updates()
            completion(true)
        }
    }
```

- [ ] **Step 9：输入框开始编辑时退出附件模式**

把 `UITextFieldDelegate` extension 替换为：

```swift
extension UIKitKeyboardViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        hideAttachmentPanel(animated: false)
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return false
    }
}
```

- [ ] **Step 10：重新生成 Xcode project**

运行：

```bash
cd keyboard-handling-tabs
xcodegen generate
```

预期：`project.pbxproj` 不再引用 `AttachmentInputHostView.swift`、`AttachmentInputView.swift` 或对应测试文件。

- [ ] **Step 11：运行 focused tests**

运行：

```bash
cd keyboard-handling-tabs
xcodebuild test -project KeyboardHandlingTabs.xcodeproj -scheme KeyboardHandlingTabs -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:KeyboardHandlingTabsTests/UIKitKeyboardViewControllerAttachmentInputTests
```

预期：focused tests 通过。

---

### Task 3：更新 README 和 UI preview 文案

**文件：**
- 修改：`keyboard-handling-tabs/README.md`
- 修改：`keyboard-handling-tabs/docs/ui-preview.html`

**接口：**
- 消费：Task 2 实现后的行为。
- 产出：文档描述 app-owned attachment panel reveal，不再描述 hidden first responder/custom input view replacement。

- [ ] **Step 1：更新 README bullets**

在 `keyboard-handling-tabs/README.md` 中，把：

```markdown
- UIKit `Attach` replaces the system keyboard with a custom attachment `UIInputView` hosted by an invisible first responder.
```

替换为：

```markdown
- UIKit `Attach` resigns the focused text field, lets the keyboard slide down, and reveals an app-owned attachment panel from the keyboard area.
```

把：

```markdown
- UIKit tab keeps the composer pinned to `keyboardLayoutGuide` while UIKit owns both the system keyboard and custom attachment input surface.
```

替换为：

```markdown
- UIKit tab keeps the composer pinned to `keyboardLayoutGuide` for text input, then pins it above the app-owned attachment panel while the keyboard dismissal reveals that panel.
```

把 key-file bullet：

```markdown
- `KeyboardHandlingTabs/UIKitKeyboardViewController.swift` demonstrates UIKit keyboard-safe composer layout with `keyboardLayoutGuide` plus first-responder switching to a custom attachment `UIInputView`.
```

替换为：

```markdown
- `KeyboardHandlingTabs/UIKitKeyboardViewController.swift` demonstrates UIKit keyboard-safe composer layout with `keyboardLayoutGuide` plus a WeChat-like app-owned attachment panel reveal.
```

- [ ] **Step 2：更新 preview 顶部说明**

在 `keyboard-handling-tabs/docs/ui-preview.html` 中，把 subtitle：

```html
这个页面用网页 mock 展示 demo 的大概 UI：每个 tab 都是滚动内容区，底部 composer 包含 action buttons、输入框和 Send。SwiftUI 用 sheet 承载来源选择；UIKit 用隐藏 first responder 提供 custom inputView，让系统键盘和附件来源选择共用同一个 keyboard area。
```

替换为：

```html
这个页面用网页 mock 展示 demo 的大概 UI：每个 tab 都是滚动内容区，底部 composer 包含 action buttons、输入框和 Send。SwiftUI 用 sheet 承载来源选择；UIKit 在点击 Attach 时让输入框失焦，键盘下滑并露出 app-owned attachment panel。
```

- [ ] **Step 3：更新 UIKit preview article**

把：

```html
<h2><span class="badge">UIKit</span> custom input view</h2>
```

替换为：

```html
<h2><span class="badge">UIKit</span> attachment reveal</h2>
```

把 UIKit notes 段落：

```html
UIKit tab 让 text field 和隐藏的 first-responder host 轮流成为 first responder。composer 始终贴住 <code>keyboardLayoutGuide</code>，系统键盘和附件选择由 UIKit 在同一输入区域中替换。
```

替换为：

```html
UIKit tab 点击 Attach 时让 text field 失焦，系统键盘向下滑走，底部普通 view hierarchy 里的 attachment panel 从键盘区域逐步露出。
```

把：

```html
<span>UIScrollView + keyboardLayoutGuide + custom inputView</span>
```

替换为：

```html
<span>UIScrollView + keyboardLayoutGuide + reveal panel</span>
```

把：

```html
<div class="source-picker" aria-label="custom attachment input view">
```

替换为：

```html
<div class="source-picker" aria-label="app-owned attachment reveal panel">
```

把：

```html
<div class="implementation">Key idea: a hidden responder returns AttachmentInputView from inputView</div>
```

替换为：

```html
<div class="implementation">Key idea: Attach resigns the text field, keyboard slides down, panel reveals behind it</div>
```

- [ ] **Step 4：运行完整测试**

运行：

```bash
cd keyboard-handling-tabs
xcodebuild test -project KeyboardHandlingTabs.xcodeproj -scheme KeyboardHandlingTabs -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

预期：全部测试通过。

---

### Task 4：手动验证 simulator 动画

**文件：**
- 预期不改源码。

**接口：**
- 消费：Task 2 的实现和 Task 3 的文档更新。
- 产出：确认视觉效果符合“微信式键盘下滑露出 panel”。

- [ ] **Step 1：查看 XcodeBuildMCP defaults**

运行 XcodeBuildMCP session defaults 工具。

预期：defaults 指向 `keyboard-handling-tabs/KeyboardHandlingTabs.xcodeproj`、scheme `KeyboardHandlingTabs` 和 iOS Simulator。如果没有 defaults，先为该 project 设置 defaults。

- [ ] **Step 2：build and run 到 simulator**

运行 XcodeBuildMCP build-and-run simulator 工具。

预期：app 在配置好的 simulator 上启动。

- [ ] **Step 3：手动执行用户请求路径**

手动步骤：

1. 打开 UIKit tab。
2. 点击输入框，确认系统键盘出现。
3. 点击 Attach。
4. 确认输入框失焦。
5. 确认系统键盘向下移动，attachment panel 从底部键盘区域逐步露出。
6. 再点击输入框。
7. 确认 attachment panel 隐藏，系统键盘重新出现。

预期：没有生硬的 custom input view 替换，没有空白间隙，attachment panel 激活时输入框不保持 focus。
