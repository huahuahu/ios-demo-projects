import SwiftUI
import os

struct ContentView: View {
    @State private var eventCount = 0
    @State private var lastEvent = "Ready"

    private let logger = Logger(subsystem: "com.tigerguo.demo.LogResearchDemo", category: "DemoEvents")

    var body: some View {
        VStack(spacing: 20) {
            Text("Xcode Log Research")
                .font(.title)
                .fontWeight(.semibold)

            Text(lastEvent)
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Emit Sample Logs") {
                emitSampleLogs()
            }
            .buttonStyle(.borderedProminent)

            Text("Events: \(eventCount)")
                .monospacedDigit()
        }
        .padding()
        .onAppear {
            logger.notice("ContentView appeared")
        }
    }

    private func emitSampleLogs() {
        eventCount += 1
        lastEvent = "Emitted log batch #\(eventCount)"

        logger.debug("Debug detail for batch \(eventCount)")
        logger.info("User triggered sample log batch \(eventCount)")
        logger.warning("Synthetic warning for AI log analysis batch \(eventCount)")

        if eventCount.isMultiple(of: 3) {
            logger.error("Synthetic recoverable error after \(eventCount) batches")
        }
    }
}

#Preview {
    ContentView()
}

