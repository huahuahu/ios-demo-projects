import Foundation

struct Story: Identifiable, Hashable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbolName: String
    let paletteIndex: Int
    let media: Media

    enum Media: Hashable, Sendable {
        case artwork
        case loopingVideo(resource: String, fileExtension: String)
    }

    static let samples: [Story] = [
        Story(
            id: "city-after-rain",
            eyebrow: "今日精选",
            title: "雨后的城市，会发光",
            subtitle: "沿着熟悉的街道，重新发现被忽略的颜色。",
            symbolName: "cloud.sun.fill",
            paletteIndex: 0,
            media: .loopingVideo(resource: "story-motion", fileExtension: "mp4")
        ),
        Story(
            id: "slow-breakfast",
            eyebrow: "生活方式",
            title: "给早餐多十分钟",
            subtitle: "六种简单做法，让普通清晨变得值得期待。",
            symbolName: "cup.and.saucer.fill",
            paletteIndex: 1,
            media: .artwork
        ),
        Story(
            id: "weekend-trail",
            eyebrow: "周末出发",
            title: "走进风经过的山谷",
            subtitle: "一条适合初学者的轻徒步路线。",
            symbolName: "mountain.2.fill",
            paletteIndex: 2,
            media: .artwork
        ),
        Story(
            id: "night-reading",
            eyebrow: "编辑推荐",
            title: "今晚，读一点遥远的故事",
            subtitle: "把屏幕调暗，让文字带你去另一座岛。",
            symbolName: "book.closed.fill",
            paletteIndex: 3,
            media: .artwork
        ),
        Story(
            id: "small-garden",
            eyebrow: "动手创造",
            title: "窗边的一平方米花园",
            subtitle: "从第一盆香草开始，建立自己的绿色角落。",
            symbolName: "leaf.fill",
            paletteIndex: 4,
            media: .artwork
        ),
        Story(
            id: "listen-to-stars",
            eyebrow: "灵感时刻",
            title: "听见星星落下的声音",
            subtitle: "用一晚时间，认识夏季夜空里最亮的朋友。",
            symbolName: "sparkles",
            paletteIndex: 5,
            media: .artwork
        )
    ]
}
