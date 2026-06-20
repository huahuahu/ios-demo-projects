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
