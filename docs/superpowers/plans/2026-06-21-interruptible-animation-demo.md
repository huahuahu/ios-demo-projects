# Interruptible Animation Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `interruptible-animation-demo/`, a focused iOS demo that explains interruptible/resumable animations through a draggable card in UIKit and a SwiftUI comparison tab.

**Architecture:** Use a SwiftUI app shell with two tabs. The UIKit tab bridges to a `UIViewController` that demonstrates explicit `UIViewPropertyAnimator` control; the SwiftUI tab mirrors the interaction through state-driven animation. Shared deterministic math lives in `AnimationProgressModel` so behavior can be tested without relying on animation timing.

**Tech Stack:** Swift 6.0, iOS 26.0, SwiftUI, UIKit, `UIViewPropertyAnimator`, XcodeGen, XcodeBuildMCP.

## Global Constraints

- Demo directory: `interruptible-animation-demo/`
- App and scheme name: `InterruptibleAnimationDemo`
- Bundle identifier: `com.huahuahu.demo.InterruptibleAnimationDemo`
- Bundle id prefix: `com.huahuahu.demo`
- Deployment target: iOS `26.0`
- Swift version: `6.0`
- Development team: empty string for local simulator demos
- Use XcodeGen for the project file
- Create a dedicated simulator named `InterruptibleAnimationDemo iPhone 17 Pro Max`
- Use `com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max` and `com.apple.CoreSimulator.SimRuntime.iOS-26-5` when creating the simulator on this machine
- Validate with XcodeBuildMCP `test_sim`
- Keep the demo local-only: no network, persistence, accounts, or external services

---

## File Structure

- Create `interruptible-animation-demo/README.md`: blog-friendly overview, setup, run/test instructions, and key files.
- Create `interruptible-animation-demo/project.yml`: XcodeGen project generated from `.agents/skills/ios-demo-project-creator/templates/project.yml`.
- Create `interruptible-animation-demo/.xcodebuildmcp/config.yaml`: XcodeBuildMCP defaults generated after the dedicated simulator exists.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleAnimationDemoApp.swift`: SwiftUI app entry point.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift`: two-tab shell for UIKit and SwiftUI demos.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationSnapState.swift`: shared collapsed/expanded state.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationProgressModel.swift`: shared progress and snap-decision math.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/UIKitInterruptibleDemoView.swift`: `UIViewControllerRepresentable` bridge.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleUIKitViewController.swift`: primary UIKit `UIViewPropertyAnimator` demo.
- Create `interruptible-animation-demo/InterruptibleAnimationDemo/SwiftUIInterruptibleDemoView.swift`: SwiftUI state-driven comparison.
- Create `interruptible-animation-demo/InterruptibleAnimationDemoTests/AnimationProgressModelTests.swift`: focused tests for deterministic logic.

---

### Task 1: Scaffold the demo project and shared model

**Files:**
- Create: `interruptible-animation-demo/README.md`
- Create: `interruptible-animation-demo/project.yml`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleAnimationDemoApp.swift`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationSnapState.swift`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationProgressModel.swift`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemoTests/AnimationProgressModelTests.swift`

**Interfaces:**
- Produces: `enum AnimationSnapState: CaseIterable, Equatable`
- Produces: `var AnimationSnapState.title: String`
- Produces: `var AnimationSnapState.targetProgress: CGFloat`
- Produces: `struct AnimationProgressModel`
- Produces: `static func AnimationProgressModel.clampedProgress(_ progress: CGFloat) -> CGFloat`
- Produces: `static func AnimationProgressModel.progress(start: AnimationSnapState, translation: CGFloat, travelDistance: CGFloat) -> CGFloat`
- Produces: `static func AnimationProgressModel.snapState(progress: CGFloat, velocity: CGFloat) -> AnimationSnapState`
- Produces: `struct ContentView: View`
- Produces: `@main struct InterruptibleAnimationDemoApp: App`

- [ ] **Step 1: Create directories**

Run:

