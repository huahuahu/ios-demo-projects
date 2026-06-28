import SwiftUI

struct ContentView: View {
    @State private var viewModel = StreamDemoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    explanation
                    statusCard
                    controls
                    logHint
                }
                .padding()
            }
            .navigationTitle("AsyncStream")
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AsyncStream + Continuation")
                .font(.title.bold())

            Text("The source owns the continuation and yields values. The consumer owns a task that reads the stream with for-await. Watch the console to see when finish, cancellation, onTermination, cleanup, and deinit happen.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.status.title)
                .font(.headline)

            Text(viewModel.status.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button("Start Stream", systemImage: "play.fill") {
                Task {
                    await viewModel.startStream()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel Consumer", systemImage: "xmark.circle") {
                viewModel.cancelConsumer()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canCancel == false)

            Button("Finish Producer", systemImage: "checkmark.circle") {
                Task {
                    await viewModel.finishProducer()
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canFinish == false)

            Button("Drop Owner", systemImage: "trash") {
                Task {
                    await viewModel.dropOwner()
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canDropOwner == false)
        }
        .frame(maxWidth: .infinity)
    }

    private var logHint: some View {
        Text("Open Xcode or Simulator console and filter for com.huahuahu.demo.AsyncStreamContinuationDemo.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}
