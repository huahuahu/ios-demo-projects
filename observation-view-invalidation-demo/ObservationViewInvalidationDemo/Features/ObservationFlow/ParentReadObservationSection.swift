import SwiftUI

struct ParentReadObservationSection: View {
  @Bindable var model: ObservationDemoModel

  init(model: ObservationDemoModel) {
    self.model = model
    DemoLifecycleLog.initialized("ParentReadObservationSection")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("ParentReadObservationSection")

    ExperimentSection(
      title: "实验 B：普通值 vs Binding",
      detail: "name、score 由父视图读取；age 通过 $model.age 传 Binding。"
    ) {
      SnapshotPropertyView(property: .name, value: model.name)
      BindingAgePropertyView(age: $model.age)
      SnapshotPropertyView(property: .score, value: model.score.formatted())
    }
  }
}

private struct SnapshotPropertyView: View {
  let property: DemoProperty
  let value: String

  init(property: DemoProperty, value: String) {
    self.property = property
    self.value = value
    DemoLifecycleLog.initialized("SnapshotPropertyView[\(property.rawValue)]")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("SnapshotPropertyView[\(property.rawValue)]")

    ObservationValueCard(property: property, value: value)
  }
}
