import SwiftUI

struct ContentView: View {
    @State private var scale = 1.0
    private let samples = FontSample.defaultSamples

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Scale")
                                .font(.headline)
                            Spacer()
                            Text(scale, format: .number.precision(.fractionLength(2)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $scale, in: 0.8...1.4, step: 0.05)
                    }
                    .padding(.vertical, 6)
                }

                Section("Samples") {
                    ForEach(samples) { sample in
                        FontSampleRow(sample: sample, scale: scale)
                    }
                }

                Section("Density Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("字体大小会同时影响可读性、信息密度和视觉层级。")
                            .font(.system(size: 17 * scale))
                        Text("当字号变大时，屏幕可容纳的信息减少；当字号变小时，扫读成本会上升。")
                            .font(.system(size: 15 * scale))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Font Size Research")
        }
    }
}

private struct FontSampleRow: View {
    let sample: FontSample
    let scale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(sample.role)
                    .font(.headline)
                Spacer()
                Text("\(Int(sample.pointSize * scale)) pt")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(sample.sampleText)
                .font(.system(size: sample.pointSize * scale, weight: sample.weight))
                .lineLimit(2)

            Text("Base \(Int(sample.pointSize)) pt")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}

