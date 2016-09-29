Texture2DArray spriteSheet : register(t0);
SamplerState spriteSampler : register(s0);

struct VSOutput
{
    float4 pos : SV_POSITION;
    float4 tint : COLOR;
    float2 tex : TEXCOORD0;
    uint texture_id : TEXTURE_ID;
};

float4 main(VSOutput input) : SV_TARGET
{
    return spriteSheet.Sample(spriteSampler, float3(input.tex, input.texture_id)) * input.tint;
}

