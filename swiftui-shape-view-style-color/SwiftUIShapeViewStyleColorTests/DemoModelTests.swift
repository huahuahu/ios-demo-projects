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
