import SwiftUI

struct ChatBubbleShape: Shape {
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailInset: CGFloat

    struct Geometry {
        let body: CGRect
        let safeRadius: CGFloat
        let safeTailWidth: CGFloat
        let safeTailHeight: CGFloat
        let safeTailInset: CGFloat
        let tailTip: CGPoint
        let tailTop: CGPoint
        let tailJoin: CGPoint
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
            height: rect.height - safeTailHeight * 0.75
        )

        let safeRadius = clamp(initialSafeRadius, lower: 0, upper: min(body.width / 2.0, body.height / 2.0))
        let tailTip = CGPoint(
            x: max(rect.minX, body.minX - safeTailWidth * 0.55),
            y: rect.maxY - 0.0001
        )
        let tailTop = CGPoint(
            x: body.minX,
            y: max(body.minY + safeRadius, body.maxY - max(safeTailInset, safeTailHeight * 0.75))
        )
        let tailJoin = CGPoint(
            x: body.minX + safeTailWidth * 0.55,
            y: body.maxY
        )

        return Geometry(
            body: body,
            safeRadius: safeRadius,
            safeTailWidth: safeTailWidth,
            safeTailHeight: safeTailHeight,
            safeTailInset: safeTailInset,
            tailTip: tailTip,
            tailTop: tailTop,
            tailJoin: tailJoin
        )
    }

    func path(in rect: CGRect) -> Path {
        let geometry = computeGeometry(in: rect)

        var path = Path()
        path.move(to: CGPoint(x: geometry.body.minX + geometry.safeRadius, y: geometry.body.minY))
        path.addLine(to: CGPoint(x: geometry.body.maxX - geometry.safeRadius, y: geometry.body.minY))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.maxX, y: geometry.body.minY + geometry.safeRadius),
            control: CGPoint(x: geometry.body.maxX, y: geometry.body.minY)
        )
        path.addLine(to: CGPoint(x: geometry.body.maxX, y: geometry.body.maxY - geometry.safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.maxX - geometry.safeRadius, y: geometry.body.maxY),
            control: CGPoint(x: geometry.body.maxX, y: geometry.body.maxY)
        )
        path.addLine(to: geometry.tailJoin)
        path.addCurve(
            to: geometry.tailTip,
            control1: CGPoint(x: geometry.body.minX + geometry.safeTailWidth * 0.2, y: geometry.body.maxY),
            control2: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.35, y: geometry.body.maxY + geometry.safeTailHeight * 0.65)
        )
        path.addCurve(
            to: geometry.tailTop,
            control1: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.35, y: geometry.body.maxY + geometry.safeTailHeight * 0.25),
            control2: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.15, y: geometry.body.maxY - geometry.safeTailHeight * 0.35)
        )
        path.addLine(to: CGPoint(x: geometry.body.minX, y: geometry.body.minY + geometry.safeRadius))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.minX + geometry.safeRadius, y: geometry.body.minY),
            control: CGPoint(x: geometry.body.minX, y: geometry.body.minY)
        )
        path.closeSubpath()
        return path
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}
