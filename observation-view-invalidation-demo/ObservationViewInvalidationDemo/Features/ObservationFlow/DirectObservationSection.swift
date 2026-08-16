import SwiftUI

struct DirectObservationSection: View {
  let model: ObservationDemoModel

  init(model: ObservationDemoModel) {
    self.model = model
    DemoLifecycleLog.initialized("DirectObservationSection")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("DirectObservationSection")

    ExperimentSection(
      title: "实验 A：子视图直接读取",
      detail: "父视图只传 model；每个子视图的 body 只读取一个属性。"
    ) {
      DirectPropertyView(property: .name, model: model)
      DirectPropertyView(property: .age, model: model)
      DirectPropertyView(property: .score, model: model)
    }
  }
}

private struct DirectPropertyView: View {
  let property: DemoProperty
  let model: ObservationDemoModel

  init(property: DemoProperty, model: ObservationDemoModel) {
    self.property = property
    self.model = model
    DemoLifecycleLog.initialized("DirectPropertyView[\(property.rawValue)]")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("DirectPropertyView[\(property.rawValue)]")

    ObservationValueCard(property: property, value: displayedValue)
  }

  private var displayedValue: String {
    switch property {
    case .name:
      model.name
    case .age:
      model.age.formatted()
    case .score:
      model.score.formatted()
    }
  }
}
