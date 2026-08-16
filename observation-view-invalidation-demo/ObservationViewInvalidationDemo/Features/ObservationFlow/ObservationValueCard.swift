import SwiftUI

struct ObservationValueCard: View {
  let property: DemoProperty
  let value: String

  var body: some View {
    HStack {
      Label(property.title, systemImage: property.systemImage)
      Spacer()
      Text(value)
        .font(.body.monospacedDigit())
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 12))
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("value-\(property.rawValue)")
  }
}
