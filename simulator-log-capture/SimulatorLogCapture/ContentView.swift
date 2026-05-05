import OSLog
import SwiftUI

struct ContentView: View {
    private let logger = Logger(subsystem: "com.huahuahu.demo.SimulatorLogCapture", category: "Button")

    var body: some View {
        Button("Print Logs") {
            print("print log from SimulatorLogCapture")
            os_log("os_log from SimulatorLogCapture")
            logger.info("Logger log from SimulatorLogCapture")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
