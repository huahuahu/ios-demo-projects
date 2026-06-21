# UIKit updateProperties Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个独立 UIKit demo，用两个实验页展示 iOS 26 `updateProperties()` 与 `layoutSubviews()`、`updateConstraints()`、UIViewController layout callbacks 的关系。

**Architecture:** 新增 `uikit-update-properties-demo/` XcodeGen 工程。共享的 state、action metadata 和 lifecycle recorder 放在小型 Swift 文件里；UIView 实验页和 UIViewController 实验页各自负责自己的 UI 和 callback 记录；root tab controller 只负责切换实验。

**Tech Stack:** UIKit, Swift 6.0, iOS 26.0, XcodeGen, XCTest, XcodeBuildMCP.

## Global Constraints

- 新 demo 目录必须是 `uikit-update-properties-demo/`。
- App target 必须是 `UIKitUpdatePropertiesDemo`。
- 使用 UIKit，不引入第三方依赖。
- 使用 Swift 6.0。
- iOS deployment target 必须是 26.0。
- 使用 XcodeGen 生成 Xcode project。
- 验证优先使用 XcodeBuildMCP。
- 界面和 README 必须明确说明：`updateProperties()` 的 observation-driven property update 不等于自动触发 `updateConstraints()`。

---

## File Structure

- `uikit-update-properties-demo/README.md`: demo 目标、运行方式、核心结论和关键文件说明。
- `uikit-update-properties-demo/project.yml`: XcodeGen project definition。
- `uikit-update-properties-demo/.xcodebuildmcp/config.yaml`: XcodeBuildMCP defaults，使用专用 simulator。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/AppDelegate.swift`: UIKit app entry point。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/SceneDelegate.swift`: window scene bootstrap。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`: 两个实验页 tab。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`: callback enum、event record、计数和清空逻辑。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoAction.swift`: demo action、预期 invalidation、稳定说明文案。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoState.swift`: observable state 和 action application。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LogView.swift`: 可复用的计数和事件日志 UI。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift`: UIView 实验页容器和按钮行为。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift`: override `updateProperties()`、`updateConstraints()`、`layoutSubviews()` 的实验 view。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`: override `updateProperties()`、`viewWillLayoutSubviews()`、`viewDidLayoutSubviews()` 的实验 view controller。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/LifecycleEventRecorderTests.swift`: recorder 单元测试。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoActionTests.swift`: action metadata 单元测试。
- `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoStateTests.swift`: state transition 单元测试。

---

### Task 1: Scaffold project and recorder model

**Files:**
- Create: `uikit-update-properties-demo/README.md`
- Create: `uikit-update-properties-demo/project.yml`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/AppDelegate.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/SceneDelegate.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/LifecycleEventRecorderTests.swift`

**Interfaces:**
- Produces: `LifecycleCallback: String, CaseIterable`
- Produces: `LifecycleEventRecorder.record(_ callback: LifecycleCallback, note: String) -> Void`
- Produces: `LifecycleEventRecorder.count(for callback: LifecycleCallback) -> Int`
- Produces: `LifecycleEventRecorder.clear() -> Void`
- Produces: `LifecycleEventRecorder.summaryLines() -> [String]`
- Produces: `LifecycleEventRecorder.eventLines(limit: Int = 12) -> [String]`

- [ ] **Step 1: Create project directories**

Run:

```bash
mkdir -p uikit-update-properties-demo/UIKitUpdatePropertiesDemo uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests
```

Expected: directories exist.

- [ ] **Step 2: Write the failing recorder tests**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/LifecycleEventRecorderTests.swift`:

