# Chat Bubble Shape Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone SwiftUI demo project that shows a parameterized chat bubble matching the attached rounded lavender bubble with purple outline, soft shadow, multiline text, and left-bottom tail.

**Architecture:** Create a new XcodeGen demo at `chat-bubble-shape-demo/`. Keep geometry in `ChatBubbleShape`, visual parameters in `ChatBubbleStyle`, sample data in `BubbleSample`, and screen layout in `ContentView` so the first screen directly demonstrates the technique and the tests cover stable logic.

**Tech Stack:** SwiftUI, Swift 6.0, iOS 26.0, XcodeGen, XCTest, XcodeBuildMCP.

## Global Constraints

- Demo directory: `chat-bubble-shape-demo/`
- App and scheme name: `ChatBubbleShapeDemo`
- Bundle identifier: `com.huahuahu.demo.ChatBubbleShapeDemo`
- XcodeGen bundle ID prefix: `com.huahuahu.demo`
- Deployment target: iOS `26.0`
- Swift version: `6.0`
- Development team: empty string
- Use SwiftUI `Shape` and `Path`; do not use UIKit or snapshot testing.
- Generate `.xcodeproj` with `xcodegen generate`.
- Validate simulator tests with XcodeBuildMCP `test_sim`, not command-line `xcodebuildmcp`.

---

## File Structure

- Create `chat-bubble-shape-demo/README.md`: concise blog-friendly overview, setup, run, test commands, and key files.
- Create `chat-bubble-shape-demo/project.yml`: XcodeGen config copied from the skill template with `ChatBubbleShapeDemo` replacements.
- Create `chat-bubble-shape-demo/.xcodebuildmcp/config.yaml`: XcodeBuildMCP defaults copied from the skill template with `ChatBubbleShapeDemo` replacement.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShapeDemoApp.swift`: SwiftUI app entry point.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleStyle.swift`: style value type and presets.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/BubbleSample.swift`: hero and comparison sample data.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShape.swift`: reusable `Shape` that builds the bubble path.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleView.swift`: reusable view that applies fill, stroke, shadow, padding, and text.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ContentView.swift`: scrollable hero and comparison screen.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/BubbleSampleTests.swift`: tests for stable sample/style data.
- Create `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/ChatBubbleShapeTests.swift`: tests for non-empty paths and safe small-rect behavior.
- Generate `chat-bubble-shape-demo/ChatBubbleShapeDemo.xcodeproj/` with XcodeGen and keep it checked in.

---

### Task 1: Scaffold the XcodeGen project and sample data

**Files:**
- Create: `chat-bubble-shape-demo/project.yml`
- Create: `chat-bubble-shape-demo/.xcodebuildmcp/config.yaml`
- Create: `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShapeDemoApp.swift`
- Create: `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleStyle.swift`
- Create: `chat-bubble-shape-demo/ChatBubbleShapeDemo/BubbleSample.swift`
- Test: `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/BubbleSampleTests.swift`
- Generate: `chat-bubble-shape-demo/ChatBubbleShapeDemo.xcodeproj/`

**Interfaces:**
- Consumes: no earlier task outputs.
- Produces:
  - `struct ChatBubbleStyle: Equatable` with `fill: Color`, `stroke: Color`, `strokeWidth: CGFloat`, `cornerRadius: CGFloat`, `tailWidth: CGFloat`, `tailHeight: CGFloat`, `tailInset: CGFloat`, `shadowColor: Color`, `shadowRadius: CGFloat`, `shadowX: CGFloat`, `shadowY: CGFloat`.
  - `extension ChatBubbleStyle { static let reference: ChatBubbleStyle; static let soft: ChatBubbleStyle; static let boldOutline: ChatBubbleStyle; static let compactTail: ChatBubbleStyle }`.
  - `struct BubbleSample: Identifiable, Equatable` with `id: String`, `title: String`, `description: String`, `message: String`, `style: ChatBubbleStyle`.
  - `extension BubbleSample { static let hero: BubbleSample; static let comparisonSamples: [BubbleSample] }`.

- [ ] **Step 1: Create the project directories**

```bash
mkdir -p chat-bubble-shape-demo/.xcodebuildmcp \
  chat-bubble-shape-demo/ChatBubbleShapeDemo \
  chat-bubble-shape-demo/ChatBubbleShapeDemoTests
