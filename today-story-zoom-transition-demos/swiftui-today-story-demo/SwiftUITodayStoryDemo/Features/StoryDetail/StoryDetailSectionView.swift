import SwiftUI

struct StoryDetailSectionView: View {
    let section: StoryDetailSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.title2)
                .bold()
            Text(section.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
        }
        .padding(.horizontal, 24)
    }
}