```swift
import XCTest
@testable import UIKitUpdatePropertiesDemo

final class LifecycleEventRecorderTests: XCTestCase {
    func testRecordsOrderedEventsAndCountsByCallback() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.updateProperties, note: "first property pass")
        recorder.record(.layoutSubviews, note: "layout after property pass")
        recorder.record(.updateProperties, note: "second property pass")

        XCTAssertEqual(recorder.count(for: .updateProperties), 2)
        XCTAssertEqual(recorder.count(for: .layoutSubviews), 1)
        XCTAssertEqual(recorder.count(for: .updateConstraints), 0)
        XCTAssertEqual(recorder.events.map(\.sequence), [1, 2, 3])
        XCTAssertEqual(recorder.events.map(\.callback), [.updateProperties, .layoutSubviews, .updateProperties])
    }

    func testSummaryAndEventLinesAreStableForTheDemoUI() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.viewWillLayoutSubviews, note: "controller before layout")
        recorder.record(.viewDidLayoutSubviews, note: "controller after layout")

        XCTAssertEqual(
            recorder.summaryLines(),
            [
                "updateProperties: 0",
                "updateConstraints: 0",
                "layoutSubviews: 0",
                "viewWillLayoutSubviews: 1",
                "viewDidLayoutSubviews: 1"
            ]
        )
        XCTAssertEqual(
            recorder.eventLines(),
            [
                "#1 viewWillLayoutSubviews - controller before layout",
                "#2 viewDidLayoutSubviews - controller after layout"
            ]
        )
    }

    func testClearRemovesEventsAndResetsCounts() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.updateProperties, note: "tracked")
        recorder.clear()

        XCTAssertTrue(recorder.events.isEmpty)
        XCTAssertEqual(recorder.count(for: .updateProperties), 0)
    }
}
```

- [ ] **Step 3: Add minimal project configuration**

Create `uikit-update-properties-demo/project.yml`:

```yaml
name: "UIKitUpdatePropertiesDemo"
options:
  bundleIdPrefix: "com.huahuahu.demo"
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""
targets:
  "UIKitUpdatePropertiesDemo":
    type: application
    platform: iOS
    sources:
      - "UIKitUpdatePropertiesDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.UIKitUpdatePropertiesDemo"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
    scheme:
      testTargets:
        - "UIKitUpdatePropertiesDemoTests"
  "UIKitUpdatePropertiesDemoTests":
    type: bundle.unit-test
    platform: iOS
    sources:
      - "UIKitUpdatePropertiesDemoTests"
    dependencies:
      - target: "UIKitUpdatePropertiesDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.UIKitUpdatePropertiesDemoTests"
```

- [ ] **Step 4: Add app bootstrap files**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/AppDelegate.swift`:

```swift
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/SceneDelegate.swift`:

```swift
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`:

```swift
import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .systemBackground
        placeholder.title = "UIView"
        placeholder.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        viewControllers = [
            UINavigationController(rootViewController: placeholder)
        ]
    }
}
```

- [ ] **Step 5: Implement the recorder**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`:

```swift
import Foundation

enum LifecycleCallback: String, CaseIterable, Equatable {
    case updateProperties
    case updateConstraints
    case layoutSubviews
    case viewWillLayoutSubviews
    case viewDidLayoutSubviews
}

struct LifecycleEvent: Equatable {
    let sequence: Int
    let callback: LifecycleCallback
    let note: String
}

final class LifecycleEventRecorder {
    private(set) var events: [LifecycleEvent] = []

    func record(_ callback: LifecycleCallback, note: String) {
        events.append(
            LifecycleEvent(
                sequence: events.count + 1,
                callback: callback,
                note: note
            )
        )
    }

    func count(for callback: LifecycleCallback) -> Int {
        events.filter { $0.callback == callback }.count
    }

    func clear() {
        events.removeAll()
    }

    func summaryLines() -> [String] {
        LifecycleCallback.allCases.map { callback in
            "\(callback.rawValue): \(count(for: callback))"
        }
    }

    func eventLines(limit: Int = 12) -> [String] {
        events.suffix(limit).map { event in
            "#\(event.sequence) \(event.callback.rawValue) - \(event.note)"
        }
    }
}
```

- [ ] **Step 6: Generate project and verify tests pass**

Run:

```bash
cd uikit-update-properties-demo
xcodegen generate
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -quiet
```

Expected: XcodeGen succeeds and the three recorder tests pass.

- [ ] **Step 7: Commit**

```bash
git add uikit-update-properties-demo
git commit -m "feat: scaffold UIKit update properties demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Add demo state and action metadata

**Files:**
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoAction.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoState.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoActionTests.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoStateTests.swift`

**Interfaces:**
- Consumes: `LifecycleCallback`
- Produces: `InvalidationExpectation`
- Produces: `DemoAction: CaseIterable`
- Produces: `DemoAction.title: String`
- Produces: `DemoAction.explanation: String`
- Produces: `DemoAction.expectation: InvalidationExpectation`
- Produces: `DemoState.apply(_ action: DemoAction) -> Void`
- Produces: `DemoState.isDetailHidden: Bool`
- Produces: `DemoState.detailHeight: CGFloat`
- Produces: `DemoState.statusText: String`

