import Testing

@testable import ObservationViewInvalidationDemo

struct ObservationDemoModelTests {
  @Test("每次操作只修改目标属性", arguments: DemoProperty.allCases)
  @MainActor
  func mutationChangesOnlySelectedProperty(_ property: DemoProperty) {
    let model = ObservationDemoModel()
    let before = model.snapshot

    model.mutate(property)

    let after = model.snapshot

    switch property {
    case .name:
      #expect(after.name != before.name)
      #expect(after.age == before.age)
      #expect(after.score == before.score)
    case .age:
      #expect(after.name == before.name)
      #expect(after.age == before.age + 1)
      #expect(after.score == before.score)
    case .score:
      #expect(after.name == before.name)
      #expect(after.age == before.age)
      #expect(after.score == before.score + 10)
    }
  }

  @Test("重置恢复初始值")
  @MainActor
  func resetRestoresInitialSnapshot() {
    let model = ObservationDemoModel()
    let initial = model.snapshot

    for property in DemoProperty.allCases {
      model.mutate(property)
    }
    model.reset()

    #expect(model.snapshot == initial)
  }
}
