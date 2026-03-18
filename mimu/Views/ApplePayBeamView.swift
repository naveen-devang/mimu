import SwiftUI

private struct Particle {
    let angle: Double
    let speed: CGFloat
    let delay: Double
    let size: CGFloat
    let brightness: Double
    let lifespan: Double
    let startDX: CGFloat
    let startDY: CGFloat
    let isBeam: Bool
    let r: Double
    let g: Double
    let b: Double
    let flickerRate: Double
    let wobbleFreq: Double
    let wobbleAmp: CGFloat
    let drift: CGFloat
}

private func randomParticleColor() -> (r: Double, g: Double, b: Double) {
    switch Double.random(in: 0...1) {
    case 0..<0.28: return (1.00, 1.00, 1.00)
    case 0.28..<0.50: return (0.70, 0.91, 1.00)
    case 0.50..<0.63: return (0.42, 0.93, 1.00)
    case 0.63..<0.73: return (0.80, 0.68, 1.00)
    case 0.73..<0.84: return (1.00, 0.82, 0.45)
    case 0.84..<0.92: return (1.00, 0.62, 0.28)
    default:          return (0.36, 0.80, 1.00)
    }
}

struct ApplePayBeamView: View {
    var onComplete: () -> Void

    @State private var startTime: Date?

    @State private var bgOpacity: Double = 0
    @State private var warmGlowOpacity: Double = 0
    @State private var coolGlowOpacity: Double = 0

    @State private var diAuraOpacity: Double = 0
    @State private var diAuraScale: CGFloat = 0.35

    @State private var impactFlashOpacity: Double = 0

    @State private var particles: [Particle] = []

    private let islandY: CGFloat = 37

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let h  = geo.size.height