- [ ] **Step 1: Write failing action tests**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoActionTests.swift`:

```swift
import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoActionTests: XCTestCase {
    func testActionCopyExplainsInvalidationBoundary() {
        XCTAssertEqual(DemoAction.toggleHidden.title, "Toggle hidden")
        XCTAssertEqual(
            DemoAction.toggleHidden.explanation,
            "Changes hidden state through updateProperties. This does not promise updateConstraints."
        )
        XCTAssertEqual(DemoAction.toggleHidden.expectation, .propertiesOnly)
    }

    func testConstraintActionsHaveDifferentExpectations() {
        XCTAssertEqual(DemoAction.constraintUpdate.expectation, .propertiesAndConstraints)
        XCTAssertEqual(DemoAction.layoutOnly.expectation, .propertiesAndLayout)
        XCTAssertTrue(DemoAction.constraintUpdate.explanation.contains("setNeedsUpdateConstraints"))
        XCTAssertTrue(DemoAction.layoutOnly.explanation.contains("setNeedsLayout"))
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoStateTests.swift`:

```swift
import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoStateTests: XCTestCase {
    func testToggleHiddenOnlyChangesVisibilityAndStatus() {
        let state = DemoState()

        state.apply(.toggleHidden)

        XCTAssertTrue(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 140)
        XCTAssertEqual(state.statusText, DemoAction.toggleHidden.explanation)
    }

    func testConstraintUpdateChangesHeightAndStatus() {
        let state = DemoState()

        state.apply(.constraintUpdate)

        XCTAssertFalse(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 72)
        XCTAssertEqual(state.statusText, DemoAction.constraintUpdate.explanation)
    }

    func testLayoutOnlyChangesHeightAndStatus() {
        let state = DemoState()

        state.apply(.layoutOnly)

        XCTAssertFalse(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 188)
        XCTAssertEqual(state.statusText, DemoAction.layoutOnly.explanation)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
cd uikit-update-properties-demo
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -quiet
```

Expected: FAIL because `DemoAction`, `InvalidationExpectation`, and `DemoState` do not exist.

- [ ] **Step 3: Implement action and state files**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoAction.swift`:

```swift
import Foundation

enum InvalidationExpectation: Equatable {
    case propertiesOnly
    case propertiesAndConstraints
    case propertiesAndLayout
}

enum DemoAction: CaseIterable, Equatable {
    case toggleHidden
    case constraintUpdate
    case layoutOnly

    var title: String {
        switch self {
        case .toggleHidden:
            "Toggle hidden"
        case .constraintUpdate:
            "Constraint update"
        case .layoutOnly:
            "Layout only"
        }
    }

    var explanation: String {
        switch self {
        case .toggleHidden:
            "Changes hidden state through updateProperties. This does not promise updateConstraints."
        case .constraintUpdate:
            "Changes height state and explicitly calls setNeedsUpdateConstraints."
        case .layoutOnly:
            "Changes height state and explicitly calls setNeedsLayout without requesting constraints."
        }
    }

    var expectation: InvalidationExpectation {
        switch self {
        case .toggleHidden:
            .propertiesOnly
        case .constraintUpdate:
            .propertiesAndConstraints
        case .layoutOnly:
            .propertiesAndLayout
        }
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoState.swift`:

```swift
import Observation
import UIKit

@Observable
final class DemoState {
    var isDetailHidden = false
    var detailHeight: CGFloat = 140
    var statusText = "Tap an action to observe which UIKit callbacks run."

    func apply(_ action: DemoAction) {
        switch action {
        case .toggleHidden:
            isDetailHidden.toggle()
        case .constraintUpdate:
            isDetailHidden = false
            detailHeight = detailHeight == 72 ? 140 : 72
        case .layoutOnly:
            isDetailHidden = false
            detailHeight = detailHeight == 188 ? 140 : 188
        }

        statusText = action.explanation
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd uikit-update-properties-demo
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoAction.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/DemoState.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoActionTests.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemoTests/DemoStateTests.swift
git commit -m "feat: add update properties demo state" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Build the UIView experiment

**Files:**
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LogView.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift`
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift`
- Modify: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`

**Interfaces:**
- Consumes: `DemoState`
- Consumes: `DemoAction`
- Consumes: `LifecycleEventRecorder`
- Produces: `UIViewExperimentViewController.init()`
- Produces: `InstrumentedPanelView.state: DemoState`
- Produces: `InstrumentedPanelView.refreshLog() -> Void`

- [ ] **Step 1: Add UI implementation files**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LogView.swift`:

```swift
import UIKit

final class LogView: UIView {
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let eventLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(recorder: LifecycleEventRecorder) {
        summaryLabel.text = recorder.summaryLines().joined(separator: "\n")
        eventLabel.text = recorder.eventLines().joined(separator: "\n")
    }

    private func configure() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 14

        titleLabel.text = "Lifecycle log"
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        summaryLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        summaryLabel.numberOfLines = 0

        eventLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventLabel.numberOfLines = 0
        eventLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, eventLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift`:

```swift
import UIKit

final class InstrumentedPanelView: UIView {
    let recorder = LifecycleEventRecorder()
    let logView = LogView()

    var state: DemoState {
        didSet {
            setNeedsUpdateProperties()
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    private let statusLabel = UILabel()
    private let detailView = UIView()
    private let detailLabel = UILabel()
    private var detailHeightConstraint: NSLayoutConstraint!

    init(state: DemoState) {
        self.state = state
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateProperties() {
        super.updateProperties()
        recorder.record(.updateProperties, note: "UIView read observable state")
        statusLabel.text = state.statusText
        detailView.isHidden = state.isDetailHidden
        detailLabel.text = state.isDetailHidden ? "Hidden by state" : "Visible detail area"
        refreshLog()
    }

    override func updateConstraints() {
        recorder.record(.updateConstraints, note: "UIView applied height constraint = \(Int(state.detailHeight))")
        detailHeightConstraint.constant = state.detailHeight
        refreshLog()
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        recorder.record(.layoutSubviews, note: "UIView laid out subviews")
        refreshLog()
    }

    func refreshLog() {
        logView.update(recorder: recorder)
    }

    func clearLog() {
        recorder.clear()
        refreshLog()
    }

    private func configure() {
        backgroundColor = .systemBackground

        statusLabel.font = .preferredFont(forTextStyle: .callout)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel

        detailView.backgroundColor = .systemBlue.withAlphaComponent(0.14)
        detailView.layer.cornerRadius = 16

        detailLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.textAlignment = .center
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(detailLabel)

        detailHeightConstraint = detailView.heightAnchor.constraint(equalToConstant: state.detailHeight)

        let explanationLabel = UILabel()
        explanationLabel.text = "UIView experiment: updateProperties updates state-derived properties. Constraint changes only happen in updateConstraints when constraints are invalidated."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [explanationLabel, statusLabel, detailView, logView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            detailHeightConstraint,
            detailLabel.centerXAnchor.constraint(equalTo: detailView.centerXAnchor),
            detailLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor)
        ])
    }
}
```

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift`:

```swift
import UIKit

final class UIViewExperimentViewController: UIViewController {
    private let state = DemoState()
    private lazy var panelView = InstrumentedPanelView(state: state)

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIView"
        configure()
    }

    private func configure() {
        let buttonStack = UIStackView(arrangedSubviews: [
            makeButton(for: .toggleHidden),
            makeButton(for: .constraintUpdate),
            makeButton(for: .layoutOnly),
            makeClearButton()
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let rootStack = UIStackView(arrangedSubviews: [buttonStack, panelView])
        rootStack.axis = .vertical
        rootStack.spacing = 16
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeButton(for action: DemoAction) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = action.title
        configuration.subtitle = action.explanation

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.apply(action)
        }, for: .touchUpInside)
        return button
    }

    private func makeClearButton() -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Clear log"

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.panelView.clearLog()
        }, for: .touchUpInside)
        return button
    }

    private func apply(_ action: DemoAction) {
        state.apply(action)

        switch action.expectation {
        case .propertiesOnly:
            break
        case .propertiesAndConstraints:
            panelView.setNeedsUpdateConstraints()
        case .propertiesAndLayout:
            panelView.setNeedsLayout()
        }
    }
}
```

Modify `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`:

```swift
import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiViewExperiment = UIViewExperimentViewController()
        uiViewExperiment.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        viewControllers = [
            UINavigationController(rootViewController: uiViewExperiment)
        ]
    }
}
```

- [ ] **Step 2: Build and run tests**

Run:

```bash
cd uikit-update-properties-demo
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -quiet
```

Expected: PASS and app target compiles.

- [ ] **Step 3: Commit**

```bash
git add uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LogView.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift
git commit -m "feat: add UIView lifecycle experiment" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Build the UIViewController experiment

**Files:**
- Create: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`
- Modify: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`

**Interfaces:**
- Consumes: `DemoState`
- Consumes: `DemoAction`
- Consumes: `LifecycleEventRecorder`
- Produces: `UIViewControllerExperimentViewController.init()`

- [ ] **Step 1: Add UIViewController experiment**

Create `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`:

```swift
import UIKit

final class UIViewControllerExperimentViewController: UIViewController {
    private let state = DemoState()
    private let recorder = LifecycleEventRecorder()
    private let statusLabel = UILabel()
    private let titlePreviewLabel = UILabel()
    private let logView = LogView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIViewController"
        configure()
    }

    override func updateProperties() {
        super.updateProperties()
        recorder.record(.updateProperties, note: "UIViewController read observable state")
        title = state.isDetailHidden ? "VC Hidden State" : "UIViewController"
        titlePreviewLabel.text = state.isDetailHidden ? "Controller title changed by state" : "Controller title is normal"
        statusLabel.text = state.statusText
        refreshLog()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recorder.record(.viewWillLayoutSubviews, note: "Controller before view layout")
        refreshLog()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recorder.record(.viewDidLayoutSubviews, note: "Controller after view layout")
        refreshLog()
    }

    private func configure() {
        view.backgroundColor = .systemBackground

        let explanationLabel = UILabel()
        explanationLabel.text = "UIViewController experiment: updateProperties can update controller-owned UI such as title and status. View layout callbacks remain separate."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.numberOfLines = 0

        titlePreviewLabel.font = .preferredFont(forTextStyle: .headline)
        titlePreviewLabel.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .callout)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0

        let buttonStack = UIStackView(arrangedSubviews: [
            makeButton(for: .toggleHidden),
            makeButton(for: .layoutOnly),
            makeClearButton()
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let rootStack = UIStackView(arrangedSubviews: [explanationLabel, buttonStack, titlePreviewLabel, statusLabel, logView])
        rootStack.axis = .vertical
        rootStack.spacing = 16
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func makeButton(for action: DemoAction) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = action.title
        configuration.subtitle = action.explanation

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.apply(action)
        }, for: .touchUpInside)
        return button
    }

    private func makeClearButton() -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Clear log"

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.recorder.clear()
            self?.refreshLog()
        }, for: .touchUpInside)
        return button
    }

    private func apply(_ action: DemoAction) {
        state.apply(action)

        if action.expectation == .propertiesAndLayout {
            view.setNeedsLayout()
        }
    }

    private func refreshLog() {
        logView.update(recorder: recorder)
    }
}
```

Modify `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift`:

```swift
import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiViewExperiment = UIViewExperimentViewController()
        uiViewExperiment.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        let controllerExperiment = UIViewControllerExperimentViewController()
        controllerExperiment.tabBarItem = UITabBarItem(title: "Controller", image: UIImage(systemName: "rectangle.stack"), tag: 1)

        viewControllers = [
            UINavigationController(rootViewController: uiViewExperiment),
            UINavigationController(rootViewController: controllerExperiment)
        ]
    }
}
```

- [ ] **Step 2: Build and run tests**

Run:

```bash
cd uikit-update-properties-demo
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -quiet
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/RootTabBarController.swift
git commit -m "feat: add UIViewController lifecycle experiment" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: Add docs, simulator config, and final validation

