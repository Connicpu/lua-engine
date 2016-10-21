#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

using namespace metal;

struct Uniforms
{
    float2x3 camera;
};

struct SpriteVertex
{
    float2 pos;
    float2 tex;
};

struct SpriteInstance
{
    float2x3 transform;
    float4 tint;
    float2 uv0;
    float2 uv1;
    float layer;
    uint texture_id;
};

struct VertexOut
{
    float4 position [[position]];
    half4 tint;
    float2 texcoord [[user(texcoord)]];
    uint tex_id;
};

float3x3 Affine2D(constant float2x3 m)
{
    return float3x3(
        float3(m[0], 0),
        float3(m[1], 0),
        float3(m[2], 1)
    );
}

vertex VertexOut SpriteVertex(constant SpriteVertex *vertices [[buffer(0)]],
                              constant SpriteInstance *instances [[buffer(1)]],
                              constant Uniforms *uniforms [[buffer(2)]],
                              uint vert_id [[vertex_id]],
                              uint inst_id [[instance_id]])
{
    float3 pos = float3(vertices[vert_id].pos, 1);
    float2 tcoord = vertices[vert_id].tex;
    float3x3 camera = Affine2D(uniforms->camera);
    float3x3 transform = Affine2D(instances[inst_id].transform);
    pos = camera * (transform * pos);

    float2 uv0 = instances[inst_id].uv0;
    float2 uv1 = instances[inst_id].uv1;
    tcoord = uv0 * tcoord + uv1 * (1 - tcoord);

    VertexOut vert;
    vert.position = float4(pos.xy, pos.z / 2000 + 0.5, 1);
    vert.tint = half4(instances[inst_id].tint);
    vert.texcoord = tcoord;
    vert.tex_id = instances[inst_id].texture_id;
    return vert;
}

fragment half4 SpriteFragment(VertexOut inFrag [[stage_in]],
                              texture2d_array<half> tex2D [[texture(0)]])
{
    constexpr sampler quad_sampler(coord::normalized, address::repeat, filter::linear);
    half4 color = tex2D.sample(quad_sampler, inFrag.texcoord, inFrag.tex_id);
    color *= inFrag.tint;
    return color;
}

fragment half4 SpritePixelFragment(VertexOut inFrag [[stage_in]],
                                   texture2d_array<half> tex2D [[texture(0)]])
{
    constexpr sampler quad_sampler(coord::normalized, address::repeat, filter::nearest);
    half4 color = tex2D.sample(quad_sampler, inFrag.texcoord, inFrag.tex_id);
    color *= inFrag.tint;
    return color;
}
