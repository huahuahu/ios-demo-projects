import SwiftUI
import os

@main
struct LogResearchDemoApp: App {
    private let logger = Logger(subsystem: "com.tigerguo.demo.LogResearchDemo", category: "AppLifecycle")

    init() {
        logger.info("LogResearchDemo app initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

