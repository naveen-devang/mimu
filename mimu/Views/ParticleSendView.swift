import SwiftUI
import UIKit

// MARK: - Particle Send View (Apple Pay Style)
struct ParticleSendView: View {
    var onComplete: () -> Void

    // Animation states
    @State private var progress: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var isDone = false
    
    // Beam states
    @State private var beamOpacity: Double = 0
    @State private var beamHeight: CGFloat = 0
    @State private var beamGlow: Double = 0
    
    // Dynamic Island states
    @State private var islandWidth: CGFloat = 126
    @State private var islandHeight: CGFloat = 37
    @State private var islandOpacity: Double = 0
    @State private var islandScale: CGFloat = 1.0
    
    // Glow rings
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring2Opacity: Double = 0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var ring3Opacity: Double = 0
    
    // Flash effect
    @State private var flashOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            let centerX = screenWidth / 2
            
            // Dynamic Island hardware position (fixed across all DI devices)
            let islandY: CGFloat = 18.5
            
            let beamStartY = screenHeight - 100
            
            ZStack {
                // Black background
                Color.black
                    .opacity(bgOpacity)
                    .ignoresSafeArea()
                
                // BEAM EFFECT - Single focused ray
                ZStack {
                    // Core beam (bright white)
                    LinearGradient(
                        colors: [
                            .white.opacity(beamOpacity),
                            .white.opacity(beamOpacity * 0.9),
                            .white.opacity(beamOpacity * 0.3),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(width: 4, height: beamHeight)
                    .blur(radius: 1)
                    
                    // Mid glow (blue-white)
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.9, blue: 1.0).opacity(beamOpacity * 0.8),
                            Color(red: 0.6, green: 0.85, blue: 1.0).opacity(beamOpacity * 0.5),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(width: 12, height: beamHeight)
                    .blur(radius: 4)
                    
                    // Outer glow (soft blue)
                    LinearGradient(
                        colors: [
                            Color(red: 0.5, green: 0.8, blue: 1.0).opacity(beamGlow * 0.6),
                            Color(red: 0.4, green: 0.7, blue: 1.0).opacity(beamGlow * 0.3),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(width: 40, height: beamHeight)
                    .blur(radius: 20)
                }
                .position(x: centerX, y: beamStartY - beamHeight / 2)
                
                // Glow rings around Dynamic Island
                ZStack {
                    // Ring 1 (innermost)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(ring1Opacity * 0.8),
                                    Color(red: 0.6, green: 0.85, blue: 1.0).opacity(ring1Opacity * 0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(ring1Scale)
                        .blur(radius: 2)
                    
                    // Ring 2 (middle)
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(ring2Opacity * 0.5),
                            lineWidth: 1.5
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(ring2Scale)
                        .blur(radius: 3)
                    
                    // Ring 3 (outermost)
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(ring3Opacity * 0.3),
                            lineWidth: 1
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(ring3Scale)
                        .blur(radius: 4)
                }
                .position(x: centerX, y: islandY)
                
                // White flash
                RoundedRectangle(cornerRadius: islandHeight / 2, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white, .white.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: islandWidth * 1.5, height: islandHeight * 1.5)
                    .blur(radius: 30)
                    .opacity(flashOpacity)
                    .position(x: centerX, y: islandY)
                
                // Dynamic Island pill
                RoundedRectangle(cornerRadius: islandHeight / 2, style: .continuous)
                    .fill(.white)
                    .frame(width: islandWidth, height: islandHeight)
                    .scaleEffect(islandScale)
                    .opacity(islandOpacity)
                    .position(x: centerX, y: islandY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        // Fade in background
        withAnimation(.easeIn(duration: 0.15)) {
            bgOpacity = 0.95
        }
        
        // Phase 1: Beam shoots up (0.0 - 0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            beamHeight = UIScreen.main.bounds.height
            beamOpacity = 1.0
            beamGlow = 1.0
        }
        
        // Phase 2: Dynamic Island appears and expands (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            islandOpacity = 1.0
            
            // Expand dramatically
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                islandWidth = 280
                islandHeight = 60
            }
            
            // Flash
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.15)) {
                flashOpacity = 0
            }
            
            // Rings expand
            withAnimation(.easeOut(duration: 0.5)) {
                ring1Scale = 2.5
                ring1Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
                ring1Opacity = 0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.05)) {
                ring2Scale = 2.8
                ring2Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.35)) {
                ring2Opacity = 0
            }
            
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                ring3Scale = 3.0
                ring3Opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                ring3Opacity = 0
            }
        }
        
        // Phase 3: Contract back (0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                islandWidth = 126
                islandHeight = 37
            }
        }
        
        // Phase 4: Fade beam (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                beamOpacity = 0
                beamGlow = 0
            }
        }
        
        // Phase 5: Fade everything out (1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                islandOpacity = 0
                bgOpacity = 0
            }
        }
        
        // Complete (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isDone = true
            onComplete()
        }
    }
}
