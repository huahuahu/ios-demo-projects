import SwiftUI

struct ExperimentSection<Content: View>: View {
  let title: String
  let detail: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)

      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)

      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.background, in: .rect(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(.separator, lineWidth: 0.5)
    }
  }
}
