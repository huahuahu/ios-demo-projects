# Chat Bubble Shape Demo Design

## Goal

Create a focused iOS demo project that shows how to build a parameterized chat bubble in SwiftUI, matching the attached reference style: a rounded lavender bubble with a purple outline, soft shadow, multiline text, and a left-bottom tail.

The demo is intended for a blog topic about implementing custom chat bubble shapes with SwiftUI `Shape` and `Path`.

## Project Shape

The new standalone demo directory will be:

```text
chat-bubble-shape-demo/
  README.md
  project.yml
  .xcodebuildmcp/
    config.yaml
  ChatBubbleShapeDemo/
  ChatBubbleShapeDemoTests/
```

The app and scheme name will be `ChatBubbleShapeDemo`. The bundle identifier will be `com.huahuahu.demo.ChatBubbleShapeDemo`. The project will use XcodeGen, Swift 6.0, iOS 26.0, and an empty development team for local simulator use.

## Architecture

The first screen will be a SwiftUI comparison page. It will lead with a large hero sample that closely resembles the reference image, then show a short list of variants using the same rendering component. The variants will demonstrate how corner radius, tail size, stroke width, fill color, and shadow affect the final bubble.

The drawing algorithm will live in a single reusable `ChatBubbleShape`. Views will pass in a style model rather than duplicating geometry logic. This keeps the demo small enough to inspect while still making the key technique easy to reuse.

## Components

### `ChatBubbleShape`

`ChatBubbleShape` will produce one `Path` that combines:

- a rounded rectangle body
- a left-bottom tail that blends into the body
- safe clamping for geometry values so extreme parameters do not create negative dimensions

The shape will focus on the silhouette only. Fill, stroke, text, and shadow will remain in the view layer.

### `ChatBubbleStyle`

`ChatBubbleStyle` will hold the visual parameters:

- fill color
- stroke color and width
- corner radius
- tail width, height, and vertical inset
- shadow color, radius, and offset

Preset styles will make the comparison page readable without introducing runtime controls.

### `BubbleSample`

`BubbleSample` will describe each rendered example with a title, short explanation, text, and `ChatBubbleStyle`. This separates demo data from layout code and gives the tests concrete behavior to verify.

### `ContentView`

`ContentView` will use a `ScrollView` with:

1. a hero bubble matching the reference mood
2. a compact comparison section with several variants
3. concise labels explaining what each variant changes

SwiftUI will handle multiline text wrapping and dynamic sizing.

## Data Flow

Static preset data will flow from `BubbleSample.presets` into `ContentView`. Each row passes its sample style into the reusable bubble view, which applies `ChatBubbleShape` for clipping/fill/stroke and overlays text content inside padding.

There is no network, persistence, or user-generated data. The demo remains deterministic and easy to test.

## Error Handling and Edge Cases

The only meaningful edge cases are invalid or extreme geometry values. The shape will clamp tail and radius values to safe ranges based on the drawing rect before constructing the path. Long text will rely on SwiftUI wrapping. Small preview sizes should still produce a valid bubble silhouette instead of an inverted or empty path.

## Testing

Tests will focus on logic that is stable and useful for a demo:

- preset data exists and includes the hero/reference sample
- style parameters stay within expected positive ranges
- `ChatBubbleShape` can produce a non-empty path for normal and small rects

The project will not include pixel snapshot tests because the goal is to demonstrate SwiftUI shape construction, not to lock down exact antialiasing or simulator rendering output.

## README Scope

The demo README will explain:

- what the demo shows
- the blog topic it supports
- expected Xcode/iOS versions
- how to run `xcodegen generate`
- how to open, run, and test the project
- the key files to inspect

## Validation Plan

After implementation, generate the Xcode project with `xcodegen generate`, configure `.xcodebuildmcp/config.yaml`, and use XcodeBuildMCP `test_sim` to verify the simulator test target.
