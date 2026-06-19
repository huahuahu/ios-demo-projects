import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SwiftUIKeyboardTabView()
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }

            UIKitKeyboardTabContainer()
                .tabItem {
                    Label("UIKit", systemImage: "square.stack.3d.up.fill")
                }
        }
    }
}