**Files:**
- Modify: `uikit-update-properties-demo/README.md`
- Create: `uikit-update-properties-demo/.xcodebuildmcp/config.yaml`

**Interfaces:**
- Consumes: `UIKitUpdatePropertiesDemo.xcodeproj`
- Consumes: `UIKitUpdatePropertiesDemo` scheme

- [ ] **Step 1: Write README**

Create or replace `uikit-update-properties-demo/README.md`:

```markdown
# UIKit Update Properties Demo

一个聚焦的 UIKit demo，用来观察 iOS 26 `updateProperties()` 和 layout / constraints callbacks 的关系。

## Blog Topic

解释 `updateProperties()`、Observation tracking、`layoutSubviews()`、`updateConstraints()`、`setNeedsLayout()`、`setNeedsUpdateConstraints()` 之间的边界。

## What It Shows

- UIView 页 override `updateProperties()`、`updateConstraints()`、`layoutSubviews()` 并显示调用次数。
- UIViewController 页 override `updateProperties()`、`viewWillLayoutSubviews()`、`viewDidLayoutSubviews()` 并显示调用次数。
- `Toggle hidden` 展示 state-driven property update 不等于自动 constraint update。
- `Constraint update` 展示修改约束相关 state 后显式调用 `setNeedsUpdateConstraints()`。
- `Layout only` 展示只调用 `setNeedsLayout()` 时，layout callback 可以发生，但不应把 `updateConstraints()` 当成必然结果。

## Core Conclusion

`@Observable` 或 observation tracking 可以让 UIKit 为受影响的 view 或 view controller 重新运行 `updateProperties()`。这并不意味着 `updateConstraints()` 会自动运行。layout 和 constraint update 仍然取决于属性变化本身、UIKit 控件行为，或显式调用 `setNeedsLayout()`、`setNeedsUpdateConstraints()` 是否让 layout / constraints 失效。

## Requirements

- Xcode with iOS 26 SDK
- XcodeGen
- XcodeBuildMCP when available for simulator workflows

## Generate

```bash
xcodegen generate
```

## Run

```bash
open UIKitUpdatePropertiesDemo.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=UIKitUpdatePropertiesDemo iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `UIKitUpdatePropertiesDemo/DemoState.swift` contains observable demo state.
- `UIKitUpdatePropertiesDemo/DemoAction.swift` defines stable action copy and invalidation expectations.
- `UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift` records callback counts and event order.
- `UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift` demonstrates UIView property, constraint, and layout callbacks.
- `UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift` demonstrates UIViewController property and layout callbacks.
```

- [ ] **Step 2: Create dedicated simulator**

Run:

```bash
xcrun simctl create "UIKitUpdatePropertiesDemo iPhone 17 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
```

Expected: command prints a simulator UUID. Save that UUID as `{SimulatorId}` for the next step.

- [ ] **Step 3: Add XcodeBuildMCP config**

Create `uikit-update-properties-demo/.xcodebuildmcp/config.yaml`, replacing `{SimulatorId}` with the UUID from Step 2:

```yaml
sessionDefaults:
  projectPath: UIKitUpdatePropertiesDemo.xcodeproj
  scheme: UIKitUpdatePropertiesDemo
  configuration: Debug
  simulatorName: UIKitUpdatePropertiesDemo iPhone 17 Pro Max
  simulatorId: {SimulatorId}
  simulatorPlatform: iOS Simulator
  useLatestOS: true
  derivedDataPath: .derivedData
