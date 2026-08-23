import Foundation

struct StoryDetailSection: Identifiable, Sendable {
    let id: Int
    let title: String
    let body: String

    static let samples: [StoryDetailSection] = [
        StoryDetailSection(id: 1, title: "从熟悉的地方开始", body: "真正有趣的旅程，不一定从远方开始。试着放慢脚步，观察每天经过的路口、窗台与树影。光线改变时，同一个地方也会讲出完全不同的故事。"),
        StoryDetailSection(id: 2, title: "留意微小的线索", body: "一块褪色的招牌、一阵刚停的雨、咖啡店门口的音乐，都可能成为记忆的入口。把这些细节记录下来，你会发现生活从来不缺少素材。"),
        StoryDetailSection(id: 3, title: "让颜色带路", body: "选择一种今天最吸引你的颜色，然后在城市里寻找它。可能是车窗上的蓝，也可能是夕阳映在墙面的橙。颜色会把原本无关的片段连接起来。"),
        StoryDetailSection(id: 4, title: "给偶然留一点空间", body: "不要把路线安排得太满。转进一条没走过的小路，或者在下一个街角多停留几分钟。那些没有计划的时刻，常常最值得记住。"),
        StoryDetailSection(id: 5, title: "用自己的节奏记录", body: "照片、文字、声音都只是工具。选择最自然的方式，不必追求完整。几个真实的片段，往往比一份完美的清单更能保留当时的感受。"),
        StoryDetailSection(id: 6, title: "带着新眼光回家", body: "当你重新回到熟悉的房间，旅程并没有结束。整理今天发现的细节，挑出一个最喜欢的瞬间，并让它成为下一次出发的起点。")
    ]
}