```

- [ ] **Step 2: Write the failing sample data test**

Create `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/BubbleSampleTests.swift`:

```swift
import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class BubbleSampleTests: XCTestCase {
    func testHeroSampleMatchesReferenceGoal() {
        let hero = BubbleSample.hero

        XCTAssertEqual(hero.id, "reference")
        XCTAssertEqual(hero.title, "Reference bubble")
        XCTAssertTrue(hero.message.contains("Japanese washi paper"))
        XCTAssertGreaterThan(hero.style.cornerRadius, 32)
        XCTAssertGreaterThan(hero.style.tailWidth, 20)
        XCTAssertGreaterThan(hero.style.strokeWidth, 4)
    }

    func testComparisonSamplesCoverVisualVariants() {
        let samples = BubbleSample.comparisonSamples

        XCTAssertEqual(samples.map(\.id), ["soft", "bold-outline", "compact-tail"])
        XCTAssertTrue(samples.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.description.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.message.isEmpty })
        XCTAssertTrue(samples.allSatisfy { $0.style.cornerRadius > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailWidth > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailHeight > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.strokeWidth > 0 })
    }
}
```

- [ ] **Step 3: Add project configuration and app entry point**

Create `chat-bubble-shape-demo/project.yml`:

```yaml
name: "ChatBubbleShapeDemo"
options:
  bundleIdPrefix: "com.huahuahu.demo"
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""
targets:
  "ChatBubbleShapeDemo":
    type: application
    platform: iOS
    sources:
      - "ChatBubbleShapeDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.ChatBubbleShapeDemo"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
    scheme:
      testTargets:
        - "ChatBubbleShapeDemoTests"
  "ChatBubbleShapeDemoTests":
    type: bundle.unit-test
    platform: iOS
    sources:
      - "ChatBubbleShapeDemoTests"
    dependencies:
      - target: "ChatBubbleShapeDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.ChatBubbleShapeDemoTests"
```

Create `chat-bubble-shape-demo/.xcodebuildmcp/config.yaml`:

```yaml
schemaVersion: 1
enabledWorkflows:
  - simulator
  - debugging
  - logging
  - ui-automation
  - utilities
debug: true
sentryDisabled: false
sessionDefaults:
  projectPath: ChatBubbleShapeDemo.xcodeproj
  scheme: ChatBubbleShapeDemo
  simulatorName: iPhone 17 Pro Max
  simulatorId: 62706291-A205-4E42-AD8C-3056825895D4
```

Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShapeDemoApp.swift`:

```swift
import SwiftUI

@main
struct ChatBubbleShapeDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Create a temporary `chat-bubble-shape-demo/ChatBubbleShapeDemo/ContentView.swift` so the app target compiles once the sample data is implemented:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(BubbleSample.hero.title)
            .padding()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Generate the Xcode project and verify the test fails**

Run:

```bash
cd chat-bubble-shape-demo
xcodegen generate
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:ChatBubbleShapeDemoTests/BubbleSampleTests
```

Expected: `xcodegen generate` succeeds. The test build fails with errors like `cannot find 'BubbleSample' in scope` and `cannot find type 'ChatBubbleStyle' in scope`.

- [ ] **Step 5: Implement style and sample data**

Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleStyle.swift`:

