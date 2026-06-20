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
            x: rect.minX,
            y: rect.minY,
            width: max(0, rect.width - 0.0001),
            height: rect.height - safeTailHeight * 1.1
        )

        let safeRadius = clamp(initialSafeRadius, lower: 0, upper: min(body.width / 2.0, body.height / 2.0))
        let svgScale = max(0.01, body.width / 540.0)
        func svgPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: body.minX + (x - 58.0) * svgScale,
                y: body.maxY + (y - 190.0) * svgScale
            )
        }
        let tailTip = svgPoint(74, 198)
        let tailTop = svgPoint(66, 176)
        let tailBase = svgPoint(91, 207)
        let tailJoin = svgPoint(128, 190)

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
        let svgScale = max(0.01, geometry.body.width / 540.0)
        func svgPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: geometry.body.minX + (x - 58.0) * svgScale,
                y: geometry.body.maxY + (y - 190.0) * svgScale
            )
        }

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
        path.addLine(to: svgPoint(128, 190))
        path.addCurve(
            to: svgPoint(91, 207),
            control1: svgPoint(113, 190),
            control2: svgPoint(102, 199)
        )
        path.addCurve(
            to: svgPoint(74, 198),
            control1: svgPoint(80, 215),
            control2: svgPoint(68, 209)
        )
        path.addCurve(
            to: svgPoint(66, 176),
            control1: svgPoint(80, 188),
            control2: svgPoint(75, 183)
        )
        path.addCurve(
            to: svgPoint(58, 158),
            control1: svgPoint(61, 174),
            control2: svgPoint(58, 166)
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