```bash
mkdir -p interruptible-animation-demo/InterruptibleAnimationDemo interruptible-animation-demo/InterruptibleAnimationDemoTests
```

Expected: command exits with status `0`.

- [ ] **Step 2: Create the XcodeGen project file**

Create `interruptible-animation-demo/project.yml` with:

```yaml
name: "InterruptibleAnimationDemo"
options:
  bundleIdPrefix: "com.huahuahu.demo"
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""
targets:
  "InterruptibleAnimationDemo":
    type: application
    platform: iOS
    sources:
      - "InterruptibleAnimationDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.InterruptibleAnimationDemo"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
    scheme:
      testTargets:
        - "InterruptibleAnimationDemoTests"
  "InterruptibleAnimationDemoTests":
    type: bundle.unit-test
    platform: iOS
    sources:
      - "InterruptibleAnimationDemoTests"
    dependencies:
      - target: "InterruptibleAnimationDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.InterruptibleAnimationDemoTests"
```

- [ ] **Step 3: Write failing model tests**

Create `interruptible-animation-demo/InterruptibleAnimationDemoTests/AnimationProgressModelTests.swift` with:

```swift
import Testing
import CoreGraphics
@testable import InterruptibleAnimationDemo

struct AnimationProgressModelTests {
    @Test func clampedProgressStaysInsideUnitRange() {
        #expect(AnimationProgressModel.clampedProgress(-0.25) == 0)
        #expect(AnimationProgressModel.clampedProgress(0.4) == 0.4)
        #expect(AnimationProgressModel.clampedProgress(1.25) == 1)
    }

    @Test func collapsedDragUpIncreasesProgress() {
        let progress = AnimationProgressModel.progress(
            start: .collapsed,
            translation: -120,
            travelDistance: 240
        )

        #expect(progress == 0.5)
    }

    @Test func expandedDragDownDecreasesProgress() {
        let progress = AnimationProgressModel.progress(
            start: .expanded,
            translation: 60,
            travelDistance: 240
        )

        #expect(progress == 0.75)
    }

    @Test func invalidTravelDistanceKeepsStartStateProgress() {
        #expect(AnimationProgressModel.progress(start: .collapsed, translation: -120, travelDistance: 0) == 0)
        #expect(AnimationProgressModel.progress(start: .expanded, translation: 120, travelDistance: -1) == 1)
    }

    @Test func snapStateUsesProgressThreshold() {
        #expect(AnimationProgressModel.snapState(progress: 0.49, velocity: 0) == .collapsed)
        #expect(AnimationProgressModel.snapState(progress: 0.5, velocity: 0) == .expanded)
    }

    @Test func snapStateUsesVelocityWhenIntentIsClear() {
        #expect(AnimationProgressModel.snapState(progress: 0.2, velocity: -900) == .expanded)
        #expect(AnimationProgressModel.snapState(progress: 0.8, velocity: 900) == .collapsed)
    }
}
```

- [ ] **Step 4: Run tests and verify the model does not exist yet**

Run:

```bash
cd interruptible-animation-demo && xcodegen generate && xcodebuild test -project InterruptibleAnimationDemo.xcodeproj -scheme InterruptibleAnimationDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: FAIL with compiler errors that `AnimationProgressModel` and `AnimationSnapState` are not found.

- [ ] **Step 5: Implement `AnimationSnapState`**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationSnapState.swift` with:

```swift
import CoreGraphics

enum AnimationSnapState: CaseIterable, Equatable {
    case collapsed
    case expanded

    var title: String {
        switch self {
        case .collapsed:
            "Collapsed"
        case .expanded:
            "Expanded"
        }
    }

    var targetProgress: CGFloat {
        switch self {
        case .collapsed:
            0
        case .expanded:
            1
        }
    }
}
```

- [ ] **Step 6: Implement `AnimationProgressModel`**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/AnimationProgressModel.swift` with:

```swift
import CoreGraphics

struct AnimationProgressModel {
    private static let snapVelocityThreshold: CGFloat = 700

    static func clampedProgress(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }

