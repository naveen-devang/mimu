import SwiftUI

// MARK: - Apple Pay Style Beam Animation
struct ApplePayBeamView: View {
    var onComplete: () -> Void
    
    @State private var beamProgress: Double = 0
    @State private var beamIntensity: Double = 0
    @State private var bgOpacity: Double = 0
    
    @State private var islandWidth: CGFloat = 126
    @State private var islandHeight: CGFloat = 37.33
    @State private var islandOpacity: Double = 0
    @State private var islandGlowOpacity: Double = 0
    
    @State private var ring1Scale: CGFloat = 0.5
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring2Opacity: Double = 0
    @State private var ring3Scale: CGFloat = 0.5
    @State private var ring3Opacity: Double = 0
    @State private var ring4Scale: CGFloat = 0.5
    @State private var ring4Opacity: Double = 0
    
    @State private var flashOpacity: Double = 0
    @State private var flashScale: CGFloat = 0.5
    
    @State private var beamGlowOpacity: Double = 0
    
    @State private var safeAreaTop: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background GeometryReader to capture safe area (DOES NOT ignore safe area)
            GeometryReader { geo in
                Color.clear
                    .preference(key: SafeAreaTopPreferenceKey.self, value: geo.safeAreaInsets.top)
            }
            .onPreferenceChange(SafeAreaTopPreferenceKey.self) { value in
                safeAreaTop = value
            }
            
