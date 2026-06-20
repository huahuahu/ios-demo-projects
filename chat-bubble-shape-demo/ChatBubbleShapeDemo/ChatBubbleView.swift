import SwiftUI

struct ChatBubbleView: View {
    let message: String
    let style: ChatBubbleStyle
    let font: Font

    init(message: String, style: ChatBubbleStyle, font: Font = .body) {
        self.message = message
        self.style = style
        self.font = font
    }

    var body: some View {
        Text(message)
            .font(font)
            .foregroundStyle(Color(red: 0.12, green: 0.11, blue: 0.18))
            .lineSpacing(5)
            .padding(.leading, style.tailWidth + 20)
            .padding(.trailing, 26)
            .padding(.vertical, 24)
            .background {
                bubbleShape
                    .fill(style.fill)
                    .shadow(
                        color: style.shadowColor,
                        radius: style.shadowRadius,
                        x: style.shadowX,
                        y: style.shadowY
                    )
            }
            .overlay {
                bubbleShape
                    .stroke(style.stroke, lineWidth: style.strokeWidth)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(message)
    }

    private var bubbleShape: ChatBubbleShape {
        ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )
    }
}

#Preview {
    ChatBubbleView(
        message: BubbleSample.hero.message,
        style: .reference,
        font: .title2
    )
    .padding()
}
