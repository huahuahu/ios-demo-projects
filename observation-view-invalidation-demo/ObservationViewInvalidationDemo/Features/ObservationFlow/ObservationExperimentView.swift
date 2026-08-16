import SwiftUI

struct ObservationExperimentView: View {
  @State private var model: ObservationDemoModel

  init() {
    _model = State(initialValue: ObservationDemoModel())
    DemoLifecycleLog.initialized("ObservationExperimentView")
  }

  var body: some View {
    let _ = DemoLifecycleLog.evaluatedBody("ObservationExperimentView")

    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          ExplanationCard()
          MutationControlPanel(model: model)
          DirectObservationSection(model: model)
          //          ParentReadObservationSection(model: model)
        }
        .padding()
      }
      .navigationTitle("Observation 刷新实验")
    }
  }
}

#Preview {
  ObservationExperimentView()
}