            // Main animation content (ignores safe area for full screen)
            animationContent
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .onAppear { animate() }
    }
    
    private var animationContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let centerX = width / 2
            
            // Dynamic Island center position
            // The hardware cutout center is at approximately 18.5pt from the physical top
            // This is consistent across all Dynamic Island devices (iPhone 14 Pro - 17 Pro Max)
            let islandY: CGFloat = 18.5
            
            let beamBottom = height - 80
            let beamHeight = beamBottom - islandY
            
            ZStack {
                // Background
                Color.black
                    .opacity(bgOpacity)
                    .ignoresSafeArea()
                
                // BEAM - Multi-layered for ultra-smooth appearance
                ZStack {
                    // Layer 5: Ultra-wide ambient glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 0.95).opacity(beamGlowOpacity * 0.15),
                                    Color(red: 0.3, green: 0.6, blue: 0.9).opacity(beamGlowOpacity * 0.08),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 120, height: beamHeight * beamProgress)
                        .blur(radius: 40)
                    
                    // Layer 4: Wide soft glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.8, blue: 1.0).opacity(beamIntensity * 0.35),
                                    Color(red: 0.45, green: 0.75, blue: 0.98).opacity(beamIntensity * 0.18),
                                    Color(red: 0.4, green: 0.7, blue: 0.95).opacity(beamIntensity * 0.08),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 70, height: beamHeight * beamProgress)
                        .blur(radius: 28)
                    
                    // Layer 3: Medium glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.88, blue: 1.0).opacity(beamIntensity * 0.6),
                                    Color(red: 0.6, green: 0.85, blue: 1.0).opacity(beamIntensity * 0.4),
                                    Color(red: 0.55, green: 0.8, blue: 0.98).opacity(beamIntensity * 0.2),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 35, height: beamHeight * beamProgress)
                        .blur(radius: 15)
                    
                    // Layer 2: Bright inner glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.95, blue: 1.0).opacity(beamIntensity * 0.85),
                                    Color(red: 0.8, green: 0.92, blue: 1.0).opacity(beamIntensity * 0.6),
                                    Color(red: 0.7, green: 0.88, blue: 1.0).opacity(beamIntensity * 0.3),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 18, height: beamHeight * beamProgress)
                        .blur(radius: 6)
                    
                    // Layer 1: Core beam (pure white)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(beamIntensity * 0.95),
                                    .white.opacity(beamIntensity * 0.85),
                                    .white.opacity(beamIntensity * 0.5),
                                    .white.opacity(beamIntensity * 0.15),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 4, height: beamHeight * beamProgress)
                        .blur(radius: 0.5)
                }
                .position(x: centerX, y: beamBottom - (beamHeight * beamProgress) / 2)
                .blendMode(.plusLighter)
                .drawingGroup()
                
                // Glow rings around Dynamic Island (4 rings for smoother effect)
                ZStack {
                    // Ring 1 (innermost, brightest)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(ring1Opacity),
                                    Color(red: 0.7, green: 0.9, blue: 1.0).opacity(ring1Opacity * 0.7),
                                    Color(red: 0.6, green: 0.85, blue: 1.0).opacity(ring1Opacity * 0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(ring1Scale)
                        .blur(radius: 1.5)
                    
                    // Ring 2
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(ring2Opacity * 0.8),
                                    Color(red: 0.65, green: 0.88, blue: 1.0).opacity(ring2Opacity * 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(ring2Scale)
                        .blur(radius: 2.5)
                    
                    // Ring 3
                    Circle()
                        .stroke(
                            Color.white.opacity(ring3Opacity * 0.5),
                            lineWidth: 2
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(ring3Scale)
                        .blur(radius: 3.5)
                    
                    // Ring 4 (outermost, softest)
                    Circle()
                        .stroke(
                            Color.white.opacity(ring4Opacity * 0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(ring4Scale)
                        .blur(radius: 5)
                }
                .position(x: centerX, y: islandY)
                .blendMode(.plusLighter)
                .drawingGroup()
                
                // Flash effect (brighter and more dramatic)
                ZStack {
                    // Outer flash
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.95, blue: 1.0).opacity(flashOpacity * 0.6),
                                    Color(red: 0.7, green: 0.85, blue: 1.0).opacity(flashOpacity * 0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(flashScale)
                        .blur(radius: 35)
                    
                    // Inner flash (bright white)
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(flashOpacity),
                                    .white.opacity(flashOpacity * 0.7),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(flashScale)
                        .blur(radius: 20)
                }
                .position(x: centerX, y: islandY)
                .blendMode(.plusLighter)
                .drawingGroup()
                
                // Dynamic Island outer glow
                RoundedRectangle(cornerRadius: islandHeight / 2, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(islandGlowOpacity * 0.4),
                                Color(red: 0.7, green: 0.9, blue: 1.0).opacity(islandGlowOpacity * 0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: islandWidth * 0.6
                        )
                    )
                    .frame(width: islandWidth + 40, height: islandHeight + 40)
                    .blur(radius: 20)
                    .opacity(islandOpacity)
                    .position(x: centerX, y: islandY)
                
                // Dynamic Island
                RoundedRectangle(cornerRadius: islandHeight / 2, style: .continuous)
                    .fill(.white)
                    .frame(width: islandWidth, height: islandHeight)
                    .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                    .opacity(islandOpacity)
                    .position(x: centerX, y: islandY)
                
                // Island inner highlight
                RoundedRectangle(cornerRadius: islandHeight / 2, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(islandOpacity * 0.6),
                                .white.opacity(islandOpacity * 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: islandWidth - 2, height: islandHeight - 2)
                    .blur(radius: 1)
                    .opacity(islandOpacity)
                    .position(x: centerX, y: islandY)
            }
        }
    }
    
    private func animate() {
        // Background fade in (faster, darker)
        withAnimation(.easeIn(duration: 0.08)) {
            bgOpacity = 0.98
        }
        
        // Beam ambient glow starts immediately
        withAnimation(.easeOut(duration: 0.15)) {
            beamGlowOpacity = 1.0
        }
        
        // Beam shoots up with ease-in curve (Apple's signature)
        withAnimation(.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.5)) {
            beamProgress = 1.0
        }
        
        withAnimation(.timingCurve(0.3, 0.0, 0.7, 1.0, duration: 0.5)) {
            beamIntensity = 1.0
        }
        
        // Island appears and expands at 0.42s (right when beam arrives)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            islandOpacity = 1.0
            
            // Dramatic expansion with custom spring
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 180, damping: 18, initialVelocity: 0)) {
                islandWidth = 320
                islandHeight = 70
            }
            
            withAnimation(.easeOut(duration: 0.15)) {
                islandGlowOpacity = 1.0
            }
            
            // Bright flash
            withAnimation(.easeOut(duration: 0.1)) {
                flashOpacity = 1.0
                flashScale = 1.5
            }
            withAnimation(.easeIn(duration: 0.15).delay(0.1)) {
                flashOpacity = 0
            }
            
            // Ring 1 (fastest, innermost)
            withAnimation(.timingCurve(0.2, 0.0, 0.4, 1.0, duration: 0.4)) {
                ring1Scale = 2.8
                ring1Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.22)) {
                ring1Opacity = 0
            }
            
            // Ring 2
            withAnimation(.timingCurve(0.2, 0.0, 0.4, 1.0, duration: 0.5).delay(0.03)) {
                ring2Scale = 3.2
                ring2Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.25).delay(0.28)) {
                ring2Opacity = 0
            }
            
            // Ring 3
            withAnimation(.timingCurve(0.2, 0.0, 0.4, 1.0, duration: 0.6).delay(0.06)) {
                ring3Scale = 3.6
                ring3Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.34)) {
                ring3Opacity = 0
            }
            
            // Ring 4 (slowest, outermost)
            withAnimation(.timingCurve(0.2, 0.0, 0.4, 1.0, duration: 0.7).delay(0.09)) {
                ring4Scale = 4.0
                ring4Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.4)) {
                ring4Opacity = 0
            }
        }
        
        // Contract back at 0.62s (Apple's bounce-back)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 20, initialVelocity: 0)) {
                islandWidth = 126
                islandHeight = 37.33
            }
            
            withAnimation(.easeIn(duration: 0.2)) {
                islandGlowOpacity = 0
            }
        }
        
        // Fade beam at 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                beamIntensity = 0
                beamGlowOpacity = 0
            }
        }
        
        // Fade everything at 0.95s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeOut(duration: 0.22)) {
                islandOpacity = 0
                bgOpacity = 0
            }
        }
        
        // Complete at 1.2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
        }
    }
}

// Preference key for safe area
struct SafeAreaTopPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
