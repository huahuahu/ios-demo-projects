import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                heroSection
                comparisonSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.94, blue: 0.98),
                    Color(red: 0.96, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat Bubble Shape")
                .font(.largeTitle.bold())
            Text("One reusable SwiftUI Shape drives the reference bubble and every variant below.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(BubbleSample.hero.title)
                .font(.headline)
            ChatBubbleView(
                message: BubbleSample.hero.message,
                style: BubbleSample.hero.style,
                font: .title2
            )
            Text(BubbleSample.hero.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Variants")
                .font(.title2.bold())

            ForEach(BubbleSample.comparisonSamples) { sample in
                VStack(alignment: .leading, spacing: 8) {
                    Text(sample.title)
                        .font(.headline)
                    Text(sample.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ChatBubbleView(message: sample.message, style: sample.style)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

#Preview {
    ContentView()
}
