import OSLog

protocol DemoLogging: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
}

struct SystemDemoLogger: DemoLogging {
    private let logger: Logger

    init(category: String) {
        logger = Logger(
            subsystem: "com.huahuahu.demo.AsyncStreamContinuationDemo",
            category: category
        )
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}

struct SilentDemoLogger: DemoLogging {
    func debug(_ message: String) {}

    func info(_ message: String) {}
}
