Shader "Custom/StylizedCloudCookieGenerator"
{
    Properties
    {
        _NoiseTex ("Perlin Noise", 2D) = "gray" {}
        _ScaleA ("Primary Noise Scale", Float) = 1.15
        _ScaleB ("Secondary Noise Scale", Float) = 2.35
        _SpeedA ("Primary Speed XY", Vector) = (0.015, 0.008, 0, 0)
        _SpeedB ("Secondary Speed XY", Vector) = (-0.008, 0.012, 0, 0)
        _SecondaryBlend ("Secondary Blend", Range(0, 1)) = 0.35
        _WarpStrength ("Warp Strength", Range(0, 0.5)) = 0.10

        _Threshold ("Cloud Threshold", Range(0, 1)) = 0.52
        _Softness ("Edge Softness", Range(0.001, 0.35)) = 0.075
        _Contrast ("Cloud Contrast", Range(0.25, 4)) = 1.15
        [Toggle] _InvertNoise ("Invert Noise", Float) = 0

        _DissolveAmount ("Gather Scatter Amount", Range(0, 0.35)) = 0.09
        _DissolveSpeed ("Gather Scatter Speed", Range(0, 1)) = 0.04
        _ShadowStrength ("Shadow Strength", Range(0, 0.95)) = 0.45
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            sampler2D _NoiseTex;
            float _ScaleA;
            float _ScaleB;
            float4 _SpeedA;
            float4 _SpeedB;
            float _SecondaryBlend;
            float _WarpStrength;

            float _Threshold;
            float _Softness;
            float _Contrast;
            float _InvertNoise;

            float _DissolveAmount;
            float _DissolveSpeed;
            float _ShadowStrength;
            float _CloudTime;

            float SampleNoise(float2 uv)
            {
                return tex2D(_NoiseTex, frac(uv)).r;
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float t = _CloudTime;
                float2 uv = i.uv;

                // Large, slowly moving cloud body.
                float2 uvA = uv * max(_ScaleA, 0.001) + _SpeedA.xy * t;
                float nA = SampleNoise(uvA);

                // A second layer moves in another direction and also warps itself.
                // This prevents the cloud shadow from looking like a static texture sliding over the world.
                float warpNoise = SampleNoise(
                    uv * max(_ScaleA * 0.63, 0.001) +
                    _SpeedB.xy * t * 0.37 +
                    float2(13.17, 27.41)
                );

                float2 warpDir = float2(warpNoise - 0.5, SampleNoise(uvA + 19.73) - 0.5);
                float2 uvB = uv * max(_ScaleB, 0.001) + _SpeedB.xy * t + warpDir * _WarpStrength;
                float nB = SampleNoise(uvB);

                float n = lerp(nA, nB, saturate(_SecondaryBlend));

                // Contrast around the midpoint before thresholding.
                n = saturate((n - 0.5) * _Contrast + 0.5);
                n = lerp(n, 1.0 - n, saturate(_InvertNoise));

                // Slowly vary the threshold to make cloud masses gather and disperse.
                float thresholdWave = sin(t * _DissolveSpeed * 6.28318530718);
                float animatedThreshold = saturate(_Threshold + thresholdWave * _DissolveAmount);

                float soft = max(_Softness, 0.0001);
                float cloud = smoothstep(animatedThreshold - soft, animatedThreshold + soft, n);

                // Light cookies are transmission masks: white = full light, black = blocked light.
                // Keep the minimum above black for a soft stylized cloud shadow.
                float transmission = saturate(1.0 - cloud * _ShadowStrength);

                return fixed4(transmission, transmission, transmission, 1.0);
            }
            ENDCG
        }
    }

    FallBack Off
}
