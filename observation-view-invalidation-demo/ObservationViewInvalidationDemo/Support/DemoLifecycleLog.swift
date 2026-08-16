import OSLog

enum DemoLifecycleLog {
  private static let logger = Logger(
    subsystem: "com.huahuahu.demo.ObservationViewInvalidationDemo",
    category: "ObservationLifecycle"
  )

  static func event(_ message: String) {
    logger.notice("OBS-DEMO \(message, privacy: .public)")
  }

  static func initialized(_ view: String) {
    event("INIT  \(view)")
  }

  static func evaluatedBody(_ view: String) {
    event("BODY  \(view)")
  }

  static func modelMutation<Value>(
    property: DemoProperty,
    from oldValue: Value,
    to newValue: Value
  ) {
    event("MODEL \(property.rawValue): \(oldValue) -> \(newValue)")
  }
}
