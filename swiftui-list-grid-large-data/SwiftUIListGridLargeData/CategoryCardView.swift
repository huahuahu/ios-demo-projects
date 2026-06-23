import SwiftUI

struct CategoryCardView: View {
    let item: HealthCategoryItem

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: item.symbolName)
                .font(.title.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .accessibilityHidden(true)

            Spacer(minLength: 16)

            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(item.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(
            LinearGradient(
                colors: item.palette.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if differentiateWithoutColor {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 2)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 14, y: 7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), \(item.subtitle)")
    }
}

#Preview {
    CategoryCardView(item: .generatedItems(count: 1)[0])
        .padding()
}
