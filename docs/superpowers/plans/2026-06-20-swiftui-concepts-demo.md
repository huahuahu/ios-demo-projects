# SwiftUI Concepts Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone SwiftUI demo project that explains how `Shape`, `View`, `ShapeStyle`, `Color`, modifier chains, and `InsettableShape` relate to each other.

**Architecture:** The demo is a single-screen SwiftUI app backed by pure Swift metadata models. Static concept and experiment data drive both the UI and Swift Testing coverage, while focused SwiftUI components render the relationship map and four small interactive experiments.

**Tech Stack:** SwiftUI, Swift 6.0, iOS 26.0, XcodeGen, Swift Testing, XcodeBuildMCP.

## Global Constraints

- Directory: `swiftui-shape-view-style-color/`
- App and scheme: `SwiftUIShapeViewStyleColor`
- Bundle prefix: `com.huahuahu.demo`
- Tooling: XcodeGen with `project.yml` and `.xcodebuildmcp/config.yaml`
- Minimum platform: iOS 26.0, Swift 6.0
- Keep the demo single-screen; do not add deep navigation.
- Do not add networking, persistence, asynchronous workflows, or third-party dependencies.
- UI control state must use enums or simple value types; do not drive behavior through string matching.
- Tests use Swift Testing in `SwiftUIShapeViewStyleColorTests`.

---

## File Structure

- Create `swiftui-shape-view-style-color/project.yml`: XcodeGen project definition copied from the repository skill template with placeholders replaced.
- Create `swiftui-shape-view-style-color/.xcodebuildmcp/config.yaml`: XcodeBuildMCP defaults copied from the repository skill template with `{DemoName}` replaced.
- Create `swiftui-shape-view-style-color/README.md`: blog-friendly overview, setup, run, test, and key files.
- Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/SwiftUIShapeViewStyleColorApp.swift`: SwiftUI app entry point.
- Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/DemoModel.swift`: pure Swift enums and static metadata for concepts, relationships, experiments, shapes, colors, styles, and stroke modes.
- Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift`: screen layout, local selection state, relationship map, picker, and four experiments.
- Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift`: Swift Testing coverage for concept order, non-empty copy, experiment metadata, and relationship edges.

---

### Task 1: Project Scaffold

**Files:**
- Create: `swiftui-shape-view-style-color/project.yml`
- Create: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/SwiftUIShapeViewStyleColorApp.swift`
- Create: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift`
- Create: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift`

**Interfaces:**
- Consumes: repository XcodeGen template values `{DemoName}=SwiftUIShapeViewStyleColor`, `{BundleIdPrefix}=com.huahuahu.demo`, `{DeploymentTarget}=26.0`, `{SwiftVersion}=6.0`, `{DevelopmentTeam}=`.
- Produces: app target `SwiftUIShapeViewStyleColor`, test target `SwiftUIShapeViewStyleColorTests`, and a compilable placeholder `ContentView`.

- [ ] **Step 1: Create directories**

Run:

```bash
mkdir -p swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests
```

Expected: directories exist and `git status --short` shows `?? swiftui-shape-view-style-color/`.

- [ ] **Step 2: Add XcodeGen project definition**

Create `swiftui-shape-view-style-color/project.yml`:

```yaml
name: "SwiftUIShapeViewStyleColor"
options:
  bundleIdPrefix: "com.huahuahu.demo"
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""
targets:
  "SwiftUIShapeViewStyleColor":
    type: application
    platform: iOS
    sources:
      - "SwiftUIShapeViewStyleColor"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.SwiftUIShapeViewStyleColor"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
    scheme:
      testTargets:
        - "SwiftUIShapeViewStyleColorTests"
  "SwiftUIShapeViewStyleColorTests":
    type: bundle.unit-test
    platform: iOS
    sources:
      - "SwiftUIShapeViewStyleColorTests"
    dependencies:
      - target: "SwiftUIShapeViewStyleColor"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.SwiftUIShapeViewStyleColorTests"
```

- [ ] **Step 3: Add placeholder app and view**

Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/SwiftUIShapeViewStyleColorApp.swift`:

```swift
import SwiftUI

@main
struct SwiftUIShapeViewStyleColorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("SwiftUI Shape / View / Style / Color")
            .padding()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Add an initial failing test target file**

Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift`:

