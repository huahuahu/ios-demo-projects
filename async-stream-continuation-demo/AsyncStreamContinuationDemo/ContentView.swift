import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.trianglehead.2.clockwise")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("AsyncStream Continuation Demo")
                .font(.title)
                .fontWeight(.semibold)

            Text("Use this demo to observe AsyncStream lifecycle logs in Xcode or Simulator console.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