    static func progress(
        start: AnimationSnapState,
        translation: CGFloat,
        travelDistance: CGFloat
    ) -> CGFloat {
        guard travelDistance > 0 else {
            return start.targetProgress
        }

        let delta = -translation / travelDistance
        return clampedProgress(start.targetProgress + delta)
    }

    static func snapState(progress: CGFloat, velocity: CGFloat) -> AnimationSnapState {
        if velocity <= -snapVelocityThreshold {
            return .expanded
        }

        if velocity >= snapVelocityThreshold {
            return .collapsed
        }

        return clampedProgress(progress) >= 0.5 ? .expanded : .collapsed
    }
}
```

- [ ] **Step 7: Add the app entry point**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleAnimationDemoApp.swift` with:

```swift
import SwiftUI

@main
struct InterruptibleAnimationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 8: Add a temporary compiling shell**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("UIKit demo will be added in Task 2.")
                .tabItem {
                    Label("UIKit", systemImage: "hand.draw")
                }

            Text("SwiftUI comparison will be added in Task 3.")
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
        }
    }
}
```

- [ ] **Step 9: Add the README**

Create `interruptible-animation-demo/README.md` with:

```markdown
# Interruptible Animation Demo

A focused iOS demo for explaining interruptible and resumable animations.

## Blog Topic

This demo supports a blog post about UIKit `UIViewPropertyAnimator`, interactive animation progress, and how SwiftUI state-driven animation compares.

## What It Shows

- A UIKit card that can be dragged, paused, reversed, and continued with `UIViewPropertyAnimator`.
- A SwiftUI comparison that shows how changing animated state can interrupt an in-flight animation.
- Shared progress math for deciding whether the card should finish expanded or collapse back.

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
open InterruptibleAnimationDemo.xcodeproj
```

Then run the `InterruptibleAnimationDemo` scheme on an iOS Simulator.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `InterruptibleAnimationDemo` scheme.

## Key Files

- `AnimationProgressModel.swift` contains the deterministic drag/progress/snap logic.
- `InterruptibleUIKitViewController.swift` demonstrates `UIViewPropertyAnimator.pauseAnimation()`, `fractionComplete`, and `continueAnimation(...)`.
- `UIKitInterruptibleDemoView.swift` bridges the UIKit controller into the SwiftUI shell.
- `SwiftUIInterruptibleDemoView.swift` shows the state-driven SwiftUI comparison.
- `ContentView.swift` presents the two demo tabs.
```

- [ ] **Step 10: Run tests and verify they pass**

Run:

```bash
cd interruptible-animation-demo && xcodebuild test -project InterruptibleAnimationDemo.xcodeproj -scheme InterruptibleAnimationDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: PASS for all `AnimationProgressModelTests`.

- [ ] **Step 11: Commit**

```bash
git add interruptible-animation-demo
git commit -m "feat: scaffold interruptible animation demo"
```

---

### Task 2: Add the UIKit interruptible animation tab

**Files:**
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/UIKitInterruptibleDemoView.swift`
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleUIKitViewController.swift`
- Modify: `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift`

**Interfaces:**
- Consumes: `AnimationSnapState.targetProgress`
- Consumes: `AnimationProgressModel.progress(start:translation:travelDistance:) -> CGFloat`
- Consumes: `AnimationProgressModel.snapState(progress:velocity:) -> AnimationSnapState`
- Produces: `struct UIKitInterruptibleDemoView: UIViewControllerRepresentable`
- Produces: `final class InterruptibleUIKitViewController: UIViewController`

- [ ] **Step 1: Add the UIKit bridge**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/UIKitInterruptibleDemoView.swift` with:

```swift
import SwiftUI
import UIKit

struct UIKitInterruptibleDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InterruptibleUIKitViewController {
        InterruptibleUIKitViewController()
    }

    func updateUIViewController(_ uiViewController: InterruptibleUIKitViewController, context: Context) {
    }
}
```

- [ ] **Step 2: Add the UIKit view controller**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleUIKitViewController.swift` with:

