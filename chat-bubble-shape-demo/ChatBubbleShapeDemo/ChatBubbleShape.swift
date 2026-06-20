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
        let tailBase: CGPoint
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
            height: rect.height - safeTailHeight * 0.55
        )

        let safeRadius = clamp(initialSafeRadius, lower: 0, upper: min(body.width / 2.0, body.height / 2.0))
        let tailTip = CGPoint(
            x: max(rect.minX, body.minX - safeTailWidth * 0.58),
            y: min(rect.maxY - 0.0001, body.maxY + safeTailHeight * 0.62)
        )
        let tailTop = CGPoint(
            x: body.minX,
            y: max(body.minY + safeRadius, body.maxY - safeRadius * 0.48)
        )
        let tailBase = CGPoint(
            x: body.minX + safeTailWidth * 0.12,
            y: body.maxY + safeTailHeight * 0.24
        )
        let tailJoin = CGPoint(
            x: body.minX + min(safeRadius * 0.34, safeTailWidth * 0.84),
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
            tailBase: tailBase,
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
            to: geometry.tailBase,
            control1: CGPoint(x: geometry.body.minX + geometry.safeTailWidth * 0.16, y: geometry.body.maxY),
            control2: CGPoint(x: geometry.body.minX + geometry.safeTailWidth * 0.02, y: geometry.tailBase.y)
        )
        path.addCurve(
            to: geometry.tailTip,
            control1: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.18, y: geometry.tailBase.y),
            control2: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.50, y: geometry.body.maxY + geometry.safeTailHeight * 0.50)
        )
        path.addCurve(
            to: geometry.tailTop,
            control1: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.64, y: geometry.body.maxY + geometry.safeTailHeight * 0.26),
            control2: CGPoint(x: geometry.body.minX - geometry.safeTailWidth * 0.12, y: geometry.tailTop.y + geometry.safeTailHeight * 0.12)
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