```swift
@testable import SwiftUIShapeViewStyleColor
import Foundation
import Testing

struct DemoModelTests {
    @Test func conceptNodesExistInTeachingOrder() {
        #expect(ConceptNode.teachingOrder.map(\.id) == [
            "shape",
            "view",
            "shapeStyle",
            "color",
            "modifier",
            "insettableShape",
        ])
    }
}
```

This test intentionally fails until Task 2 creates `ConceptNode`.

- [ ] **Step 5: Generate the Xcode project**

Run:

```bash
cd swiftui-shape-view-style-color && xcodegen generate
```

Expected: `SwiftUIShapeViewStyleColor.xcodeproj` is generated.

- [ ] **Step 6: Run the failing test once**

Use XcodeBuildMCP if session defaults are already set; otherwise this direct fallback is acceptable during plan execution setup:

```bash
cd swiftui-shape-view-style-color && xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: FAIL with a compile error containing `Cannot find 'ConceptNode' in scope`.

- [ ] **Step 7: Commit scaffold**

```bash
git add swiftui-shape-view-style-color
git commit -m "Add SwiftUI concepts demo scaffold" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Concept and Experiment Model

**Files:**
- Create: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/DemoModel.swift`
- Modify: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift`

**Interfaces:**
- Consumes: the app module `SwiftUIShapeViewStyleColor`.
- Produces:
  - `struct ConceptNode: Identifiable, Equatable` with `id: String`, `title: String`, `summary: String`, `symbolName: String`, and static `teachingOrder: [ConceptNode]`.
  - `struct ConceptRelationship: Equatable` with `source: String`, `target: String`, `label: String`, and static `expected: [ConceptRelationship]`.
  - `enum Experiment: String, CaseIterable, Identifiable` with `id`, `title`, and `summary`.
  - `enum DemoShapeKind: String, CaseIterable, Identifiable`, `enum DemoShapeStyleKind: String, CaseIterable, Identifiable`, `enum DemoColorKind: String, CaseIterable, Identifiable`, and `enum StrokeMode: String, CaseIterable, Identifiable`.

- [ ] **Step 1: Expand tests before implementation**

Replace `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift` with:

```swift
@testable import SwiftUIShapeViewStyleColor
import Testing

struct DemoModelTests {
    @Test func conceptNodesExistInTeachingOrder() {
        #expect(ConceptNode.teachingOrder.map(\.id) == [
            "shape",
            "view",
            "shapeStyle",
            "color",
            "modifier",
            "insettableShape",
        ])
    }

    @Test func conceptNodesHaveReadableCopy() {
        for node in ConceptNode.teachingOrder {
            #expect(!node.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!node.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!node.symbolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test func experimentsHaveStableIdentityAndCopy() {
        #expect(Experiment.allCases.map(\.id) == [
            "shape-becomes-view",
            "shape-style-paints-shape",
            "color-as-shape-style",
            "stroke-vs-stroke-border",
        ])

        for experiment in Experiment.allCases {
            #expect(!experiment.title.isEmpty)
            #expect(!experiment.summary.isEmpty)
        }
    }

    @Test func relationshipEdgesExplainCoreConcepts() {
        #expect(ConceptRelationship.expected.contains(.init(
            source: "shape",
            target: "view",
            label: "becomes visible as"
        )))
        #expect(ConceptRelationship.expected.contains(.init(
            source: "shapeStyle",
            target: "shape",
            label: "paints"
        )))
        #expect(ConceptRelationship.expected.contains(.init(
            source: "color",
            target: "shapeStyle",
            label: "is a simple"
        )))
        #expect(ConceptRelationship.expected.contains(.init(
            source: "modifier",
            target: "view",
            label: "returns a new"
        )))
        #expect(ConceptRelationship.expected.contains(.init(
            source: "insettableShape",
            target: "strokeBorder",
            label: "enables"
        )))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
cd swiftui-shape-view-style-color && xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: FAIL with compile errors for missing `ConceptNode`, `Experiment`, and `ConceptRelationship`.

- [ ] **Step 3: Add model implementation**

Create `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/DemoModel.swift`:

```swift
import Foundation