            ZStack {
                Color(red: 0.03, green: 0.03, blue: 0.06)
                    .opacity(bgOpacity)
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color(red: 0.82, green: 0.46, blue: 0.06).opacity(warmGlowOpacity * 0.62),
                        Color(red: 0.62, green: 0.28, blue: 0.03).opacity(warmGlowOpacity * 0.30),
                        Color(red: 0.40, green: 0.14, blue: 0.02).opacity(warmGlowOpacity * 0.10),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 1.28),
                    startRadius: 5, endRadius: h * 0.82
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color(red: 0.25, green: 0.50, blue: 1.00).opacity(coolGlowOpacity * 0.22),
                        Color(red: 0.36, green: 0.30, blue: 0.92).opacity(coolGlowOpacity * 0.09),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: -0.10),
                    startRadius: 0, endRadius: h * 0.44
                )
                .ignoresSafeArea()

                if let start = startTime {
                    TimelineView(.animation) { tl in
                        let elapsed = tl.date.timeIntervalSince(start)

                        ZStack {
                            // ── Particle field ──
                            Canvas { context, _ in
                                for p in particles {
                                    let t = elapsed - p.delay
                                    guard t > 0 else { continue }
                                    let progress = t / p.lifespan
                                    guard progress < 1.01 else { continue }

                                    let fadeIn  = min(t / (p.lifespan * 0.08), 1.0)
                                    let fadeOut = progress > 0.42
                                        ? max(0.0, 1.0 - (progress - 0.42) / 0.58)
                                        : 1.0
                                    let flicker = p.flickerRate > 0
                                        ? 0.68 + 0.32 * sin(elapsed * p.flickerRate * 2 * .pi)
                                        : 1.0
                                    let opacity = p.brightness * fadeIn * fadeOut * flicker
                                    guard opacity > 0.01 else { continue }

                                    let dist = p.speed * CGFloat(t)
                                    let px: CGFloat
                                    let py: CGFloat

                                    if p.isBeam {
                                        let wobble = p.wobbleAmp * CGFloat(sin(elapsed * p.wobbleFreq * 2 * .pi))
                                        px = cx + p.startDX + wobble + dist * CGFloat(cos(p.angle)) * 0.18
                                        py = islandY + p.startDY + dist * CGFloat(sin(p.angle))
                                    } else {
                                        let perp = p.angle + .pi / 2
                                        px = cx + dist * CGFloat(cos(p.angle))
                                            + p.drift * CGFloat(t * t) * CGFloat(cos(perp))
                                        py = islandY + dist * CGFloat(sin(p.angle))
                                            + p.drift * CGFloat(t * t) * CGFloat(sin(perp))
                                    }

                                    let r = p.size / 2
                                    let particleColor = Color(red: p.r, green: p.g, blue: p.b)

                                    // Ball rendering: soft halo + bright solid core
                                    if p.size >= 1.0 {
                                        let hR = r * 2.2
                                        context.fill(
                                            Path(ellipseIn: CGRect(x: px - hR, y: py - hR,
                                                                   width: hR * 2, height: hR * 2)),
                                            with: .color(particleColor.opacity(opacity * 0.28))
                                        )
                                    }
                                    // Solid bright core
                                    context.fill(
                                        Path(ellipseIn: CGRect(x: px - r, y: py - r,
                                                               width: p.size, height: p.size)),
                                        with: .color(particleColor.opacity(opacity))
                                    )
                                }
                            }

                            // ── Shapeless DI nebula glow ──
                            ZStack {
                                // Widest diffuse haze
                                Ellipse()
                                    .fill(Color(red: 0.35, green: 0.55, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.16))
                                    .frame(
                                        width:  340 + CGFloat(sin(elapsed * 0.38)) * 38,
                                        height: 185 + CGFloat(cos(elapsed * 0.55)) * 24
                                    )
                                    .blur(radius: 72)
                                    .offset(x: CGFloat(sin(elapsed * 0.28)) * 20,
                                            y: CGFloat(cos(elapsed * 0.38)) * 14)

                                // Off-centre blue blob — right
                                Ellipse()
                                    .fill(Color(red: 0.28, green: 0.60, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.24))
                                    .frame(
                                        width:  178 + CGFloat(cos(elapsed * 0.68)) * 20,
                                        height:  98 + CGFloat(sin(elapsed * 0.88)) * 13
                                    )
                                    .blur(radius: 50)
                                    .offset(x:  34 + CGFloat(cos(elapsed * 0.48)) * 14,
                                            y:  -9 + CGFloat(sin(elapsed * 0.58)) *  9)

                                // Off-centre purple blob — left
                                Ellipse()
                                    .fill(Color(red: 0.55, green: 0.32, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.28))
                                    .frame(
                                        width:  152 + CGFloat(sin(elapsed * 0.82)) * 16,
                                        height:  87 + CGFloat(cos(elapsed * 0.98)) * 11
                                    )
                                    .blur(radius: 42)
                                    .offset(x: -32 + CGFloat(sin(elapsed * 0.52)) * 12,
                                            y:   6 + CGFloat(cos(elapsed * 0.68)) *  8)

                                // Wandering wisp — cyan
                                Ellipse()
                                    .fill(Color(red: 0.40, green: 0.85, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.22))
                                    .frame(width: 90, height: 40)
                                    .blur(radius: 24)
                                    .offset(x: CGFloat(sin(elapsed * 1.18 + 1.0)) * 46,
                                            y: CGFloat(cos(elapsed * 0.88 + 0.5)) * 23)

                                // Wandering wisp — violet
                                Ellipse()
                                    .fill(Color(red: 0.72, green: 0.40, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.20))
                                    .frame(width: 70, height: 32)
                                    .blur(radius: 20)
                                    .offset(x: CGFloat(cos(elapsed * 1.08 + 2.1)) * 42,
                                            y: CGFloat(sin(elapsed * 0.78 + 1.2)) * 21)

                                // Wandering wisp — warm amber
                                Ellipse()
                                    .fill(Color(red: 1.00, green: 0.72, blue: 0.40)
                                        .opacity(diAuraOpacity * 0.14))
                                    .frame(width: 58, height: 28)
                                    .blur(radius: 17)
                                    .offset(x: CGFloat(sin(elapsed * 0.95 + 3.5)) * 38,
                                            y: CGFloat(cos(elapsed * 1.15 + 0.8)) * 19)

                                // Central mid glow
                                Ellipse()
                                    .fill(RadialGradient(
                                        colors: [
                                            Color(red: 0.62, green: 0.44, blue: 1.00).opacity(diAuraOpacity * 0.42),
                                            Color(red: 0.46, green: 0.62, blue: 1.00).opacity(diAuraOpacity * 0.18),
                                            .clear
                                        ],
                                        center: .center, startRadius: 0, endRadius: 90
                                    ))
                                    .frame(
                                        width:  170 + CGFloat(cos(elapsed * 0.95)) * 18,
                                        height:  97 + CGFloat(sin(elapsed * 0.72)) * 11
                                    )
                                    .blur(radius: 28)

                                // Inner cyan bloom
                                Ellipse()
                                    .fill(Color(red: 0.55, green: 0.92, blue: 1.00)
                                        .opacity(diAuraOpacity * 0.56))
                                    .frame(
                                        width:  97 + CGFloat(sin(elapsed * 1.32)) * 10,
                                        height: 58 + CGFloat(cos(elapsed * 1.05)) *  7
                                    )
                                    .blur(radius: 18)

                                // Bright hot core
                                Ellipse()
                                    .fill(.white.opacity(diAuraOpacity * 0.75))
                                    .frame(width: 42, height: 25)
                                    .blur(radius: 7)
                            }
                            .scaleEffect(diAuraScale)
                            .position(x: cx, y: islandY)
                            .blendMode(.plusLighter)
                        }
                    }
                }

                // Impact flash
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            .white.opacity(impactFlashOpacity * 0.96),
                            Color(red: 0.50, green: 0.85, blue: 1.00).opacity(impactFlashOpacity * 0.54),
                            Color(red: 0.58, green: 0.38, blue: 1.00).opacity(impactFlashOpacity * 0.24),
                            .clear
                        ],
                        center: .center, startRadius: 0, endRadius: 95
                    ))
                    .frame(width: 190, height: 190)
                    .blur(radius: 24)
                    .blendMode(.plusLighter)
                    .position(x: cx, y: islandY)
            }
            .onAppear {
                buildParticles(width: geo.size.width, height: geo.size.height)
                animate()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func buildParticles(width: CGFloat, height: CGFloat) {
        let beamLength = (height - 80) - islandY
        var result = [Particle]()
        result.reserveCapacity(2700)

        // — Beam: dense column of tiny balls from text/pill area up to DI —
        for _ in 0..<520 {
            let dy    = CGFloat.random(in: 15...beamLength)
            // Tighter column near DI, wider near pill
            let spr   = (1.0 - dy / beamLength) * 8 + 14
            let dx    = CGFloat.random(in: -spr...spr)
            let speed = CGFloat.random(in: 80...400)
            let col   = randomParticleColor()

            result.append(Particle(
                angle:       -.pi / 2 + Double.random(in: -0.13...0.13),
                speed:       speed,
                delay:       Double.random(in: 0...0.35),
                size:        CGFloat.random(in: 0.2...1.4),   // tiny balls
                brightness:  Double.random(in: 0.5...1.0),
                lifespan:    Double(dy / speed) * 0.97,
                startDX:     dx, startDY: dy, isBeam: true,
                r: col.r, g: col.g, b: col.b,
                flickerRate: Double.random(in: 0...1) < 0.28 ? Double.random(in: 2...9) : 0,
                wobbleFreq:  Double.random(in: 0.5...3.0),
                wobbleAmp:   CGFloat.random(in: 0...5),
                drift:       0
            ))
        }

        // — Explosion wave 1: dense pinpoint burst —
        for _ in 0..<1650 {
            let angle = Double.random(in: 0...(2 * .pi))
            let bias  = pow(Double.random(in: 0...1), 1.6)
            let speed = CGFloat(14 + bias * 610)
            let size: CGFloat = Double.random(in: 0...1) < 0.05
                ? CGFloat.random(in: 2.0...4.5)   // rare accent balls
                : CGFloat.random(in: 0.2...1.2)   // dense tiny balls
            let col = randomParticleColor()

            result.append(Particle(
                angle:       angle,
                speed:       speed,
                delay:       0.42 + Double.random(in: 0...0.08),
                size:        size,
                brightness:  Double.random(in: 0.28...1.00),
                lifespan:    Double.random(in: 0.7...2.5),
                startDX:     0, startDY: 0, isBeam: false,
                r: col.r, g: col.g, b: col.b,
                flickerRate: Double.random(in: 0...1) < 0.22 ? Double.random(in: 1.5...7) : 0,
                wobbleFreq:  0, wobbleAmp: 0,
                drift:       CGFloat.random(in: -18...18)
            ))
        }

        // — Echo wave 2: softer ripple —
        for _ in 0..<380 {
            let angle = Double.random(in: 0...(2 * .pi))
            let bias  = pow(Double.random(in: 0...1), 1.3)
            let speed = CGFloat(30 + bias * 340)
            let echoPalette: [(Double, Double, Double)] = [
                (0.52, 0.87, 1.0), (0.70, 0.60, 1.0),
                (0.36, 0.80, 1.0), (0.85, 0.78, 1.0), (1.0, 1.0, 1.0)
            ]
            let col = echoPalette[Int.random(in: 0..<echoPalette.count)]

            result.append(Particle(
                angle:       angle,
                speed:       speed,
                delay:       0.72 + Double.random(in: 0...0.14),
                size:        CGFloat.random(in: 0.2...1.3),   // tiny
                brightness:  Double.random(in: 0.18...0.68),
                lifespan:    Double.random(in: 1.0...2.4),
                startDX:     0, startDY: 0, isBeam: false,
                r: col.0, g: col.1, b: col.2,
                flickerRate: Double.random(in: 0...1) < 0.32 ? Double.random(in: 2...8) : 0,
                wobbleFreq:  0, wobbleAmp: 0,
                drift:       CGFloat.random(in: -10...10)
            ))
        }

        // — Sparks: large bright flares at impact —
        for _ in 0..<55 {
            let angle = Double.random(in: 0...(2 * .pi))
            let col   = randomParticleColor()
            result.append(Particle(
                angle:       angle,
                speed:       CGFloat.random(in: 140...530),
                delay:       0.42 + Double.random(in: 0...0.05),
                size:        CGFloat.random(in: 2.8...7.0),
                brightness:  Double.random(in: 0.70...1.00),
                lifespan:    Double.random(in: 0.18...0.55),
                startDX:     0, startDY: 0, isBeam: false,
                r: col.r, g: col.g, b: col.b,
                flickerRate: 0, wobbleFreq: 0, wobbleAmp: 0,
                drift:       CGFloat.random(in: -6...6)
            ))
        }

        particles = result
    }

    private func animate() {
        withAnimation(.easeIn(duration: 0.07)) { bgOpacity = 0.97 }
        withAnimation(.easeOut(duration: 0.72).delay(0.10)) { warmGlowOpacity = 1.0 }
        withAnimation(.easeOut(duration: 0.56).delay(0.12)) { coolGlowOpacity = 0.90 }
        withAnimation(.easeOut(duration: 0.62).delay(0.13)) {
            diAuraOpacity = 0.55
            diAuraScale   = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startTime = Date()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.47) {
            withAnimation(.easeOut(duration: 0.12)) { impactFlashOpacity = 1.0 }
            withAnimation(.easeIn(duration: 0.42).delay(0.12)) { impactFlashOpacity = 0 }
            withAnimation(.easeOut(duration: 0.10)) { diAuraOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.52).delay(0.10)) { diAuraOpacity = 0.82 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) {
            withAnimation(.easeOut(duration: 0.88)) {
                diAuraScale   = 3.0
                diAuraOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.62)) { warmGlowOpacity = 0 }
            withAnimation(.easeOut(duration: 0.52)) { coolGlowOpacity  = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.32) {
            withAnimation(.easeOut(duration: 0.46)) { bgOpacity = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.82) {
            onComplete()
        }
    }
}
