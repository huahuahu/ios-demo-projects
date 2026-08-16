enum DemoProperty: String, CaseIterable, Identifiable, Sendable {
  case name
  case age
  case score

  var id: Self { self }

  var title: String {
    switch self {
    case .name:
      "姓名"
    case .age:
      "年龄"
    case .score:
      "分数"
    }
  }

  var systemImage: String {
    switch self {
    case .name:
      "person.text.rectangle"
    case .age:
      "birthday.cake"
    case .score:
      "star"
    }
  }
}