```swift
import SwiftUI

struct ChatBubbleStyle: Equatable {
    let fill: Color
    let stroke: Color
    let strokeWidth: CGFloat
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailInset: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
}

extension ChatBubbleStyle {
    static let reference = ChatBubbleStyle(
        fill: Color(red: 0.82, green: 0.80, blue: 1.0),
        stroke: Color(red: 0.54, green: 0.43, blue: 0.96),
        strokeWidth: 8,
        cornerRadius: 38,
        tailWidth: 28,
        tailHeight: 26,
        tailInset: 16,
        shadowColor: Color.black.opacity(0.26),
        shadowRadius: 8,
        shadowX: 0,
        shadowY: 5
    )

    static let soft = ChatBubbleStyle(
        fill: Color(red: 0.88, green: 0.94, blue: 1.0),
        stroke: Color(red: 0.52, green: 0.68, blue: 0.95),
        strokeWidth: 4,
        cornerRadius: 28,
        tailWidth: 22,
        tailHeight: 20,
        tailInset: 12,
        shadowColor: Color.black.opacity(0.14),
        shadowRadius: 5,
        shadowX: 0,
        shadowY: 3
    )

    static let boldOutline = ChatBubbleStyle(
        fill: Color(red: 0.91, green: 0.86, blue: 1.0),
        stroke: Color(red: 0.43, green: 0.28, blue: 0.92),
        strokeWidth: 10,
        cornerRadius: 34,
        tailWidth: 30,
        tailHeight: 24,
        tailInset: 18,
        shadowColor: Color.black.opacity(0.22),
        shadowRadius: 7,
        shadowX: 0,
        shadowY: 4
    )

    static let compactTail = ChatBubbleStyle(
        fill: Color(red: 0.95, green: 0.92, blue: 1.0),
        stroke: Color(red: 0.62, green: 0.50, blue: 0.98),
        strokeWidth: 5,
        cornerRadius: 24,
        tailWidth: 16,
        tailHeight: 14,
        tailInset: 10,
        shadowColor: Color.black.opacity(0.16),
        shadowRadius: 4,
        shadowX: 0,
        shadowY: 3
    )
}
```

Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/BubbleSample.swift`:

```swift
import SwiftUI

struct BubbleSample: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let message: String
    let style: ChatBubbleStyle
}

extension BubbleSample {
    static let hero = BubbleSample(
        id: "reference",
        title: "Reference bubble",
        description: "Large radius, thick purple outline, soft shadow, and a left-bottom tail.",
        message: "Maybe Japanese washi paper? I saw some beautiful traditional patterns at Mai Do while picking up some basic sheets for us.",
        style: .reference
    )

    static let comparisonSamples: [BubbleSample] = [
        BubbleSample(
            id: "soft",
            title: "Soft outline",
            description: "A thinner stroke and lighter shadow make the same shape feel quieter.",
            message: "A smaller outline keeps the bubble light while preserving the custom tail.",
            style: .soft
        ),
        BubbleSample(
            id: "bold-outline",
            title: "Bold outline",
            description: "A heavier stroke emphasizes the silhouette and tail join.",
            message: "Increasing the stroke width makes the bubble read more like a sticker.",
            style: .boldOutline
        ),
        BubbleSample(
            id: "compact-tail",
            title: "Compact tail",
            description: "A shorter tail changes the personality without changing the text layout.",
            message: "Tail width and height can be tuned independently from the rounded body.",
            style: .compactTail
        )
    ]
}
```

- [ ] **Step 6: Run the sample data tests and verify they pass**

Run:

```bash
cd chat-bubble-shape-demo
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:ChatBubbleShapeDemoTests/BubbleSampleTests
```

Expected: `BubbleSampleTests` passes.

- [ ] **Step 7: Commit the scaffold and sample data**

```bash
git add chat-bubble-shape-demo
git commit -m "Add chat bubble demo scaffold" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Implement the reusable chat bubble shape

**Files:**
- Create: `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShape.swift`
- Test: `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/ChatBubbleShapeTests.swift`

**Interfaces:**
- Consumes: `ChatBubbleStyle` from Task 1.
- Produces:
  - `struct ChatBubbleShape: Shape`
  - `init(cornerRadius: CGFloat, tailWidth: CGFloat, tailHeight: CGFloat, tailInset: CGFloat)`
  - `func path(in rect: CGRect) -> Path`

- [ ] **Step 1: Write the failing shape tests**

Create `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/ChatBubbleShapeTests.swift`:

```swift
import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class ChatBubbleShapeTests: XCTestCase {
    func testReferenceShapeProducesNonEmptyPathInsideRequestedRect() {
        let style = ChatBubbleStyle.reference
        let shape = ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )

        let rect = CGRect(x: 0, y: 0, width: 320, height: 180)
        let bounds = shape.path(in: rect).boundingRect

        XCTAssertFalse(bounds.isNull)
        XCTAssertGreaterThan(bounds.width, 250)
        XCTAssertGreaterThan(bounds.height, 140)
        XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY)
    }

    func testShapeClampsGeometryForSmallRects() {
        let shape = ChatBubbleShape(
            cornerRadius: 80,
            tailWidth: 60,
            tailHeight: 60,
            tailInset: 40
        )

        let rect = CGRect(x: 0, y: 0, width: 48, height: 36)
        let bounds = shape.path(in: rect).boundingRect

        XCTAssertFalse(bounds.isNull)
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
        XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY)
    }
}
```