```swift
import UIKit

final class InterruptibleUIKitViewController: UIViewController {
    private let travelDistance: CGFloat = 260
    private var currentState: AnimationSnapState = .collapsed
    private var interactionStartState: AnimationSnapState = .collapsed
    private var animator: UIViewPropertyAnimator?

    private let titleLabel = UILabel()
    private let explanationLabel = UILabel()
    private let statusLabel = UILabel()
    private let trackView = UIView()
    private let cardView = UIView()
    private let cardTitleLabel = UILabel()
    private let cardBodyLabel = UILabel()
    private var cardCenterYConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLabels()
        configureCard()
        configureLayout()
        configureGesture()
        updateStatus(progress: currentState.targetProgress, phase: "Ready")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardCenterYConstraint?.constant = offset(for: currentState.targetProgress)
    }

    private func configureView() {
        view.backgroundColor = UIColor.systemGroupedBackground
    }

    private func configureLabels() {
        titleLabel.text = "UIKit: UIViewPropertyAnimator"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true

        explanationLabel.text = "Drag the card upward or downward. The pan gesture pauses the animator, writes into fractionComplete, then continues from the current progress on release."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.textColor = .secondaryLabel
        explanationLabel.numberOfLines = 0
        explanationLabel.adjustsFontForContentSizeCategory = true

        statusLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
    }

    private func configureCard() {
        trackView.backgroundColor = UIColor.secondarySystemGroupedBackground
        trackView.layer.cornerRadius = 28

        cardView.backgroundColor = UIColor.systemBlue
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowRadius = 14
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        cardTitleLabel.text = "Drag me"
        cardTitleLabel.font = .preferredFont(forTextStyle: .title3)
        cardTitleLabel.textColor = .white
        cardTitleLabel.adjustsFontForContentSizeCategory = true

        cardBodyLabel.text = "pauseAnimation → fractionComplete → continueAnimation"
        cardBodyLabel.font = .preferredFont(forTextStyle: .body)
        cardBodyLabel.textColor = .white.withAlphaComponent(0.86)
        cardBodyLabel.numberOfLines = 0
        cardBodyLabel.adjustsFontForContentSizeCategory = true
    }

    private func configureLayout() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, explanationLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 12

        let cardTextStack = UIStackView(arrangedSubviews: [cardTitleLabel, cardBodyLabel])
        cardTextStack.axis = .vertical
        cardTextStack.spacing = 8
        cardTextStack.isUserInteractionEnabled = false

        [textStack, trackView, cardView, cardTextStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(textStack)
        view.addSubview(trackView)
        trackView.addSubview(cardView)
        cardView.addSubview(cardTextStack)

        let cardCenterYConstraint = cardView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor, constant: offset(for: currentState.targetProgress))
        self.cardCenterYConstraint = cardCenterYConstraint

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            trackView.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 24),
            trackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            trackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            trackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            cardView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -24),
            cardView.heightAnchor.constraint(equalToConstant: 150),
            cardCenterYConstraint,

            cardTextStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            cardTextStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            cardTextStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    private func configureGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            interactionStartState = currentState
            animator?.stopAnimation(true)
            animator = nil
            makeAnimator(to: currentState == .collapsed ? .expanded : .collapsed).pauseAnimation()
            updateStatus(progress: currentState.targetProgress, phase: "Paused")

        case .changed:
            let translation = gesture.translation(in: trackView).y
            let progress = AnimationProgressModel.progress(
                start: interactionStartState,
                translation: translation,
                travelDistance: travelDistance
            )
            animator?.fractionComplete = progress
            cardCenterYConstraint?.constant = offset(for: progress)
            updateStatus(progress: progress, phase: "Scrubbing")

        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: trackView).y
            let progress = animator?.fractionComplete ?? currentState.targetProgress
            let targetState = AnimationProgressModel.snapState(progress: progress, velocity: velocity)
            continueAnimation(to: targetState, from: progress)

        default:
            break
        }
    }

    private func makeAnimator(to targetState: AnimationSnapState) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 0.65, dampingRatio: 0.82) {
            self.cardCenterYConstraint?.constant = self.offset(for: targetState.targetProgress)
            self.view.layoutIfNeeded()
        }
        self.animator = animator
        return animator
    }

    private func continueAnimation(to targetState: AnimationSnapState, from progress: CGFloat) {
        currentState = targetState
        let animator = makeAnimator(to: targetState)
        animator.fractionComplete = progress
        animator.addCompletion { [weak self] _ in
            self?.updateStatus(progress: targetState.targetProgress, phase: "Completed: \(targetState.title)")
        }
        updateStatus(progress: progress, phase: "Continuing to \(targetState.title)")
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }

    private func offset(for progress: CGFloat) -> CGFloat {
        let clampedProgress = AnimationProgressModel.clampedProgress(progress)
        return travelDistance * (0.5 - clampedProgress)
    }

    private func updateStatus(progress: CGFloat, phase: String) {
        let percent = Int((AnimationProgressModel.clampedProgress(progress) * 100).rounded())
        statusLabel.text = "\(phase)\nprogress: \(percent)%"
    }
}
```