struct ConceptNode: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let symbolName: String

    static let teachingOrder: [ConceptNode] = [
        .init(id: "shape", title: "Shape", summary: "描述几何轮廓，例如 Circle、RoundedRectangle 或自定义 Path。", symbolName: "circle.hexagongrid"),
        .init(id: "view", title: "View", summary: "SwiftUI 可以放进层级并参与 layout、渲染和 modifier 链的节点。", symbolName: "rectangle.stack"),
        .init(id: "shapeStyle", title: "ShapeStyle", summary: "决定 shape 如何被填充、描边或绘制，几何和外观因此可以分开。", symbolName: "paintpalette"),
        .init(id: "color", title: "Color", summary: "颜色值本身也符合 ShapeStyle，是最常见的绘制输入。", symbolName: "drop.fill"),
        .init(id: "modifier", title: "Modifier", summary: "fill、stroke、foregroundStyle 等 modifier 接收值并返回新的 view。", symbolName: "slider.horizontal.3"),
        .init(id: "insettableShape", title: "InsettableShape", summary: "允许 shape 向内收缩，因此 strokeBorder 可以把描边放在边界内侧。", symbolName: "inset.filled.rectangle"),
    ]
}

struct ConceptRelationship: Equatable {
    let source: String
    let target: String
    let label: String

    static let expected: [ConceptRelationship] = [
        .init(source: "shape", target: "view", label: "becomes visible as"),
        .init(source: "shapeStyle", target: "shape", label: "paints"),
        .init(source: "color", target: "shapeStyle", label: "is a simple"),
        .init(source: "modifier", target: "view", label: "returns a new"),
        .init(source: "insettableShape", target: "strokeBorder", label: "enables"),
    ]
}

enum Experiment: String, CaseIterable, Identifiable {
    case shapeBecomesView
    case shapeStylePaintsShape
    case colorAsShapeStyle
    case strokeVsStrokeBorder

    var id: String {
        switch self {
        case .shapeBecomesView: "shape-becomes-view"
        case .shapeStylePaintsShape: "shape-style-paints-shape"
        case .colorAsShapeStyle: "color-as-shape-style"
        case .strokeVsStrokeBorder: "stroke-vs-stroke-border"
        }
    }

    var title: String {
        switch self {
        case .shapeBecomesView: "Shape becomes View"
        case .shapeStylePaintsShape: "ShapeStyle paints Shape"
        case .colorAsShapeStyle: "Color as ShapeStyle"
        case .strokeVsStrokeBorder: "Stroke vs StrokeBorder"
        }
    }

    var summary: String {
        switch self {
        case .shapeBecomesView:
            "Shape 描述几何；当它进入 view tree 并获得尺寸、填充或描边后，才变成可见界面。"
        case .shapeStylePaintsShape:
            "同一个 shape 可以使用不同 ShapeStyle 绘制，说明几何和外观是两个独立选择。"
        case .colorAsShapeStyle:
            "Color 是最简单的 ShapeStyle，也可以和 gradient、material 这类 style 放在同一位置理解。"
        case .strokeVsStrokeBorder:
            "stroke 沿边界居中绘制；strokeBorder 依赖 InsettableShape，把描边约束在边界内。"
        }
    }
}

enum DemoShapeKind: String, CaseIterable, Identifiable {
    case circle
    case roundedRectangle
    case capsule

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circle: "Circle"
        case .roundedRectangle: "RoundedRectangle"
        case .capsule: "Capsule"
        }
    }
}

enum DemoShapeStyleKind: String, CaseIterable, Identifiable {
    case solid
    case gradient
    case material

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid: "Color"
        case .gradient: "Gradient"
        case .material: "Material"
        }
    }
}

enum DemoColorKind: String, CaseIterable, Identifiable {
    case blue
    case orange
    case purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: "Blue"
        case .orange: "Orange"
        case .purple: "Purple"
        }
    }
}

