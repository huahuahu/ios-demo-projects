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
