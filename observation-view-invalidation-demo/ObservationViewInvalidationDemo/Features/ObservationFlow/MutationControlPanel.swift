import SwiftUI

struct MutationControlPanel: View {
  let model: ObservationDemoModel

  init(model: ObservationDemoModel) {
    self.model = model
    DemoLifecycleLog.initialized("MutationControlPanel")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("MutationControlPanel")

    VStack(alignment: .leading, spacing: 12) {
      Text("修改一个属性")
        .font(.headline)

      ForEach(DemoProperty.allCases) { property in
        Button(property.title, systemImage: property.systemImage) {
          model.mutate(property)
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("mutate-\(property.rawValue)")
      }

      Button("重置全部", systemImage: "arrow.counterclockwise", action: model.reset)
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("reset-all")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 16))
  }
}
