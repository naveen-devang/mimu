import SwiftUI

private struct DustMote: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let opacityOrig: Double
    let color: Color
}

// A shape that represents the flared vertical beam (narrow at top, wide at bottom)
struct TrumpetBeamShape: Shape {
    var topWidth: CGFloat
    var bottomWidth: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topWidth, bottomWidth) }
        set {
            topWidth = newValue.first
            bottomWidth = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let top = rect.minY
        let bottom = rect.maxY
        
        path.move(to: CGPoint(x: cx - topWidth/2, y: top))
        path.addLine(to: CGPoint(x: cx + topWidth/2, y: top))
        
        // Curve smoothly towards bottom right
        path.addCurve(
            to: CGPoint(x: cx + bottomWidth/2, y: bottom),
            control1: CGPoint(x: cx + topWidth/2, y: top + (bottom - top) * 0.90),
            control2: CGPoint(x: cx + bottomWidth/2, y: top + (bottom - top) * 0.98)
        )
        
        path.addLine(to: CGPoint(x: cx - bottomWidth/2, y: bottom))
        
        // Curve back to top left
        path.addCurve(
            to: CGPoint(x: cx - topWidth/2, y: top),
            control1: CGPoint(x: cx - bottomWidth/2, y: top + (bottom - top) * 0.98),
            control2: CGPoint(x: cx - topWidth/2, y: top + (bottom - top) * 0.90)
        )
        
        return path
    }
}

// MARK: - Final Beam View
struct ApplePayBeamView: View {
    let text: String
    var onComplete: () -> Void

    @State private var bgOpacity: Double = 0
    @State private var beamLength: CGFloat = 0.0
    @State private var auraOpacity: Double = 0.0
    @State private var dustArray: [DustMote] = []
    
    @State private var startTime: Date?
    
    // Core Colors based on Image 2
    let coreWhite = Color.white
    let beamBlue  = Color(red: 0.4, green: 0.4, blue: 1.0)
    let beamPurple = Color(red: 0.3, green: 0.1, blue: 0.8)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            
            // Fixed Dynamic Island coordinates
            let islandY: CGFloat = 37
            
            // Calculate absolute layout of the input pill to secure the beam flawlessly
            let safeBottom = geo.safeAreaInsets.bottom
            let pillHeight: CGFloat = 64
            let pillWidth = w - 40 // Matches the pill's padding(.horizontal, 20)
            let pillBottomMargin: CGFloat = 16
            
            let pillCenterY = h - safeBottom - pillBottomMargin - (pillHeight / 2)
            // Start beam precisely at the top of the input pill
            let baseY: CGFloat = pillCenterY - (pillHeight / 2)
            let beamHeight = baseY - islandY
            
