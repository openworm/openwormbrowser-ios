#include <metal_stdlib>
using namespace metal;

struct MetalVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct Uniforms {
    float4x4 mvp;
    float4 color;
    float3 lightDir;
    float ambient;
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};

vertex VertexOut lighting_vertex(const device MetalVertex *verts [[buffer(0)]],
                                 constant Uniforms &uni [[buffer(1)]],
                                 uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = uni.mvp * float4(verts[vid].position, 1.0);
    out.normal = verts[vid].normal;
    return out;
}

fragment float4 lighting_fragment(VertexOut in [[stage_in]],
                                  constant Uniforms &uni [[buffer(1)]]) {
    float diff = max(dot(normalize(in.normal), normalize(uni.lightDir)), 0.0);
    return float4(uni.color.rgb * (diff + uni.ambient), uni.color.a);
}

vertex float4 picking_vertex(const device MetalVertex *verts [[buffer(0)]],
                             constant Uniforms &uni [[buffer(1)]],
                             uint vid [[vertex_id]]) {
    return uni.mvp * float4(verts[vid].position, 1.0);
}

fragment float4 picking_fragment(constant Uniforms &uni [[buffer(1)]]) {
    return uni.color;
}
