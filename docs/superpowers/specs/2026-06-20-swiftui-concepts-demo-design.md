# SwiftUI Shape/View/Style/Color Demo Design

## Goal

Create a focused iOS demo project that explains how SwiftUI `Shape`, `View`, `Style` / `ShapeStyle`, and `Color` relate to each other. The demo should be useful as a blog companion: readers should understand the concept hierarchy from the first screen, then interact with small examples that make the relationship concrete.

## Project Shape

- Directory: `swiftui-shape-view-style-color/`
- App and scheme: `SwiftUIShapeViewStyleColor`
- Bundle prefix: `com.huahuahu.demo`
- Tooling: XcodeGen with the repository's standard generated `project.yml` and `.xcodebuildmcp/config.yaml`
- Minimum platform: iOS 26.0, Swift 6.0

The project follows the repository's standalone demo pattern:

```text
swiftui-shape-view-style-color/
  README.md
  project.yml
  .xcodebuildmcp/config.yaml
  SwiftUIShapeViewStyleColor/
  SwiftUIShapeViewStyleColorTests/
```

## User Experience

The first screen is a compact teaching surface:

1. A relationship map with four concept cards:
   - `Shape`: describes geometry, such as `Circle`, `RoundedRectangle`, or a custom shape.
   - `View`: the rendered node SwiftUI can place in a hierarchy.
   - `Style` / `ShapeStyle`: defines how a shape is filled, stroked, or otherwise painted.
   - `Color`: a concrete color value that can also act as a `ShapeStyle`.
2. A segmented picker switches between three experiments:
   - `Shape becomes View`: shows that a `Shape` becomes visible when used as a `View` and modified with `fill`, `stroke`, or layout modifiers.
   - `Style paints Shape`: switches fill and stroke styles to show that geometry and appearance are separate decisions.
   - `Color as ShapeStyle`: demonstrates `Color` as a simple `ShapeStyle`, alongside gradients or materials if useful.

The demo should avoid deep navigation. It should be readable from one screen and keep the topic visible while users interact.

## Architecture

Use small SwiftUI components with explicit boundaries:

- `ContentView`: owns high-level layout and the small amount of selection state.
- `RelationshipDiagram`: renders the concept map.
- `ConceptCard`: renders one concept and its short explanation.
- `ExperimentPicker`: selects the active experiment.
- `ShapeBecomesViewExperiment`, `StylePaintsShapeExperiment`, and `ColorAsShapeStyleExperiment`: each owns one focused demonstration.
- `ConceptNode` and `Experiment`: pure Swift models used by both UI and tests.

State is limited to the current experiment, selected shape, selected style, and selected color. These values are enums or simple value types, so invalid picker states are not representable.

## Data Flow

User selections update local SwiftUI state in `ContentView` or the current experiment view. SwiftUI recomputes the body and passes selected values into shape/style rendering helpers. There is no router, persistence, networking, or asynchronous work.

The concept map and experiment metadata come from static model data. This keeps the educational copy testable and makes the key relationships easy to inspect without reading the view hierarchy.

## Error Handling

The demo has no external input or recoverable runtime failures. Error avoidance comes from type-safe enums for experiments, shapes, and styles. The UI should not rely on string matching for control flow.

## Testing

Use Swift Testing in `SwiftUIShapeViewStyleColorTests` for focused checks:

- The concept nodes appear in the intended teaching order.
- Each concept has a non-empty explanation.
- Each experiment has a title, summary, and stable identity.
- The expected relationship edges are present: `Shape -> View`, `Style -> Shape`, and `Color -> ShapeStyle`.

UI snapshot testing is out of scope for this demo.

## Validation

After implementation:

1. Run `xcodegen generate` in the demo directory.
2. Use XcodeBuildMCP defaults for the generated project.
3. Run simulator tests with XcodeBuildMCP `test_sim`.

## Out of Scope

- A full SwiftUI reference guide.
- Deep navigation or multiple app screens.
- Custom drawing performance comparisons.
- Compatibility work below the repository's current iOS 26 demo baseline.
