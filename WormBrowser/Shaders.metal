#include <metal_stdlib>
using namespace metal;

struct MetalVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

vertex float4 basic_vertex(const device MetalVertex *verts [[buffer(0)]],
                           uint vid [[vertex_id]]) {
    return float4(verts[vid].position, 1.0);
}

fragment float4 basic_fragment() {
    return float4(0.2, 0.6, 0.9, 1.0);
}
