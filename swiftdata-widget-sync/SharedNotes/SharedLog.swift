import os

enum SharedLog {
    private static let subsystem = "com.huahuahu.demo.SwiftDataResearch"

    static let store = Logger(subsystem: subsystem, category: "SharedStore")
    static let app = Logger(subsystem: subsystem, category: "App")
    static let history = Logger(subsystem: subsystem, category: "History")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}
