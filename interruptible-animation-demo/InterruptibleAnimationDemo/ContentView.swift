import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UIKitInterruptibleDemoView()
                .ignoresSafeArea(edges: .bottom)
                .tabItem {
                    Label("UIKit", systemImage: "hand.draw")
                }

            SwiftUIInterruptibleDemoView()
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
        }
    }
}
