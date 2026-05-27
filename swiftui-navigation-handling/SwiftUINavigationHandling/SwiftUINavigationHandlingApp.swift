import SwiftUI

@main
struct SwiftUINavigationHandlingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .handlesExternalEvents(matching: ["*"])
    }
}
