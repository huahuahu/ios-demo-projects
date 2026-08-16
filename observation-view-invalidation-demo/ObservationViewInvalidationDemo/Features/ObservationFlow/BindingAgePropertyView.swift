import SwiftUI

struct BindingAgePropertyView: View {
  @Binding var age: Int

  init(age: Binding<Int>) {
    _age = age
    DemoLifecycleLog.initialized("BindingAgePropertyView[age]")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("BindingAgePropertyView[age]")

    ObservationValueCard(property: .age, value: age.formatted())
  }
}
