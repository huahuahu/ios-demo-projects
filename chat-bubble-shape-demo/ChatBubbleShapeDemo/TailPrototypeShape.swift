import SwiftUI

struct TailPrototypeBubbleShape: Shape {
    struct Geometry {
        let body: CGRect
        let radius: CGFloat
        let tailUpperJoin: CGPoint
        let tailCapTop: CGPoint
        let tailCapBottom: CGPoint
        let tailLowerJoin: CGPoint
    }

    func computeGeometry(in rect: CGRect) -> Geometry {
        let tailHeight = rect.height * 0.24
        let body = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: max(0, rect.width - 0.0001),
            height: max(0, rect.height - tailHeight)
        )
        let radius = min(body.height * 0.36, body.width * 0.18)

        return Geometry(
            body: body,
            radius: radius,
            tailUpperJoin: CGPoint(x: body.minX + radius * 0.20, y: body.maxY - tailHeight * 0.12),
            tailCapTop: CGPoint(x: body.minX + radius * 0.26, y: body.maxY + tailHeight * 0.42),
            tailCapBottom: CGPoint(x: body.minX + radius * 0.46, y: body.maxY + tailHeight * 0.72),
            tailLowerJoin: CGPoint(x: body.minX + radius * 1.62, y: body.maxY)
        )
    }

    func path(in rect: CGRect) -> Path {
        let geometry = computeGeometry(in: rect)
        var path = Path()
        path.move(to: CGPoint(x: geometry.body.minX + geometry.radius, y: geometry.body.minY))
        path.addLine(to: CGPoint(x: geometry.body.maxX - geometry.radius, y: geometry.body.minY))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.maxX, y: geometry.body.minY + geometry.radius),
            control: CGPoint(x: geometry.body.maxX, y: geometry.body.minY)
        )
        path.addLine(to: CGPoint(x: geometry.body.maxX, y: geometry.body.maxY - geometry.radius))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.maxX - geometry.radius, y: geometry.body.maxY),
            control: CGPoint(x: geometry.body.maxX, y: geometry.body.maxY)
        )
        path.addLine(to: geometry.tailLowerJoin)
        path.addCurve(
            to: geometry.tailCapBottom,
            control1: CGPoint(x: geometry.body.minX + geometry.radius * 1.18, y: geometry.body.maxY),
            control2: CGPoint(x: geometry.body.minX + geometry.radius * 0.72, y: geometry.tailCapBottom.y)
        )
        path.addCurve(
            to: geometry.tailCapTop,
            control1: CGPoint(x: geometry.body.minX + geometry.radius * 0.30, y: geometry.tailCapBottom.y),
            control2: CGPoint(x: geometry.body.minX + geometry.radius * 0.18, y: geometry.tailCapTop.y)
        )
        path.addCurve(
            to: geometry.tailUpperJoin,
            control1: CGPoint(x: geometry.body.minX + geometry.radius * 0.12, y: geometry.body.maxY + geometry.radius * 0.14),
            control2: CGPoint(x: geometry.body.minX + geometry.radius * 0.04, y: geometry.body.maxY)
        )
        path.addLine(to: CGPoint(x: geometry.body.minX, y: geometry.body.maxY - geometry.radius))
        path.addLine(to: CGPoint(x: geometry.body.minX, y: geometry.body.minY + geometry.radius))
        path.addQuadCurve(
            to: CGPoint(x: geometry.body.minX + geometry.radius, y: geometry.body.minY),
            control: CGPoint(x: geometry.body.minX, y: geometry.body.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct TailPrototypeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tail Prototype")
                .font(.largeTitle.bold())
            Text("Two cubic Bézier curves: rounded left tip, then a short tail growing left-to-right.")
                .font(.body)
                .foregroundStyle(.secondary)

            ZStack(alignment: .bottomLeading) {
                TailPrototypeBubbleShape()
                    .fill(Color(red: 0.82, green: 0.80, blue: 1.0))
                    .overlay {
                        TailPrototypeBubbleShape()
                            .stroke(
                                Color(red: 0.54, green: 0.43, blue: 0.96),
                                style: StrokeStyle(lineWidth: 8, lineJoin: .round)
                            )
                    }
                    .frame(width: 300, height: 150)
                    .padding(20)
            }
            .frame(width: 360, height: 190, alignment: .bottomLeading)
            .background(Color(red: 0.78, green: 0.94, blue: 0.98))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.96, green: 0.95, blue: 1.0))
    }
}

#Preview {
    TailPrototypeView()
}
