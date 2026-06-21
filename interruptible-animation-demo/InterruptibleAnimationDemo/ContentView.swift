import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UIKitInterruptibleDemoView()
                .ignoresSafeArea(edges: .bottom)
                .tabItem {
                    Label("UIKit", systemImage: "hand.draw")
                }

            Text("SwiftUI comparison will be added in Task 3.")
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
        }
    }
}
