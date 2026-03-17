#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Beam shader for Apple Pay-style animation
[[ stitchable ]] half4 beamShader(
    float2 position,
    half4 color,
    float2 size,
    float progress,
    float intensity
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 1.0);
    
    // Distance from center line
    float distFromCenter = abs(uv.x - 0.5);
    
    // Vertical gradient
    float verticalGradient = smoothstep(1.0, 0.0, uv.y);
    
    // Core beam (tight, bright)
    float coreBeam = smoothstep(0.002, 0.0, distFromCenter) * verticalGradient;
    
    // Mid glow (medium width)
    float midGlow = smoothstep(0.01, 0.0, distFromCenter) * verticalGradient * 0.6;
    
    // Outer glow (wide, soft)
    float outerGlow = smoothstep(0.05, 0.0, distFromCenter) * verticalGradient * 0.3;
    
    // Combine layers
    float beam = coreBeam + midGlow + outerGlow;
    beam *= intensity * progress;
    
    // Color: white core, blue-white glow
    half3 beamColor = mix(
        half3(0.5, 0.8, 1.0),  // Blue-white
        half3(1.0, 1.0, 1.0),  // Pure white
        half(coreBeam)
    );
    
    return half4(beamColor * half(beam), half(beam));
}

// Glow ring shader
[[ stitchable ]] half4 ringShader(
    float2 position,
    half4 color,
    float2 size,
    float radius,
    float thickness,
    float intensity
) {
    float2 center = size / 2.0;
    float dist = distance(position, center);
    
    // Ring shape
    float ring = smoothstep(thickness, 0.0, abs(dist - radius));
    ring *= intensity;
    
    // Gradient from white to blue
    half3 ringColor = mix(
        half3(0.6, 0.85, 1.0),
        half3(1.0, 1.0, 1.0),
        half(ring)
    );
    
    return half4(ringColor * half(ring), half(ring));
}
