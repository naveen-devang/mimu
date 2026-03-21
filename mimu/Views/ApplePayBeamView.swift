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
        
        path.addCurve(
            to: CGPoint(x: cx + bottomWidth/2, y: bottom),
            control1: CGPoint(x: cx + topWidth/2, y: top + (bottom - top) * 0.85),
            control2: CGPoint(x: cx + bottomWidth/2, y: top + (bottom - top) * 0.95)
        )
        
        path.addLine(to: CGPoint(x: cx - bottomWidth/2, y: bottom))
        
        path.addCurve(
            to: CGPoint(x: cx - topWidth/2, y: top),
            control1: CGPoint(x: cx - bottomWidth/2, y: top + (bottom - top) * 0.95),
            control2: CGPoint(x: cx - topWidth/2, y: top + (bottom - top) * 0.85)
        )
        
        return path
    }
}

struct FlatBaseBeamMask: Shape {
    var baseWidth: CGFloat
    var transitionHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedBaseWidth = min(max(baseWidth, 1), rect.width)
        let transitionY = max(rect.maxY - transitionHeight, rect.minY)
        let baseMinX = rect.midX - clampedBaseWidth / 2
        let baseMaxX = rect.midX + clampedBaseWidth / 2

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: transitionY))
        path.addLine(to: CGPoint(x: baseMaxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: baseMinX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: transitionY))
        path.closeSubpath()
        return path
    }
}

struct ApplePayBeamView: View {
    let text: String
    let pillFrame: CGRect
    var onComplete: () -> Void

    @State private var bgOpacity: Double = 0
    @State private var beamLength: CGFloat = 0.0
    @State private var auraOpacity: Double = 0.0
    @State private var dustArray: [DustMote] = []
    @State private var startTime: Date?
    
    let beamBlue  = Color(red: 0.4, green: 0.5, blue: 1.0)
    let beamPurple = Color(red: 0.5, green: 0.2, blue: 0.9)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let islandCenterY: CGFloat = 37
            let islandWidth: CGFloat = 126
            let islandHeight: CGFloat = 37
            let topOverscan: CGFloat = 34
            
            // EXACT ALIGNMENT MATH
            let viewOrigin = geo.frame(in: .named("root")).origin
            let localPill = CGRect(
                x: pillFrame.minX - viewOrigin.x,
                y: pillFrame.minY - viewOrigin.y,
                width: pillFrame.width,
                height: pillFrame.height
            )
            
            // Fallbacks in case geometry hasn't fully loaded
            let isValid = localPill.width > 10
            let pWidth = isValid ? localPill.width : (w - 40)
            let pMidX = isValid ? localPill.midX : w / 2
            
            // Anchor the beam slightly into the pill and run it to the island centerline.
            let baseY = isValid ? (localPill.minY + 12) : (h - 118)
            let beamHeight = max(baseY - islandCenterY + topOverscan, 0)
            
