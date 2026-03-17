import SwiftUI
import Combine

/// Animated waveform bars that respond to live microphone audio levels
struct WaveformView: View {
    /// Normalized audio power from 0.0 (silent) to 1.0 (loud)
    var audioLevel: Float

    private let barCount = 5
    // Each bar gets a fixed "base" weight so bars have varied heights
    private let barWeights: [Float] = [0.6, 0.85, 1.0, 0.75, 0.5]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(
                        .spring(response: 0.18, dampingFraction: 0.55),
                        value: audioLevel
                    )
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minH: CGFloat = 4
        let maxH: CGFloat = 28

        // Each bar scales with the audio level but weighted differently for a natural spread
        let weight = CGFloat(barWeights[index])
        let level = CGFloat(audioLevel)

        // When silent, bars collapse to min; at peak they fill to max
        return minH + (level * weight) * (maxH - minH)
    }
}

#Preview {
    WaveformView(audioLevel: 0.7)
        .frame(height: 40)
        .padding()
}