enum StrokeMode: String, CaseIterable, Identifiable {
    case stroke
    case strokeBorder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stroke: ".stroke()"
        case .strokeBorder: ".strokeBorder()"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd swiftui-shape-view-style-color && xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: PASS for all `DemoModelTests`.

- [ ] **Step 5: Commit model and tests**

```bash
git add swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/DemoModel.swift swiftui-shape-view-style-color/SwiftUIShapeViewStyleColorTests/DemoModelTests.swift
git commit -m "Add SwiftUI concept metadata model" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Single-Screen SwiftUI Demo UI

**Files:**
- Modify: `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift`

**Interfaces:**
- Consumes: `ConceptNode.teachingOrder`, `ConceptRelationship.expected`, `Experiment.allCases`, `DemoShapeKind`, `DemoShapeStyleKind`, `DemoColorKind`, and `StrokeMode` from Task 2.
- Produces: `ContentView`, `RelationshipDiagram`, `ConceptCard`, `ExperimentPicker`, `ShapeBecomesViewExperiment`, `ShapeStylePaintsShapeExperiment`, `ColorAsShapeStyleExperiment`, and `StrokeVsStrokeBorderExperiment`.

- [ ] **Step 1: Replace placeholder UI with full demo UI**

Replace `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedExperiment: Experiment = .shapeBecomesView
    @State private var selectedShape: DemoShapeKind = .circle
    @State private var selectedStyle: DemoShapeStyleKind = .solid
    @State private var selectedColor: DemoColorKind = .blue
    @State private var strokeMode: StrokeMode = .stroke
    @State private var lineWidth = 20.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    RelationshipDiagram(nodes: ConceptNode.teachingOrder)
                    ExperimentPicker(selection: $selectedExperiment)
                    activeExperiment
                }
                .padding()
            }
            .navigationTitle("SwiftUI Concepts")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shape -> View -> Modifier")
                .font(.largeTitle.bold())
            Text("Shape 提供几何，ShapeStyle 提供绘制方式，modifier 把这些选择组合成新的 View。")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var activeExperiment: some View {
        switch selectedExperiment {
        case .shapeBecomesView:
            ShapeBecomesViewExperiment(shape: $selectedShape, color: $selectedColor)
        case .shapeStylePaintsShape:
            ShapeStylePaintsShapeExperiment(shape: $selectedShape, style: $selectedStyle)
        case .colorAsShapeStyle:
            ColorAsShapeStyleExperiment(color: $selectedColor)
        case .strokeVsStrokeBorder:
            StrokeVsStrokeBorderExperiment(mode: $strokeMode, lineWidth: $lineWidth)
        }
    }
}

