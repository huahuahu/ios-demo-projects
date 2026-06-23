import SwiftUI

struct CategoryDetailView: View {
    let item: HealthCategoryItem

    var body: some View {
        VStack(spacing: 20) {
            CategoryCardView(item: item)
                .frame(maxWidth: 360)

            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title2.bold())

                Text("This detail screen is intentionally small. The demo focuses on switching between native List rows and a polished LazyVGrid card layout while keeping pagination in one ViewModel.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CategoryDetailView(item: .generatedItems(count: 1)[0])
}