- [ ] **Step 2: Run the shape tests and verify they fail**

Run:

```bash
cd chat-bubble-shape-demo
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:ChatBubbleShapeDemoTests/ChatBubbleShapeTests
```

Expected: build fails with `cannot find 'ChatBubbleShape' in scope`.

- [ ] **Step 3: Implement the shape**

Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShape.swift`:

```swift
import SwiftUI

struct ChatBubbleShape: Shape {
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailInset: CGFloat

    func path(in rect: CGRect) -> Path {
        let minimumSide = max(0, min(rect.width, rect.height))
        let safeTailWidth = clamp(tailWidth, lower: 0, upper: rect.width * 0.35)
        let safeTailHeight = clamp(tailHeight, lower: 0, upper: rect.height * 0.45)
        let safeTailInset = clamp(tailInset, lower: 0, upper: rect.height * 0.35)
        let safeRadius = clamp(cornerRadius, lower: 0, upper: minimumSide * 0.5)

        let body = CGRect(
            x: rect.minX + safeTailWidth,
            y: rect.minY,
            width: max(0, rect.width - safeTailWidth),
            height: rect.height - safeTailHeight * 0.15
        )

        let tailTip = CGPoint(
            x: rect.minX + safeTailWidth * 0.12,
            y: min(rect.maxY, body.maxY + safeTailHeight * 0.55)
        )
        let tailTop = CGPoint(
            x: body.minX + safeRadius * 0.55,
            y: max(body.minY + safeRadius, body.maxY - safeTailInset - safeTailHeight)
        )
        let tailJoin = CGPoint(
            x: body.minX + safeRadius * 0.35,
            y: body.maxY - safeTailInset
        )

        var path = Path()
        path.move(to: CGPoint(x: body.minX + safeRadius, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - safeRadius, y: body.minY))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX, y: body.minY + safeRadius),
            control: CGPoint(x: body.maxX, y: body.minY)
        )
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX - safeRadius, y: body.maxY),
            control: CGPoint(x: body.maxX, y: body.maxY)
        )
        path.addLine(to: tailJoin)
        path.addQuadCurve(
            to: tailTip,
            control: CGPoint(x: body.minX + safeTailWidth * 0.15, y: body.maxY + safeTailHeight * 0.15)
        )
        path.addQuadCurve(
            to: tailTop,
            control: CGPoint(x: body.minX - safeTailWidth * 0.15, y: body.maxY - safeTailInset)
        )
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: body.minX + safeRadius, y: body.minY),
            control: CGPoint(x: body.minX, y: body.minY)
        )
        path.closeSubpath()
        return path
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}
```

- [ ] **Step 4: Run the shape tests and verify they pass**

Run:

```bash
cd chat-bubble-shape-demo
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:ChatBubbleShapeDemoTests/ChatBubbleShapeTests
```

Expected: `ChatBubbleShapeTests` passes.

- [ ] **Step 5: Commit the shape**

```bash
git add chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleShape.swift chat-bubble-shape-demo/ChatBubbleShapeDemoTests/ChatBubbleShapeTests.swift
git commit -m "Add reusable chat bubble shape" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Build the SwiftUI comparison screen

**Files:**
- Create: `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleView.swift`
- Modify: `chat-bubble-shape-demo/ChatBubbleShapeDemo/ContentView.swift`
- Modify: `chat-bubble-shape-demo/ChatBubbleShapeDemoTests/BubbleSampleTests.swift`

**Interfaces:**
- Consumes: `ChatBubbleShape`, `ChatBubbleStyle`, `BubbleSample.hero`, and `BubbleSample.comparisonSamples`.
- Produces:
  - `struct ChatBubbleView: View`
  - `init(message: String, style: ChatBubbleStyle, font: Font = .body)`
  - `struct ContentView: View` showing a hero section and comparison samples.

- [ ] **Step 1: Add a failing reusable view construction test**

Append this test method to `BubbleSampleTests`:

