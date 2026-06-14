import SwiftUI

// MARK: - iOS 26 Siri-Style Screen Edge Glow Animation (Metal Shader)
//
// Single-pass Metal fragment shader driven by SwiftUI's .colorEffect().
// Replaces the previous 5-layer blur approach with one draw call and
// zero Gaussian blur passes — dramatically lower GPU / CPU / battery cost.

struct SiriGlowView: View {
    /// Tied directly to speechManager.isRecording.
    var isActive: Bool

    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    /// Timestamp captured when the glow starts, so the angle is always
    /// computed relative to a fixed origin — no reset on each render pass.
    @State private var startDate: Date? = nil

    /// Seconds per full revolution for the primary gradient.
    private let revolutionDuration: Double = 3.0
    /// Actual device screen corner radius, queried once at first use.
    private static let deviceCornerRadius: Float = {
        let cr = (UIScreen.main.value(forKey: "displayCornerRadius") as? CGFloat) ?? 47
        return Float(cr)
    }()

    var body: some View {
        // TimelineView drives every frame from real clock time.
        TimelineView(.animation(paused: !isActive)) { context in
            let elapsed = startDate.map {
                context.date.timeIntervalSince($0)
            } ?? 0

            // Capture @State values into local constants so they can
            // be read inside the @Sendable visualEffect closure.
            let currentOpacity = glowOpacity
            let currentPulse = pulseScale

            GeometryReader { geo in
                Rectangle()
                    .fill(.white)   // shader replaces every pixel — needs non-clear input
                    .visualEffect { content, proxy in
                        content.colorEffect(
                            ShaderLibrary.siriGlow(
                                .float(Float(elapsed)),
                                .float(Float(currentOpacity)),
                                .float2(
                                    Float(proxy.size.width),
                                    Float(proxy.size.height)
                                ),
                                .float(Self.deviceCornerRadius),
                                .float(Float(currentPulse))
                            )
                        )
                    }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                startGlow()
            } else {
                stopGlow()
            }
        }
        .onAppear {
            if isActive { startGlow() }
        }
    }

    // MARK: - Animation Control

    private func startGlow() {
        // Anchor elapsed-time calculations to right now.
        startDate = Date()

        withAnimation(.easeOut(duration: 0.4)) {
            glowOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    private func stopGlow() {
        withAnimation(.easeInOut(duration: 0.5)) {
            glowOpacity = 0
            pulseScale = 1.0
        }
        // Clear the start date after fade-out so the next session begins fresh.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            startDate = nil
        }
    }
}