            ZStack {
                // Dimming background
                Color.black.ignoresSafeArea().opacity(bgOpacity * 0.6)
                
                if let start = startTime {
                    TimelineView(.animation) { tl in
                        let elapsed = tl.date.timeIntervalSince(start)
                        
                        ZStack {
                            // 1. Ambient Particles
                            Canvas { ctx, _ in
                                for dust in dustArray {
                                    let currentY = dust.y - (dust.speed * CGFloat(elapsed))
                                    let currentX = dust.x + sin(elapsed * 2 + Double(dust.x)) * 8
                                    var finalY = currentY
                                    while finalY < -20 { finalY += h + 40 }
                                    let flicker = 0.5 + 0.5 * sin(elapsed * 4 + Double(dust.x))
                                    ctx.fill(Path(ellipseIn: CGRect(x: currentX, y: finalY, width: dust.size, height: dust.size)), with: .color(dust.color.opacity(dust.opacityOrig * flicker * auraOpacity)))
                                }
                            }

                            // 2. The Shooting Beam
                            ZStack {
                                TrumpetBeamShape(topWidth: 28, bottomWidth: pWidth * 0.86)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                beamBlue.opacity(0.78),
                                                beamPurple.opacity(0.78)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .blur(radius: 6)
                                
                                TrumpetBeamShape(topWidth: 18, bottomWidth: pWidth * 0.68)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.9),
                                                beamBlue.opacity(0.72)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .blur(radius: 3)

                                TrumpetBeamShape(topWidth: 11, bottomWidth: pWidth * 0.48)
                                    .fill(Color.white.opacity(0.98))
                                    .blur(radius: 1.4)
                            }
                            .frame(width: w, height: beamHeight)
                            .position(x: pMidX, y: baseY - beamHeight / 2)
                            .opacity(auraOpacity)
                            .compositingGroup()
                            // Reveal the beam vertically without a rounded mask head.
                            .mask(
                                Rectangle()
                                    .frame(width: w, height: beamHeight * beamLength)
                                    .frame(width: w, height: beamHeight, alignment: .bottom)
                            )
                            .mask(
                                FlatBaseBeamMask(baseWidth: pWidth * 0.40, transitionHeight: 66)
                            )

                            // 3. Rounded connector so the beam terminates behind the Dynamic Island instead of flat-cutting.
                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(beamPurple.opacity(0.48))
                                    .frame(width: 48, height: 26)
                                    .blur(radius: 10)

                                Capsule(style: .continuous)
                                    .fill(beamBlue.opacity(0.62))
                                    .frame(width: 30, height: 18)
                                    .blur(radius: 6)

                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.98))
                                    .frame(width: 14, height: 10)
                                    .blur(radius: 2)
                            }
                            .position(x: w / 2, y: islandCenterY + 8)
                            .opacity(auraOpacity)
                            
                            // 4. Island Impact Glow
                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(beamPurple.opacity(0.45))
                                    .frame(width: islandWidth + 22, height: islandHeight + 18)
                                    .blur(radius: 16)

                                Capsule(style: .continuous)
                                    .fill(beamBlue.opacity(0.55))
                                    .frame(width: islandWidth + 8, height: islandHeight + 10)
                                    .blur(radius: 10)

                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.98))
                                    .frame(width: islandWidth - 22, height: islandHeight - 6)
                                    .blur(radius: 7)
                            }
                            .position(x: w / 2, y: islandCenterY)
                            .opacity(beamLength > 0.88 ? auraOpacity : 0)
                            .scaleEffect(0.94 + (beamLength * 0.06))

                            // 5. Flying Text
                            Text(text)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .position(x: pMidX, y: baseY + 10)
                                .scaleEffect(y: 1.0 + (beamLength * 3), anchor: .bottom)
                                .offset(y: -beamLength * (beamHeight + 50))
                                .blur(radius: beamLength * 10)
                                .opacity(1.0 - Double(beamLength))
                        }
                        .blendMode(.plusLighter)
                    }
                }
            }
            .onAppear {
                generateDustMotes(width: w, height: h)
                runEnhancedSequence()
            }
        }
        .ignoresSafeArea()
    }

    private func generateDustMotes(width: CGFloat, height: CGFloat) {
        let colors: [Color] = [beamBlue, beamPurple, .white]
        dustArray = (0..<100).map { _ in
            DustMote(x: .random(in: 0...width), y: .random(in: 0...height), speed: .random(in: 30...80), size: .random(in: 1...3), opacityOrig: .random(in: 0.3...0.7), color: colors.randomElement()!)
        }
    }

    private func runEnhancedSequence() {
        startTime = Date()
        beamLength = 0
        auraOpacity = 0
        bgOpacity = 0
        
        // Phase 1: bring the background and particles in before the beam launches.
        withAnimation(.easeOut(duration: 0.6)) {
            bgOpacity = 1.0
            auraOpacity = 1.0
        }
        
        // Phase 2: launch the beam with a slower, smooth rise.
        withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.25)) {
            beamLength = 1.0
        }
        
        // Phase 3: Smooth Dissolve - Held slightly longer so user can read the impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                auraOpacity = 0
                bgOpacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }
}