private struct RelationshipDiagram: View {
    let nodes: [ConceptNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Concept Map", systemImage: "map")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(nodes) { node in
                    ConceptCard(node: node)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(ConceptRelationship.expected, id: \.label) { relationship in
                    Text("\(relationship.source) -> \(relationship.target): \(relationship.label)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct ConceptCard: View {
    let node: ConceptNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(node.title, systemImage: node.symbolName)
                .font(.headline)
            Text(node.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

private struct ExperimentPicker: View {
    @Binding var selection: Experiment

    var body: some View {
        Picker("Experiment", selection: $selection) {
            ForEach(Experiment.allCases) { experiment in
                Text(experiment.title).tag(experiment)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct ShapeBecomesViewExperiment: View {
    @Binding var shape: DemoShapeKind
    @Binding var color: DemoColorKind

    var body: some View {
        ExperimentSection(experiment: .shapeBecomesView) {
            Picker("Shape", selection: $shape) {
                ForEach(DemoShapeKind.allCases) { shape in
                    Text(shape.title).tag(shape)
                }
            }
            .pickerStyle(.segmented)

            Picker("Color", selection: $color) {
                ForEach(DemoColorKind.allCases) { color in
                    Text(color.title).tag(color)
                }
            }
            .pickerStyle(.segmented)

            demoShape(shape)
                .fill(swiftUIColor(color))
                .frame(height: 160)
                .overlay(alignment: .bottom) {
                    Text("\(shape.title)().fill(\(color.title.lowercased()))")
                        .font(.caption.monospaced())
                        .padding(8)
                        .background(.thinMaterial, in: Capsule())
                        .padding()
                }
        }
    }
}

private struct ShapeStylePaintsShapeExperiment: View {
    @Binding var shape: DemoShapeKind
    @Binding var style: DemoShapeStyleKind

    var body: some View {
        ExperimentSection(experiment: .shapeStylePaintsShape) {
            Picker("Shape", selection: $shape) {
                ForEach(DemoShapeKind.allCases) { shape in
                    Text(shape.title).tag(shape)
                }
            }
            .pickerStyle(.segmented)

            Picker("Style", selection: $style) {
                ForEach(DemoShapeStyleKind.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)

            demoShape(shape)
                .fill(shapeStyle(style))
                .frame(height: 160)
                .overlay {
                    demoShape(shape)
                        .stroke(.primary.opacity(0.25), lineWidth: 2)
                }
        }
    }
}

private struct ColorAsShapeStyleExperiment: View {
    @Binding var color: DemoColorKind

    var body: some View {
        ExperimentSection(experiment: .colorAsShapeStyle) {
            Picker("Color", selection: $color) {
                ForEach(DemoColorKind.allCases) { color in
                    Text(color.title).tag(color)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                Circle()
                    .fill(swiftUIColor(color))
                    .overlay(Text("Color").font(.caption.bold()).foregroundStyle(.white))
                Circle()
                    .fill(.linearGradient(colors: [.pink, swiftUIColor(color)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Text("Gradient").font(.caption.bold()).foregroundStyle(.white))
            }
            .frame(height: 150)
        }
    }
}

private struct StrokeVsStrokeBorderExperiment: View {
    @Binding var mode: StrokeMode
    @Binding var lineWidth: Double

    var body: some View {
        ExperimentSection(experiment: .strokeVsStrokeBorder) {
            Picker("Stroke Mode", selection: $mode) {
                ForEach(StrokeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Slider(value: $lineWidth, in: 4...36) {
                Text("Line Width")
            }

            ZStack {
                RoundedRectangle(cornerRadius: 36)
                    .fill(.blue.opacity(0.12))
                RoundedRectangle(cornerRadius: 36)
                    .stroke(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6]))
                if mode == .stroke {
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(.orange, lineWidth: lineWidth)
                } else {
                    RoundedRectangle(cornerRadius: 36)
                        .strokeBorder(.orange, lineWidth: lineWidth)
                }
            }
            .frame(height: 170)
        }
    }
}

private struct ExperimentSection<Content: View>: View {
    let experiment: Experiment
    let content: Content

    init(experiment: Experiment, @ViewBuilder content: () -> Content) {
        self.experiment = experiment
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(experiment.title)
                .font(.title2.bold())
            Text(experiment.summary)
                .font(.body)
                .foregroundStyle(.secondary)
            content
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
        }
    }
}

private struct DemoShape: InsettableShape {
    let kind: DemoShapeKind
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        switch kind {
        case .circle:
            return Circle().path(in: insetRect)
        case .roundedRectangle:
            return RoundedRectangle(cornerRadius: 32).path(in: insetRect)
        case .capsule:
            return Capsule().path(in: insetRect)
        }
    }

    func inset(by amount: CGFloat) -> DemoShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

private func demoShape(_ shape: DemoShapeKind) -> DemoShape {
    DemoShape(kind: shape)
}

private func swiftUIColor(_ color: DemoColorKind) -> Color {
    switch color {
    case .blue: .blue
    case .orange: .orange
    case .purple: .purple
    }
}

private func shapeStyle(_ style: DemoShapeStyleKind) -> AnyShapeStyle {
    switch style {
    case .solid:
        AnyShapeStyle(.blue)
    case .gradient:
        AnyShapeStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
    case .material:
        AnyShapeStyle(.regularMaterial)
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 2: Build to catch SwiftUI type errors**

Run:

```bash
cd swiftui-shape-view-style-color && xcodebuild build -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run model tests to ensure UI changes did not regress metadata**

Run:

```bash
cd swiftui-shape-view-style-color && xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: PASS for all tests.

- [ ] **Step 4: Commit UI**

```bash
git add swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor/ContentView.swift
git commit -m "Add SwiftUI concepts demo UI" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: README, XcodeBuildMCP Config, and Final Validation

**Files:**
- Create: `swiftui-shape-view-style-color/README.md`
- Create: `swiftui-shape-view-style-color/.xcodebuildmcp/config.yaml`
- Modify: generated `swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor.xcodeproj/**` after running XcodeGen

**Interfaces:**
- Consumes: app target and tests from Tasks 1-3.
- Produces: blog-friendly project documentation, checked-in XcodeBuildMCP defaults, generated `.xcodeproj`, and final simulator test evidence.

- [ ] **Step 1: Add README**

Create `swiftui-shape-view-style-color/README.md`:

```markdown
# SwiftUI Shape / View / Style / Color

A focused SwiftUI demo that explains how `Shape`, `View`, `ShapeStyle`, `Color`, modifier chains, and `InsettableShape` fit together.

## Blog Topic

Understanding the relationship between SwiftUI drawing concepts: geometry (`Shape`), renderable UI (`View`), painting (`ShapeStyle`), color values, modifiers, and `strokeBorder`.

## What It Shows

- `Shape` describes geometry before appearance is chosen.
- `Shape` becomes visible as a `View` when it participates in layout and rendering.
- `ShapeStyle` paints a shape without changing its geometry.
- `Color` is a concrete value that can also be used as a `ShapeStyle`.
- Modifiers such as `.fill()`, `.stroke()`, and `.foregroundStyle()` return new views.
- `InsettableShape` explains why `.strokeBorder()` can draw inside a shape boundary.

## Requirements

- Xcode with iOS Simulator support
- XcodeGen
- XcodeBuildMCP when available for simulator workflows
- iOS 26.0 SDK baseline
- Swift 6.0

## Generate

```bash
xcodegen generate
```

## Run

```bash
open SwiftUIShapeViewStyleColor.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `SwiftUIShapeViewStyleColor/DemoModel.swift` defines concept metadata, relationship edges, and experiment options.
- `SwiftUIShapeViewStyleColor/ContentView.swift` renders the relationship map and four experiments.
- `SwiftUIShapeViewStyleColorTests/DemoModelTests.swift` verifies the teaching order, experiment metadata, and concept relationships.
```

- [ ] **Step 2: Add XcodeBuildMCP config**

Create `swiftui-shape-view-style-color/.xcodebuildmcp/config.yaml`:

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
  projectPath: SwiftUIShapeViewStyleColor.xcodeproj
  scheme: SwiftUIShapeViewStyleColor
  simulatorName: iPhone 17 Pro Max
  simulatorId: 62706291-A205-4E42-AD8C-3056825895D4
```

- [ ] **Step 3: Regenerate project**

Run:

```bash
cd swiftui-shape-view-style-color && xcodegen generate
```

Expected: `SwiftUIShapeViewStyleColor.xcodeproj` exists and includes sources, tests, and a shared scheme.

- [ ] **Step 4: Configure XcodeBuildMCP defaults**

Use XcodeBuildMCP `session_set_defaults` with:

```text
projectPath: /Users/tigerguo/git/copilot-worktrees/learn projects/huahuahu-friendly-adventure/swiftui-shape-view-style-color/SwiftUIShapeViewStyleColor.xcodeproj
scheme: SwiftUIShapeViewStyleColor
simulatorName: iPhone 17 Pro Max
simulatorId: 62706291-A205-4E42-AD8C-3056825895D4
```

Expected: XcodeBuildMCP session defaults point at the new demo.

- [ ] **Step 5: Run simulator tests through XcodeBuildMCP**

Use XcodeBuildMCP `test_sim`.

Expected: all tests pass on the configured iOS Simulator.

- [ ] **Step 6: Run the app through XcodeBuildMCP**

Use XcodeBuildMCP `build_run_sim`.

Expected: app builds, installs, and launches on the configured iOS Simulator.

- [ ] **Step 7: Commit docs, config, generated project, and validation-ready state**

```bash
git add swiftui-shape-view-style-color
git commit -m "Document and validate SwiftUI concepts demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Self-Review Notes

- Spec coverage: Task 1 creates the standalone project; Task 2 implements testable concept and experiment metadata; Task 3 implements the single-screen SwiftUI relationship map and four experiments; Task 4 adds README, XcodeBuildMCP config, XcodeGen output, and final simulator validation.
- Placeholder scan: no task uses unfinished-work markers; all code-producing steps include concrete file contents.
- Type consistency: `ConceptNode`, `ConceptRelationship`, `Experiment`, `DemoShapeKind`, `DemoShapeStyleKind`, `DemoColorKind`, and `StrokeMode` are defined in Task 2 and consumed by Task 3 with matching names.