- [ ] **Step 3: Wire the UIKit tab**

Replace `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UIKitInterruptibleDemoView()
                .ignoresSafeArea(edges: .bottom)
                .tabItem {
                    Label("UIKit", systemImage: "hand.draw")
                }

            Text("SwiftUI comparison will be added in Task 3.")
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
        }
    }
}
```

- [ ] **Step 4: Build the app**

Run:

```bash
cd interruptible-animation-demo && xcodebuild build -project InterruptibleAnimationDemo.xcodeproj -scheme InterruptibleAnimationDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift interruptible-animation-demo/InterruptibleAnimationDemo/UIKitInterruptibleDemoView.swift interruptible-animation-demo/InterruptibleAnimationDemo/InterruptibleUIKitViewController.swift
git commit -m "feat: add UIKit interruptible animation demo"
```

---

### Task 3: Add the SwiftUI comparison tab

**Files:**
- Create: `interruptible-animation-demo/InterruptibleAnimationDemo/SwiftUIInterruptibleDemoView.swift`
- Modify: `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift`

**Interfaces:**
- Consumes: `AnimationSnapState.targetProgress`
- Consumes: `AnimationProgressModel.progress(start:translation:travelDistance:) -> CGFloat`
- Consumes: `AnimationProgressModel.snapState(progress:velocity:) -> AnimationSnapState`
- Produces: `struct SwiftUIInterruptibleDemoView: View`

- [ ] **Step 1: Add the SwiftUI comparison view**

Create `interruptible-animation-demo/InterruptibleAnimationDemo/SwiftUIInterruptibleDemoView.swift` with:

```swift
import SwiftUI

struct SwiftUIInterruptibleDemoView: View {
    private let travelDistance: CGFloat = 260

    @State private var currentState: AnimationSnapState = .collapsed
    @State private var interactionStartState: AnimationSnapState = .collapsed
    @State private var interactiveProgress: CGFloat = AnimationSnapState.collapsed.targetProgress
    @State private var phase = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SwiftUI: state-driven interruption")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Drag the card. SwiftUI does not expose UIViewPropertyAnimator, but new state changes can interrupt an in-flight animation and retarget the card.")
                    .foregroundStyle(.secondary)

                Text("\(phase)\nprogress: \(Int((AnimationProgressModel.clampedProgress(interactiveProgress) * 100).rounded()))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemGroupedBackground))

                card
                    .offset(y: offset(for: interactiveProgress))
                    .gesture(cardDrag)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drag me")
                .font(.title3)
                .fontWeight(.semibold)

            Text("gesture state → target state → animated retarget")
                .font(.body)
                .opacity(0.86)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 150)
        .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 24)
    }

    private var cardDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if phase != "Scrubbing" {
                    interactionStartState = currentState
                }

                interactiveProgress = AnimationProgressModel.progress(
                    start: interactionStartState,
                    translation: value.translation.height,
                    travelDistance: travelDistance
                )
                phase = "Scrubbing"
            }
            .onEnded { value in
                let targetState = AnimationProgressModel.snapState(
                    progress: interactiveProgress,
                    velocity: value.velocity.height
                )
                currentState = targetState
                phase = "Animating to \(targetState.title)"
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    interactiveProgress = targetState.targetProgress
                }
            }
    }

    private func offset(for progress: CGFloat) -> CGFloat {
        let clampedProgress = AnimationProgressModel.clampedProgress(progress)
        return travelDistance * (0.5 - clampedProgress)
    }
}
```

