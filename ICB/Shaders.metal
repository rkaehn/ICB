#include <metal_stdlib>
using namespace metal;

constant float2 quad_pos[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct vertex_out {
    float4 position [[position]];
};

vertex vertex_out main_vertex(ushort vid [[vertex_id]]) {
    vertex_out out;
    out.position = float4(quad_pos[vid], 0, 1);
    return out;
}

fragment half main_fragment(constant float& color [[buffer(0)]]) {
    return half(color);
}
