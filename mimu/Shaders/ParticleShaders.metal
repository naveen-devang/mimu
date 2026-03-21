#include <metal_stdlib>
using namespace metal;

struct ParticleIn {
    float startDX;
    float startDY;
    float r;
    float g;
    float b;
    float angle;
    float speed;
    float delay;
    float lifespan;
    float size;
    float brightness;
    float isBeam;
    float flickerRate;
    float wobbleFreq;
    float wobbleAmp;
    float drift;
};

struct Uniforms {
    float elapsedTime;
    float cx;
    float cy;
    float islandY;
    float screenScale;
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
    float coreSize;
};

[[vertex]]
VertexOut particleVertex(
    const device ParticleIn *particles [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(1)]],
    uint vid [[vertex_id]]
) {
    ParticleIn p = particles[vid];
    float t = uniforms.elapsedTime - p.delay;
    
    VertexOut out;
    out.position = float4(0, 0, -2, 1);
    out.pointSize = 0;
    out.color = float4(0);
    out.coreSize = 1.0;
    
    if (t > 0 && t <= p.lifespan) {
        float progress = t / p.lifespan;
        float fadeIn = min(t / (p.lifespan * 0.08), 1.0);
        float fadeOut = (progress > 0.42) ? max(0.0, 1.0 - (progress - 0.42) / 0.58) : 1.0;
        
        float flicker = 1.0;
        if (p.flickerRate > 0) {
            flicker = 0.68 + 0.32 * sin(uniforms.elapsedTime * p.flickerRate * 2.0 * 3.14159265);
        }
        
        float opacity = p.brightness * fadeIn * fadeOut * flicker;
        if (opacity > 0.01) {
            float dist = p.speed * t;
            float px;
            float py;
            
            if (p.isBeam > 0.5) {
                float wobble = p.wobbleAmp * sin(uniforms.elapsedTime * p.wobbleFreq * 2.0 * 3.14159265);
                px = uniforms.cx + p.startDX + wobble + dist * cos(p.angle) * 0.18;
                py = uniforms.islandY + p.startDY + dist * sin(p.angle);
            } else {
                float perp = p.angle + 3.14159265 / 2.0;
                px = uniforms.cx + dist * cos(p.angle) + p.drift * (t * t) * cos(perp);
                py = uniforms.islandY + dist * sin(p.angle) + p.drift * (t * t) * sin(perp);
            }
            
            float ndcX = (px / uniforms.cx) - 1.0;
            float ndcY = 1.0 - (py / uniforms.cy); 
            
            out.position = float4(ndcX, ndcY, 0, 1);
            
            float coreRadius = p.size / 2.0;
            if (p.size >= 1.0) {
                float haloRadius = coreRadius * 2.2;
                out.pointSize = haloRadius * 2.0 * uniforms.screenScale; 
                out.coreSize = coreRadius / haloRadius;
            } else {
                out.pointSize = p.size * uniforms.screenScale;
                out.coreSize = 1.0;
            }
            
            out.color = float4(p.r, p.g, p.b, opacity);
        }
    }
    return out;
}

[[fragment]]
float4 particleFragment(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float dist = distance(pointCoord, float2(0.5, 0.5));
    float coreRadius = in.coreSize * 0.5;
    
    // Smooth anti-aliased edge instead of hard step
    float pixelWidth = 1.0 / in.pointSize;
    float coreAlpha = (1.0 - smoothstep(coreRadius - pixelWidth, coreRadius + pixelWidth, dist)) * in.color.a;
    
    float haloAlpha = 0.0;
    if (in.coreSize < 1.0) {
        float inHalo = smoothstep(0.5, 0.5 - pixelWidth, dist) * smoothstep(coreRadius, coreRadius + pixelWidth, dist);
        haloAlpha = inHalo * (in.color.a * 0.28);
    }
    
    float finalAlpha = max(coreAlpha, haloAlpha);
    if (finalAlpha < 0.001) {
        discard_fragment();
    }
    
    return float4(in.color.rgb * finalAlpha, finalAlpha);
}
