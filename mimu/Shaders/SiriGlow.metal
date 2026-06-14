//
//  SiriGlow.metal
//  mimu
//
//  Single-pass fragment shader that replaces the 5-layer SwiftUI
//  SiriGlowView.  Everything — angular gradient, glow falloff,
//  shimmer highlight, corner blooms — is computed analytically
//  per-pixel.  Zero Gaussian blur passes, one draw call.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// ── Helpers ────────────────────────────────────────────────────────────

/// Signed distance to a rounded rectangle centred at the origin.
/// Negative inside, positive outside, zero on the boundary.
static float roundedRectSDF(float2 p, float2 halfSize, float radius) {
    float2 d = abs(p) - halfSize + float2(radius);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

/// Map an angle (radians, 0…2π) to the Siri colour palette.
/// The palette is baked right into the shader so there's no
/// buffer / texture lookup — just a few mix() calls.
static half3 siriColor(float angle) {
    //  0: bright cyan        (0.00, 0.76, 1.00)
    //  1: electric blue       (0.20, 0.40, 1.00)
    //  2: deep violet         (0.55, 0.10, 1.00)
    //  3: hot pink-purple     (0.90, 0.20, 0.80)
    //  4: coral pink          (1.00, 0.40, 0.60)
    //  5: sky blue            (0.40, 0.85, 1.00)
    //  → wraps back to 0 (bright cyan)

    constexpr half3 palette[7] = {
        half3(0.00h, 0.76h, 1.00h),
        half3(0.20h, 0.40h, 1.00h),
        half3(0.55h, 0.10h, 1.00h),
        half3(0.90h, 0.20h, 0.80h),
        half3(1.00h, 0.40h, 0.60h),
        half3(0.40h, 0.85h, 1.00h),
        half3(0.00h, 0.76h, 1.00h),   // wrap
    };

    float t = fract(angle / (2.0 * M_PI_F)) * 6.0;   // 0…6
    int   i = int(t);                                  // segment index
    float f = t - float(i);                            // fraction inside segment
    i = clamp(i, 0, 5);
    return mix(palette[i], palette[i + 1], half(f));
}

// ── Main shader ────────────────────────────────────────────────────────

/// SwiftUI .colorEffect() entry point.
///
/// @param position  pixel coordinate in user space
/// @param color     source colour of the underlying Rectangle (ignored)
/// @param time      elapsed seconds since glow started
/// @param opacity   0 → 1 fade controlled by SwiftUI animation
/// @param size      view size (width, height)
/// @param corner    corner radius of the device (e.g. 47)
/// @param pulse     pulse scale factor (≈ 1.0 … 1.08)
[[ stitchable ]] half4 siriGlow(
    float2 position,
    half4  color,
    float  time,
    float  opacity,
    float2 size,
    float  corner,
    float  pulse
) {
    // Centre-relative coordinates
    float2 centre = size * 0.5;
    float2 p = position - centre;

    // SDF distance to the rounded-rect border
    float dist = roundedRectSDF(p, centre, corner);

    // ── Glow envelope ──────────────────────────────────────────────
    // Three concentric analytical "glow rings".
    //
    //   Layer 1 (wide halo):   σ ≈ 44,  weight 0.70
    //   Layer 2 (mid ring):    σ ≈ 22,  weight 0.90
    //   Layer 3 (crisp edge):  σ ≈ 6,   weight 1.00

    float g1 = exp(-0.5 * (dist * dist) / (44.0 * 44.0)) * 0.70;
    float g2 = exp(-0.5 * (dist * dist) / (22.0 * 22.0)) * 0.90;
    float g3 = exp(-0.5 * (dist * dist) / (6.0  * 6.0 )) * 1.00;
    float glow = g1 + g2 + g3;

    // ── Angular gradient ───────────────────────────────────────────
    // Revolution period = 3 s.  Each layer is offset (0°, 30°, 60°).
    float baseAngle = atan2(p.y, p.x) + M_PI_F;   // 0…2π
    float revolution = 2.0 * M_PI_F;

    float rotBase = fmod(time / 3.0, 1.0) * revolution;
    float rot1 = rotBase;
    float rot2 = rotBase + (M_PI_F / 6.0);   // 30°
    float rot3 = rotBase + (M_PI_F / 3.0);   // 60°

    half3 c1 = siriColor(baseAngle + rot1) * half(g1);
    half3 c2 = siriColor(baseAngle + rot2) * half(g2);
    half3 c3 = siriColor(baseAngle + rot3) * half(g3);

    half3 rgb = c1 + c2 + c3;

    // ── Shimmer highlight (1.6× speed) ─────────────────────────────
    float shimmerAngle = baseAngle + fmod(time / (3.0 / 1.6), 1.0) * revolution;
    // Two bright spokes + two dark gaps
    float shimmer = pow(max(cos(shimmerAngle * 2.0), 0.0), 4.0);
    // Visible across a wider band around the border
    float shimmerMask = exp(-0.5 * (dist * dist) / (6.0 * 6.0));
    rgb += half3(shimmer * shimmerMask * 0.7);

    // ── Corner bloom hotspots ──────────────────────────────────────
    // Arc centre of each rounded corner sits at (corner, corner) from the edge.
    float2 corners[4] = {
        float2(corner,            corner),
        float2(size.x - corner,   corner),
        float2(corner,            size.y - corner),
        float2(size.x - corner,   size.y - corner),
    };

    for (int i = 0; i < 4; i++) {
        float d = length(position - corners[i]);
        float bloom = exp(-d * d / (80.0 * 80.0));   // endRadius ≈ 80
        half3 bloomColor = mix(
            half3(0.40h, 0.70h, 1.00h),              // sky-blue centre
            half3(0.60h, 0.20h, 1.00h),               // violet edge
            half(saturate(d / 80.0))
        );
        rgb += bloomColor * half(bloom * 0.65 * pulse);
    }

    // ── Final composite (pre-multiplied alpha) ─────────────────────
    half  a = half(saturate(glow * opacity));
    // Mask out interior pixels so the glow never tints content behind it.
    // Wider transition to accommodate the thicker glow bands.
    float interiorMask = smoothstep(-20.0, -3.0, dist);
    a *= half(interiorMask);
    rgb *= half(opacity) * half(interiorMask);

    return half4(rgb, a);
}
