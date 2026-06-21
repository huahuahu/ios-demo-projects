# Scrollable Lifecycle Logs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both UIKit updateProperties demo tabs vertically scrollable and emit lifecycle callback records to the unified logging system so Simulator logs can show which callbacks ran.

**Architecture:** Wrap each tab's vertical stack in a `UIScrollView` with a content layout guide and frame layout guide. Add `Logger` output inside `LifecycleEventRecorder.record` so the existing on-screen recorder and system log stream share the same event source.

**Tech Stack:** UIKit, Swift 6.0, iOS 26.0, os.Logger, XcodeBuildMCP.

## Global Constraints

- Change only `uikit-update-properties-demo/`.
- Keep the existing UIKit demo project shape and XcodeGen project.
- Do not add third-party dependencies.
- Keep lifecycle teaching semantics: per-method observation tracking dependencies are independent.
- Logs must include callback name, sequence number, and note.
- Validate with XcodeBuildMCP `test_sim`; build/run when possible.

---

## File Structure

- Modify `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`: import `OSLog`, add a static `Logger`, and log every recorded event.
- Modify `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift`: wrap `rootStack` in `UIScrollView`.
- Modify `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`: wrap `rootStack` in `UIScrollView`.

---

### Task 1: Add scroll containers and lifecycle logger

**Files:**
- Modify: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`
- Modify: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift`
- Modify: `uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`

**Interfaces:**
- Consumes: `LifecycleEventRecorder.record(_ callback: LifecycleCallback, note: String) -> Void`
- Produces: system log entries in category `LifecycleEventRecorder`

- [ ] **Step 1: Update recorder logging**

Change `LifecycleEventRecorder.swift` to:

```swift
import Foundation
import OSLog

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
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.huahuahu.demo.UIKitUpdatePropertiesDemo",
        category: "LifecycleEventRecorder"
    )

    private(set) var events: [LifecycleEvent] = []

    func record(_ callback: LifecycleCallback, note: String) {
        let event = LifecycleEvent(
            sequence: events.count + 1,
            callback: callback,
            note: note
        )
        events.append(event)
        Self.logger.info("#\(event.sequence, privacy: .public) \(event.callback.rawValue, privacy: .public) - \(event.note, privacy: .public)")
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

- [ ] **Step 2: Make UIView tab scrollable**

In `UIViewExperimentViewController.configure()`, create a `UIScrollView`, add `rootStack` to `scrollView.contentLayoutGuide`, pin the scroll view to `view.safeAreaLayoutGuide`, and constrain `rootStack.widthAnchor` to `scrollView.frameLayoutGuide.widthAnchor`.

- [ ] **Step 3: Make UIViewController tab scrollable**

Apply the same scroll view pattern in `UIViewControllerExperimentViewController.configure()`.

- [ ] **Step 4: Run tests**

Use XcodeBuildMCP `test_sim`.

Expected: 9 tests pass.

- [ ] **Step 5: Build and run**

Use XcodeBuildMCP `build_run_sim`.

Expected: app builds and launches.

- [ ] **Step 6: Commit**

```bash
git add uikit-update-properties-demo/UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewExperimentViewController.swift uikit-update-properties-demo/UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift docs/superpowers/plans/2026-06-21-scrollable-lifecycle-logs.md
git commit -m "feat: add scrollable lifecycle logging" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Self-Review

- Spec coverage: The plan covers scrollable tabs and lifecycle system logs.
- Placeholder scan: No unresolved placeholder markers.
- Type consistency: The recorder API remains unchanged.
