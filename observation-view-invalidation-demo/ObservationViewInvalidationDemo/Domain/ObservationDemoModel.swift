import Observation

@Observable
@MainActor
final class ObservationDemoModel {
  private(set) var name = "花花虎 0"
  var age = 18
  private(set) var score = 100

  @ObservationIgnored private var nameRevision = 0

  var snapshot: DemoSnapshot {
    DemoSnapshot(name: name, age: age, score: score)
  }

  func mutate(_ property: DemoProperty) {
    switch property {
    case .name:
      let oldValue = name
      nameRevision += 1
      name = "花花虎 \(nameRevision)"
      DemoLifecycleLog.modelMutation(property: property, from: oldValue, to: name)
    case .age:
      let oldValue = age
      age += 1
      DemoLifecycleLog.modelMutation(property: property, from: oldValue, to: age)
    case .score:
      let oldValue = score
      score += 10
      DemoLifecycleLog.modelMutation(property: property, from: oldValue, to: score)
    }
  }

  func reset() {
    nameRevision = 0
    name = "花花虎 0"
    age = 18
    score = 100
    DemoLifecycleLog.event("MODEL reset: all three observable properties were assigned")
  }
}
