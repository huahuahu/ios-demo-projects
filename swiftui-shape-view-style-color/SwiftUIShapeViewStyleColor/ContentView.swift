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