```swift
    func testChatBubbleViewCanBeConstructedWithPresetData() {
        let view = ChatBubbleView(
            message: BubbleSample.hero.message,
            style: BubbleSample.hero.style,
            font: .title2
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(BubbleSample.comparisonSamples.count, 3)
    }
```

The full file should be:

```swift
import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class BubbleSampleTests: XCTestCase {
    func testHeroSampleMatchesReferenceGoal() {
        let hero = BubbleSample.hero

        XCTAssertEqual(hero.id, "reference")
        XCTAssertEqual(hero.title, "Reference bubble")
        XCTAssertTrue(hero.message.contains("Japanese washi paper"))
        XCTAssertGreaterThan(hero.style.cornerRadius, 32)
        XCTAssertGreaterThan(hero.style.tailWidth, 20)
        XCTAssertGreaterThan(hero.style.strokeWidth, 4)
    }

    func testComparisonSamplesCoverVisualVariants() {
        let samples = BubbleSample.comparisonSamples

        XCTAssertEqual(samples.map(\.id), ["soft", "bold-outline", "compact-tail"])
        XCTAssertTrue(samples.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.description.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.message.isEmpty })
        XCTAssertTrue(samples.allSatisfy { $0.style.cornerRadius > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailWidth > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailHeight > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.strokeWidth > 0 })
    }

    func testChatBubbleViewCanBeConstructedWithPresetData() {
        let view = ChatBubbleView(
            message: BubbleSample.hero.message,
            style: BubbleSample.hero.style,
            font: .title2
        )

        XCTAssertNotNil(view)
        XCTAssertEqual(BubbleSample.comparisonSamples.count, 3)
    }
}
```

- [ ] **Step 2: Run the reusable view construction test and verify it fails**

Run:

```bash
cd chat-bubble-shape-demo
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest' -only-testing:ChatBubbleShapeDemoTests/BubbleSampleTests/testChatBubbleViewCanBeConstructedWithPresetData
```

Expected: build fails with `cannot find 'ChatBubbleView' in scope`.

- [ ] **Step 3: Implement the reusable bubble view**

Create `chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleView.swift`:

```swift
import SwiftUI

struct ChatBubbleView: View {
    let message: String
    let style: ChatBubbleStyle
    let font: Font

    init(message: String, style: ChatBubbleStyle, font: Font = .body) {
        self.message = message
        self.style = style
        self.font = font
    }

    var body: some View {
        Text(message)
            .font(font)
            .foregroundStyle(Color(red: 0.12, green: 0.11, blue: 0.18))
            .lineSpacing(5)
            .padding(.leading, style.tailWidth + 20)
            .padding(.trailing, 26)
            .padding(.vertical, 24)
            .background {
                bubbleShape
                    .fill(style.fill)
                    .shadow(
                        color: style.shadowColor,
                        radius: style.shadowRadius,
                        x: style.shadowX,
                        y: style.shadowY
                    )
            }
            .overlay {
                bubbleShape
                    .stroke(style.stroke, lineWidth: style.strokeWidth)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(message)
    }

    private var bubbleShape: ChatBubbleShape {
        ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )
    }
}

#Preview {
    ChatBubbleView(
        message: BubbleSample.hero.message,
        style: .reference,
        font: .title2
    )
    .padding()
}
```

- [ ] **Step 4: Replace the temporary content screen**

Replace `chat-bubble-shape-demo/ChatBubbleShapeDemo/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                heroSection
                comparisonSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.94, blue: 0.98),
                    Color(red: 0.96, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat Bubble Shape")
                .font(.largeTitle.bold())
            Text("One reusable SwiftUI Shape drives the reference bubble and every variant below.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(BubbleSample.hero.title)
                .font(.headline)
            ChatBubbleView(
                message: BubbleSample.hero.message,
                style: BubbleSample.hero.style,
                font: .title2
            )
            Text(BubbleSample.hero.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Variants")
                .font(.title2.bold())

            ForEach(BubbleSample.comparisonSamples) { sample in
                VStack(alignment: .leading, spacing: 8) {
                    Text(sample.title)
                        .font(.headline)
                    Text(sample.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ChatBubbleView(message: sample.message, style: sample.style)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 5: Run app tests and verify they pass**

Run:

```bash
cd chat-bubble-shape-demo
xcodebuild test -project ChatBubbleShapeDemo.xcodeproj -scheme ChatBubbleShapeDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: all tests pass.

