import SwiftUI

struct ChatBubbleStyle: Equatable {
    let fill: Color
    let stroke: Color
    let strokeWidth: CGFloat
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailInset: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
    let textColor: Color
}

extension ChatBubbleStyle {
    static let reference = ChatBubbleStyle(
        fill: Color(red: 0.82, green: 0.80, blue: 1.0),
        stroke: Color(red: 0.54, green: 0.43, blue: 0.96),
        strokeWidth: 8,
        cornerRadius: 38,
        tailWidth: 28,
        tailHeight: 26,
        tailInset: 16,
        shadowColor: Color.black.opacity(0.26),
        shadowRadius: 8,
        shadowX: 0,
        shadowY: 5,
        textColor: Color(red: 0.12, green: 0.11, blue: 0.18)
    )

    static let soft = ChatBubbleStyle(
        fill: Color(red: 0.88, green: 0.94, blue: 1.0),
        stroke: Color(red: 0.52, green: 0.68, blue: 0.95),
        strokeWidth: 4,
        cornerRadius: 28,
        tailWidth: 22,
        tailHeight: 20,
        tailInset: 12,
        shadowColor: Color.black.opacity(0.14),
        shadowRadius: 5,
        shadowX: 0,
        shadowY: 3,
        textColor: Color(red: 0.12, green: 0.11, blue: 0.18)
    )

    static let boldOutline = ChatBubbleStyle(
        fill: Color(red: 0.91, green: 0.86, blue: 1.0),
        stroke: Color(red: 0.43, green: 0.28, blue: 0.92),
        strokeWidth: 10,
        cornerRadius: 34,
        tailWidth: 30,
        tailHeight: 24,
        tailInset: 18,
        shadowColor: Color.black.opacity(0.22),
        shadowRadius: 7,
        shadowX: 0,
        shadowY: 4,
        textColor: Color(red: 0.12, green: 0.11, blue: 0.18)
    )

    static let compactTail = ChatBubbleStyle(
        fill: Color(red: 0.95, green: 0.92, blue: 1.0),
        stroke: Color(red: 0.62, green: 0.50, blue: 0.98),
        strokeWidth: 5,
        cornerRadius: 24,
        tailWidth: 16,
        tailHeight: 14,
        tailInset: 10,
        shadowColor: Color.black.opacity(0.16),
        shadowRadius: 4,
        shadowX: 0,
        shadowY: 3,
        textColor: Color(red: 0.12, green: 0.11, blue: 0.18)
    )
}
