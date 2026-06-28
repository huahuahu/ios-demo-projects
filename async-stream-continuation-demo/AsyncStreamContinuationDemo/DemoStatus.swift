enum DemoStatus: Equatable, Sendable {
    case idle
    case running(lastEvent: String?)
    case cancelled
    case finished
    case released

    var title: String {
        switch self {
        case .idle:
            "Idle"
        case .running:
            "Running"
        case .cancelled:
            "Cancelled"
        case .finished:
            "Finished"
        case .released:
            "Owner Released"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "Tap Start Stream to create an AsyncStream and store its continuation."
        case .running(let lastEvent):
            if let lastEvent {
                "Latest event: \(lastEvent)"
            } else {
                "Waiting for the producer to yield."
            }
        case .cancelled:
            "The consumer task was cancelled. Watch for onTermination cleanup in the console."
        case .finished:
            "The producer called finish(). The for-await loop can end normally."
        case .released:
            "The view model finished the stream before releasing its source reference."
        }
    }
}