- [ ] **Step 2: Wire the SwiftUI tab**

Replace `interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UIKitInterruptibleDemoView()
                .ignoresSafeArea(edges: .bottom)
                .tabItem {
                    Label("UIKit", systemImage: "hand.draw")
                }

            SwiftUIInterruptibleDemoView()
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
        }
    }
}
```

- [ ] **Step 3: Build the app**

Run:

```bash
cd interruptible-animation-demo && xcodebuild build -project InterruptibleAnimationDemo.xcodeproj -scheme InterruptibleAnimationDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add interruptible-animation-demo/InterruptibleAnimationDemo/ContentView.swift interruptible-animation-demo/InterruptibleAnimationDemo/SwiftUIInterruptibleDemoView.swift
git commit -m "feat: add SwiftUI interruptible animation comparison"
```

---

### Task 4: Add dedicated simulator config and validate with XcodeBuildMCP

**Files:**
- Create: `interruptible-animation-demo/.xcodebuildmcp/config.yaml`
- Modify: generated `interruptible-animation-demo/InterruptibleAnimationDemo.xcodeproj/`

**Interfaces:**
- Consumes: app/scheme name `InterruptibleAnimationDemo`
- Produces: dedicated simulator named `InterruptibleAnimationDemo iPhone 17 Pro Max`
- Produces: XcodeBuildMCP defaults for project, scheme, simulator name, and simulator UUID

- [ ] **Step 1: Regenerate the Xcode project**

Run:

```bash
cd interruptible-animation-demo && xcodegen generate
```

Expected: output includes `Project "InterruptibleAnimationDemo" generated.`

- [ ] **Step 2: Create the dedicated simulator**

Run:

```bash
xcrun simctl create "InterruptibleAnimationDemo iPhone 17 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
```

Expected: command prints one simulator UUID, for example `AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE`. Use the actual printed UUID in the next step.

- [ ] **Step 3: Write XcodeBuildMCP config**

Create `interruptible-animation-demo/.xcodebuildmcp/config.yaml`, replacing `AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE` with the UUID from Step 2:

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
  projectPath: InterruptibleAnimationDemo.xcodeproj
  scheme: InterruptibleAnimationDemo
  simulatorName: InterruptibleAnimationDemo iPhone 17 Pro Max
  simulatorId: AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE
```

- [ ] **Step 4: Set XcodeBuildMCP session defaults**

Use XcodeBuildMCP `session_set_defaults` with:

```text
projectPath: /Users/tigerguo/git/copilot-worktrees/learn projects/huahuahu-scaling-giggle/interruptible-animation-demo/InterruptibleAnimationDemo.xcodeproj
scheme: InterruptibleAnimationDemo
simulatorName: InterruptibleAnimationDemo iPhone 17 Pro Max
simulatorId: <UUID from Step 2>
simulatorPlatform: iOS Simulator
configuration: Debug
```

Expected: defaults show the new project, scheme, and dedicated simulator.

- [ ] **Step 5: Run tests with XcodeBuildMCP**

Use XcodeBuildMCP `test_sim`.

Expected: all `AnimationProgressModelTests` pass.

- [ ] **Step 6: Build and run with XcodeBuildMCP**

Use XcodeBuildMCP `build_run_sim`.

Expected: app builds, installs, and launches on `InterruptibleAnimationDemo iPhone 17 Pro Max`.

- [ ] **Step 7: Commit**

```bash
git add interruptible-animation-demo
git commit -m "chore: validate interruptible animation demo"
```

