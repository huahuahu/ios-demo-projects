import SwiftUI

struct FontSample: Identifiable, Equatable {
    let id: String
    let role: String
    let pointSize: Double
    let weight: Font.Weight
    let textStyle: Font.TextStyle
    let sampleText: String

    var font: Font {
        .system(size: pointSize, weight: weight)
    }
}

extension FontSample {
    static let defaultSamples: [FontSample] = [
        FontSample(
            id: "caption",
            role: "Caption",
            pointSize: 12,
            weight: .regular,
            textStyle: .caption,
            sampleText: "辅助信息、时间、状态标签"
        ),
        FontSample(
            id: "body",
            role: "Body",
            pointSize: 17,
            weight: .regular,
            textStyle: .body,
            sampleText: "正文内容需要在长时间阅读中保持舒适。"
        ),
        FontSample(
            id: "headline",
            role: "Headline",
            pointSize: 20,
            weight: .semibold,
            textStyle: .headline,
            sampleText: "列表标题或卡片标题"
        ),
        FontSample(
            id: "title",
            role: "Title",
            pointSize: 28,
            weight: .bold,
            textStyle: .title,
            sampleText: "页面标题"
        ),
        FontSample(
            id: "large-title",
            role: "Large Title",
            pointSize: 34,
            weight: .bold,
            textStyle: .largeTitle,
            sampleText: "主视觉标题"
        )
    ]
}

