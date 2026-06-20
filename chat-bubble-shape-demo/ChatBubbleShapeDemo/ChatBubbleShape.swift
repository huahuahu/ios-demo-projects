import SwiftUI

struct ChatBubbleShape: Shape {
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailInset: CGFloat

    struct Geometry {
        let body: CGRect
        let safeRadius: CGFloat
    }

    func computeGeometry(in rect: CGRect) -> Geometry {
        let minimumSide = max(0, min(rect.width, rect.height))
        let safeTailWidth = clamp(tailWidth, lower: 0, upper: rect.width * 0.35)
        let safeTailHeight = clamp(tailHeight, lower: 0, upper: rect.height * 0.45)
        let safeTailInset = clamp(tailInset, lower: 0, upper: rect.height * 0.35)
        let initialSafeRadius = clamp(cornerRadius, lower: 0, upper: minimumSide * 0.5)

        let body = CGRect(
            x: rect.minX + safeTailWidth,
            y: rect.minY,
            width: max(0, rect.width - safeTailWidth - 0.0001),
            height: rect.height - safeTailHeight * 0.15
        )

        let safeRadius = clamp(initialSafeRadius, lower: 0, upper: min(body.width / 2.0, body.height / 2.0))

        return Geometry(body: body, safeRadius: safeRadius)
    }

    func path(in rect: CGRect) -> Path {
        let minimumSide = max(0, min(rect.width, rect.height))
        let safeTailWidth = clamp(tailWidth, lower: 0, upper: rect.width * 0.35)
        let safeTailHeight = clamp(tailHeight, lower: 0, upper: rect.height * 0.45)
        let safeTailInset = clamp(tailInset, lower: 0, upper: rect.height * 0.35)
        let initialSafeRadius = clamp(cornerRadius, lower: 0, upper: minimumSide * 0.5)

        let body = CGRect(
            x: rect.minX + safeTailWidth,
            y: rect.minY,
            width: max(0, rect.width - safeTailWidth - 0.0001),
            height: rect.height - safeTailHeight * 0.15
        )

        let safeRadius = clamp(initialSafeRadius, lower: 0, upper: min(body.width / 2.0, body.height / 2.0))

        let tailTip = CGPoint(
            x: rect.minX + safeTailWidth * 0.12,
            y: min(rect.maxY - 0.0001, body.maxY + safeTailHeight * 0.55)
        )
        let tailTop = CGPoint(
            x: body.minX + safeRadius * 0.55,
            y: max(body.minY + safeRadius, body.maxY - safeTailInset - safeTailHeight)
        )
        let tailJoin = CGPoint(
            x: body.minX + safeRadius * 0.35,
            y: body.maxY - safeTailInset
        )

        var path = Path()
        path.move(to: CGPoint(x: body.minX + safeRadius, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - safeRadius, y: body.minY))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX, y: body.minY + safeRadius),
            control: CGPoint(x: body.maxX, y: body.minY)
        )
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX - safeRadius, y: body.maxY),
            control: CGPoint(x: body.maxX, y: body.maxY)
        )
        path.addLine(to: tailJoin)
        path.addQuadCurve(
            to: tailTip,
            control: CGPoint(x: body.minX + safeTailWidth * 0.15, y: body.maxY + safeTailHeight * 0.15)
        )
        path.addQuadCurve(
            to: tailTop,
            control: CGPoint(x: body.minX - safeTailWidth * 0.15, y: body.maxY - safeTailInset)
        )
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: body.minX + safeRadius, y: body.minY),
            control: CGPoint(x: body.minX, y: body.minY)
        )
        path.closeSubpath()
        return path
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}