- [ ] **Step 6: Commit the comparison screen**

```bash
git add chat-bubble-shape-demo/ChatBubbleShapeDemo/ChatBubbleView.swift \
  chat-bubble-shape-demo/ChatBubbleShapeDemo/ContentView.swift \
  chat-bubble-shape-demo/ChatBubbleShapeDemoTests/BubbleSampleTests.swift
git commit -m "Build chat bubble comparison screen" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Add README and final XcodeBuildMCP validation

**Files:**
- Modify: `chat-bubble-shape-demo/README.md`
- Regenerate: `chat-bubble-shape-demo/ChatBubbleShapeDemo.xcodeproj/`

**Interfaces:**
- Consumes: all app files and tests from Tasks 1-3.
- Produces: completed blog-friendly demo documentation and generated project.

- [ ] **Step 1: Write the README**

Create or replace `chat-bubble-shape-demo/README.md`:

```markdown
# Chat Bubble Shape Demo

A focused SwiftUI demo for building a parameterized chat bubble with a rounded body, left-bottom tail, purple stroke, lavender fill, soft shadow, and multiline text.

## Blog Topic

Using SwiftUI `Shape` and `Path` to implement a reusable chat bubble silhouette and compare visual parameters such as corner radius, tail size, stroke width, and shadow.

## Requirements

- Xcode with iOS Simulator support
- iOS 26.0 SDK
- Swift 6.0
- XcodeGen
- XcodeBuildMCP for simulator validation

## Generate

```bash
xcodegen generate
```

## Run

```bash
open ChatBubbleShapeDemo.xcodeproj
```

Then run the `ChatBubbleShapeDemo` scheme on an iOS Simulator.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `ChatBubbleShapeDemo` scheme.

## Key Files

- `ChatBubbleShapeDemo/ChatBubbleShape.swift` builds the custom bubble `Path`.
- `ChatBubbleShapeDemo/ChatBubbleStyle.swift` stores visual parameters and presets.
- `ChatBubbleShapeDemo/BubbleSample.swift` defines the hero and comparison samples.
- `ChatBubbleShapeDemo/ChatBubbleView.swift` applies fill, stroke, shadow, padding, and text.
- `ChatBubbleShapeDemo/ContentView.swift` presents the reference bubble and variants.
- `ChatBubbleShapeDemoTests/` verifies preset data and path behavior.
```

- [ ] **Step 2: Regenerate the Xcode project**

Run:

```bash
cd chat-bubble-shape-demo
xcodegen generate
```

Expected: output includes `Project "ChatBubbleShapeDemo" generated.`

- [ ] **Step 3: Configure XcodeBuildMCP defaults**

Use XcodeBuildMCP tool `session_set_defaults` with:

```text
projectPath: /Users/tigerguo/git/copilot-worktrees/learn projects/huahuahu-curly-guide/chat-bubble-shape-demo/ChatBubbleShapeDemo.xcodeproj
scheme: ChatBubbleShapeDemo
simulatorName: iPhone 17 Pro Max
simulatorPlatform: iOS Simulator
useLatestOS: true
```

Expected: the active session defaults show `ChatBubbleShapeDemo` as the scheme.

- [ ] **Step 4: Run final simulator tests with XcodeBuildMCP**

Use XcodeBuildMCP tool `test_sim` with no extra arguments.

Expected: test action succeeds for `ChatBubbleShapeDemoTests`.

- [ ] **Step 5: Commit README, generated project, and final validation-ready files**

```bash
git add chat-bubble-shape-demo
git commit -m "Document chat bubble shape demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Plan Self-Review

- Spec coverage: Task 1 creates the standalone XcodeGen project, app/scheme names, bundle identifier, config, sample data, and generated project. Task 2 implements the reusable SwiftUI `Shape`/`Path` with clamping. Task 3 builds the hero and comparison screen. Task 4 writes the README and performs XcodeBuildMCP simulator validation.
- Placeholder scan: no deferred implementation markers or unspecified validation steps remain.
- Type consistency: `ChatBubbleStyle`, `BubbleSample`, `ChatBubbleShape`, `ChatBubbleView`, and `ContentView` names and signatures are consistent across tasks.
