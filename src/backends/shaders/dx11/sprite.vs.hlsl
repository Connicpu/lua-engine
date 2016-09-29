struct VSInput
{
    float2 pos : POSITION;
    float2 tex : TEXCOORD0;

    float2 transform0 : TRANSFORM0;
    float2 transform1 : TRANSFORM1;
    float2 transform2 : TRANSFORM2;
    float4 tint : COLOR;
    float2 uv0 : TEXCOORD1;
    float2 uv1 : TEXCOORD2;
    float layer : LAYER;
    uint texture_id : TEXTURE_ID;
};

struct VSOutput
{
    float4 pos : SV_POSITION;
    float4 tint : COLOR;
    float2 tex : TEXCOORD0;
    uint texture_id : TEXTURE_ID;
};

cbuffer Camera : register(b0)
{
    float2 camera0;
    float2 camera1;
    float2 camera2;
};

inline float3x3 affine2d(float2 row1, float2 row2, float2 row3)
{
    return float3x3(
        float3(row1.x, row2.x, row3.x),
        float3(row1.y, row2.y, row3.y),
        float3(0, 0, 1)
        );
}

VSOutput main(VSInput input)
{
    float3x3 world = affine2d(input.transform0, input.transform1, input.transform2);
    float3x3 view = affine2d(camera0, camera1, camera2);
    VSOutput output;

    float3 pos = mul(mul(float3(input.pos, 1), world), view);

    output.pos = float4(pos.xy, pos.z / 2000 + 0.5, 1);
    output.tint = input.tint;
    output.tex = lerp(input.uv0, input.uv1, input.tex);
    output.texture_id = input.texture_id;

    return output;
}

