import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("UIKit demo will be added in Task 2.")
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
