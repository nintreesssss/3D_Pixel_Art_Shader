#ifndef OUTLINE_INCLUDED
#define OUTLINE_INCLUDED

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_CameraNormalsTexture);
SAMPLER(sampler_CameraNormalsTexture);

float GetDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).x;
}

float3 GetNormal(float2 uv)
{
    float3 worldNormal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uv).xyz;
    return mul((float3x3) UNITY_MATRIX_V, worldNormal) * 2.0 - 1.0;
}

float4 _CameraNormalsTexture_TexelSize;
void Outline_float(float2 uv, float2 DepthThreshold, float NormalsThreshold, float3 NormalEdgeBias, float DepthEdgeStrength, float NormalEdgeStrength, out float Outline)
{
    float2 texelSize = _CameraNormalsTexture_TexelSize.xy;

    float depth = GetDepth(uv);
    float3 normal = GetNormal(uv);

    float2 uvs[4];

    uvs[0] = uv + float2(0.0,texelSize.y); //上
    uvs[1] = uv - float2(0.0,texelSize.y); //下
    uvs[2] = uv + float2(texelSize.x,0.0); //右
    uvs[3] = uv - float2(texelSize.x,0.0); //左

    //计算深度边缘
    float depths[4];
    float depthDifference = 0.0; //深度差值

    [unroll]
    for (int i = 0; i < 4; i++)
    {
        depths[i] = GetDepth(uvs[i]);
        depthDifference += depth - depths[i];
    }
    float depthEdge = step(DepthThreshold, depthDifference); //如果深度差值大于阈值，则为1，否则为0

    //计算法线边缘
    float3 normals[4];
    float dotSum = 0.0;

    [unroll]
    for (int i = 0; i < 4; i++)
    {
        normals[i] = GetNormal(uvs[i]);
        float3 normalDiff = normal - normals[i]; //当前法线差值向量

        float normalBiasDiff = dot(normalDiff, NormalEdgeBias); //判断法线变化方向是否顺着偏置方向
        float normalIndicator = smoothstep(-.01,.01,normalBiasDiff);

        dotSum += dot(normalDiff, normalDiff) * normalIndicator;
    }
    float indicator = sqrt(dotSum);
    float normalEdge = step(NormalsThreshold, indicator);

    Outline = depthDifference < 0 ? 0 : (depthEdge > 0.0 ? (DepthEdgeStrength * depthEdge) : (NormalEdgeStrength * normalEdge));
}
#endif