            ZStack {
                // 1. Semi-transparent overlay to dim the UI, preserving context
                Color.black
                    .ignoresSafeArea()
                    .opacity(bgOpacity * 0.75)
                
                if let start = startTime {
                    TimelineView(.animation) { tl in
                        let elapsed = tl.date.timeIntervalSince(start)
                        
                        ZStack {
                            // 2. Ambient Dust Motes slowly drifting upwards
                            Canvas { ctx, _ in
                                for dust in dustArray {
                                    // Move slowly up
                                    let currentY = dust.y - dust.speed * CGFloat(elapsed)
                                    // Gentle sine wave horiz drift
                                    let currentX = dust.x + sin(elapsed * 1.5 + Double(dust.x)) * 10.0
                                    
                                    // Wrapping logic
                                    var finalY = currentY
                                    while finalY < -20 { finalY += h + 40 }
                                    
                                    let flicker = 0.6 + 0.4 * sin(elapsed * 5.0 + Double(dust.x * 0.5))
                                    let finalOpacity = dust.opacityOrig * flicker * auraOpacity
                                    
                                    if finalOpacity > 0.01 {
                                        ctx.fill(
                                            Path(ellipseIn: CGRect(x: currentX, y: finalY, width: dust.size, height: dust.size)),
                                            with: .color(dust.color.opacity(finalOpacity))
                                        )
                                        // Slight halo for the dust
                                        ctx.fill(
                                            Path(ellipseIn: CGRect(x: currentX - dust.size/2, y: finalY - dust.size/2, width: dust.size * 2, height: dust.size * 2)),
                                            with: .color(dust.color.opacity(finalOpacity * 0.3))
                                        )
                                    }
                                }
                            }
                            
                            // 3. The Core Trumpet Beams and Glowing Input Pill
                            ZStack {
                                // Purple Glow surrounding the borders of the input bar
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(beamPurple, lineWidth: 4)
                                    .frame(width: pillWidth, height: pillHeight)
                                    .position(x: cx, y: pillCenterY)
                                    .blur(radius: 6)
                                    .opacity(auraOpacity)
                                    
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(beamPurple.opacity(0.8), lineWidth: 8)
                                    .frame(width: pillWidth + 8, height: pillHeight + 8)
                                    .position(x: cx, y: pillCenterY)
                                    .blur(radius: 15)
                                    .opacity(auraOpacity)
                                    
                                // Ambient base aura directly over the pill
                                Ellipse()
                                    .fill(
                                        RadialGradient(
                                            colors: [beamPurple.opacity(0.8), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: pillWidth * 0.7
                                        )
                                    )
                                    .frame(width: pillWidth * 1.4, height: 160)
                                    .position(x: cx, y: pillCenterY)
                                    .blur(radius: 30)
                                    .opacity(auraOpacity)
                                
                                // The main blurred Purple/Blue Trumpet Beam exactly matching pill boundaries
                                TrumpetBeamShape(topWidth: 40, bottomWidth: pillWidth)
                                    .fill(
                                        LinearGradient(
                                            colors: [beamBlue.opacity(0.8), beamPurple.opacity(0.95)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: w, height: beamHeight)
                                    .position(x: cx, y: baseY - beamHeight / 2)
                                    .blur(radius: 12)
                                
                                // Sharper Mid Blue Trumpet Beam
                                TrumpetBeamShape(topWidth: 12, bottomWidth: pillWidth - 30)
                                    .fill(beamBlue.opacity(0.9))
                                    .frame(width: w, height: beamHeight)
                                    .position(x: cx, y: baseY - beamHeight / 2)
                                    .blur(radius: 6)
                                
                                // Pure White Core Trumpet Beam (Extremely bright and intense)
                                TrumpetBeamShape(topWidth: 4, bottomWidth: pillWidth * 0.4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.95)],
                                            startPoint: .bottom, // brightest at bottom
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: w, height: beamHeight)
                                    .position(x: cx, y: baseY - beamHeight / 2)
                                    .blur(radius: 2)
                                    
                                // Connection aura at Dynamic Island
                                Circle()
                                    .fill(coreWhite)
                                    .frame(width: 30, height: 30)
                                    .blur(radius: 10)
                                    .position(x: cx, y: islandY)
                                    
                                Circle()
                                    .fill(beamBlue)
                                    .frame(width: 80, height: 60)
                                    .blur(radius: 25)
                                    .position(x: cx, y: islandY)
                            }
                            // The beam animates by sliding a mask upwards from the bottom
                            // It gives the perfect "shooting straight up" look
                            .mask(
                                Rectangle()
                                    .frame(width: w * 3, height: h * 2)
                                    // Start the mask below screen, animate up
                                    .offset(y: h * 2 * (1.0 - beamLength))
                            )
                            .opacity(auraOpacity)
                            
                            // 4. Transform the Voice Text into the Beam
                            Text(text)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: beamBlue, radius: 10)
                                // The text stretches infinitely vertically
                                .scaleEffect(y: 1.0 + beamLength * 60.0, anchor: .bottom)
                                .position(x: cx, y: baseY)
                                // Shoots up towards the Dynamic Island securely
                                .offset(y: -(beamLength * beamHeight * 0.85))
                                // Blurs out to become pure light
                                .blur(radius: beamLength * 20)
                                .opacity(isAnimating ? (1.0 - Double(beamLength) * 0.3) : 0.0)
                        }
                        .blendMode(.plusLighter) // Maximizes glowing brightness HDR
                    }
                }
            }
            .onAppear {
                generateDustMotes(width: w, height: h)
                startAnimationSequence()
            }
        }
        .ignoresSafeArea()
        // Prevents touches while animating
        .allowsHitTesting(false)
    }

    @State private var isAnimating = false

    private func generateDustMotes(width: CGFloat, height: CGFloat) {
        var motes = [DustMote]()
        let colors: [Color] = [.white, Color(red: 0.6, green: 0.8, blue: 1.0), beamBlue, beamPurple]
        
        // 200 light particles uniformly distributed
        for _ in 0..<200 {
            motes.append(DustMote(
                x: CGFloat.random(in: -30...(width + 30)),
                y: CGFloat.random(in: 0...(height + 150)),
                speed: CGFloat.random(in: 10...60),
                size: CGFloat.random(in: 1...3.5),
                opacityOrig: Double.random(in: 0.15...0.7),
                color: colors.randomElement()!
            ))
        }
        dustArray = motes
    }
    
    private func startAnimationSequence() {
        startTime = Date()
        isAnimating = true
        
        // 1. Immediately fade background
        withAnimation(.easeIn(duration: 0.15)) {
            bgOpacity = 1.0
        }
        
        // 2. Beam shoots straight up from the bottom (Mask slides up quickly)
        // Also triggers isAnimating constraint for text opacity
        withAnimation(.timingCurve(0.1, 0.9, 0.2, 1.0, duration: 0.6)) {
            beamLength = 1.0
            auraOpacity = 1.0
        }
        
        // 3. Hold the beam in place for a bit, then fade out smoothly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                auraOpacity = 0.0
                bgOpacity = 0.0
            }
        }
        
        // 4. Return control 
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onComplete()
        }
    }
}