```

- [ ] **Step 4: Regenerate project**

Run:

```bash
cd uikit-update-properties-demo
xcodegen generate
```

Expected: `UIKitUpdatePropertiesDemo.xcodeproj` is generated or updated successfully.

- [ ] **Step 5: Validate with XcodeBuildMCP**

Use XcodeBuildMCP tools:

1. `session_show_defaults`
2. `session_set_defaults` with `projectPath` set to the generated `.xcodeproj`, `scheme` set to `UIKitUpdatePropertiesDemo`, and simulator fields from `.xcodebuildmcp/config.yaml`
3. `test_sim`
4. `build_run_sim`
5. `snapshot_ui`

Expected: tests pass, app launches, and the screenshot/UI snapshot shows two tabs named `UIView` and `Controller`.

- [ ] **Step 6: Commit final docs and generated project files**

```bash
git add uikit-update-properties-demo
git commit -m "docs: document UIKit update properties demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Self-Review

- Spec coverage: Tasks 1-5 cover project scaffold, two experiment pages, shared state/event flow, README conclusion, tests, XcodeGen, dedicated simulator config, and XcodeBuildMCP validation.
- Placeholder scan: The plan does not contain unresolved placeholder markers, incomplete sections, or deferred implementation instructions.
- Type consistency: `LifecycleEventRecorder`, `DemoAction`, `DemoState`, `InstrumentedPanelView`, and both experiment controllers use the same names and signatures across all tasks.
