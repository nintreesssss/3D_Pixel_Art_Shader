Shader "Custom/URP/CartoonEnergySphere"
{
    Properties
    {
        [Header(Colors and Transparency)]
        [HDR] _BaseColor("Base Color", Color) = (0.035, 0.22, 0.55, 1)
        [HDR] _InnerColor("Inner Color", Color) = (0.08, 0.55, 1.20, 1)
        _BaseAlpha("Base Transparency", Range(0, 1)) = 0.16
        _CenterAlpha("Center Alpha", Range(0, 1)) = 0.08
        _OverallBrightness("Overall Brightness", Range(0, 5)) = 1

        [Header(Cartoon Rim)]
        [HDR] _RimColor("Rim Color", Color) = (0.35, 1.40, 2.40, 1)
        _RimWidth("Rim Width", Range(0.01, 1)) = 0.28
        _RimSoftness("Rim Softness", Range(0.001, 0.3)) = 0.035
        _RimIntensity("Rim Intensity", Range(0, 10)) = 2.4
        _RimAlpha("Rim Alpha", Range(0, 1)) = 0.70
        _ToonSteps("Rim Toon Steps", Range(1, 12)) = 4

        [Header(Edge Wave)]
        _EdgeWaveScale("Edge Wave Scale", Range(0.1, 20)) = 6
        _EdgeWaveSpeed("Edge Wave Speed", Range(-5, 5)) = 1.2
        _EdgeWaveStrength("Edge Wave Strength", Range(0, 0.3)) = 0.08
        _EdgeWaveSharpness("Edge Wave Sharpness", Range(0.5, 8)) = 2.5
        _EdgeWaveFlicker("Edge Wave Flicker", Range(0, 1)) = 0.25

        [Header(Animated Energy Rings)]
        [HDR] _RingColor("Ring Color", Color) = (0.20, 1.10, 2.20, 1)
        _RingCount("Ring Count", Range(0.25, 12)) = 2.2
        _RingWidth("Ring Width", Range(0.002, 0.25)) = 0.045
        _RingSoftness("Ring Softness", Range(0.001, 0.2)) = 0.025
        _RingSpeed("Ring Speed", Range(-5, 5)) = 0.35
        _RingOffset("Ring Offset", Range(-2, 2)) = 0
        _RingDistortion("Ring Distortion", Range(0, 1)) = 0.16
        _RingIntensity("Ring Intensity", Range(0, 10)) = 1.8
        _RingAlpha("Ring Alpha", Range(0, 1)) = 0.45
        _ObjectRadius("Sphere Local Radius", Float) = 0.5

        [Header(Procedural Motion)]
        _NoiseScale("Noise Scale", Range(0.1, 20)) = 3.5
        _NoiseSpeed("Noise Speed", Range(-5, 5)) = 0.6
        _NoiseStrength("Rim Noise Strength", Range(0, 1)) = 0.18
        _InnerNoiseIntensity("Inner Energy Intensity", Range(0, 3)) = 0.22
        _PulseSpeed("Pulse Speed", Range(0, 10)) = 1.7
        _PulseAmount("Pulse Amount", Range(0, 1)) = 0.12

        [Header(Vertex Wobble)]
        _VertexWaveAmount("Vertex Wave Amount", Range(0, 0.1)) = 0.012
        _VertexWaveScale("Vertex Wave Scale", Range(0.1, 20)) = 4.5
        _VertexWaveSpeed("Vertex Wave Speed", Range(-5, 5)) = 0.9

        [Header(Soft Intersection)]
        [Toggle] _UseDepthIntersection("Use Depth Intersection", Float) = 1
        [HDR] _IntersectionColor("Intersection Color", Color) = (0.25, 1.50, 2.60, 1)
        _IntersectionDistance("Intersection Distance", Range(0.001, 1)) = 0.12
        _IntersectionIntensity("Intersection Intensity", Range(0, 10)) = 2.0
        _IntersectionAlpha("Intersection Alpha", Range(0, 1)) = 0.5

        [Header(Rendering)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "EnergySphere"
            Tags { "LightMode" = "UniversalForward" }

            Blend One OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float3 positionOS : TEXCOORD2;
                float4 screenPos  : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _InnerColor;
                float _BaseAlpha;
                float _CenterAlpha;
                float _OverallBrightness;

                half4 _RimColor;
                float _RimWidth;
                float _RimSoftness;
                float _RimIntensity;
                float _RimAlpha;
                float _ToonSteps;

                float _EdgeWaveScale;
                float _EdgeWaveSpeed;
                float _EdgeWaveStrength;
                float _EdgeWaveSharpness;
                float _EdgeWaveFlicker;

                half4 _RingColor;
                float _RingCount;
                float _RingWidth;
                float _RingSoftness;
                float _RingSpeed;
                float _RingOffset;
                float _RingDistortion;
                float _RingIntensity;
                float _RingAlpha;
                float _ObjectRadius;

                float _NoiseScale;
                float _NoiseSpeed;
                float _NoiseStrength;
                float _InnerNoiseIntensity;
                float _PulseSpeed;
                float _PulseAmount;

                float _VertexWaveAmount;
                float _VertexWaveScale;
                float _VertexWaveSpeed;

                float _UseDepthIntersection;
                half4 _IntersectionColor;
                float _IntersectionDistance;
                float _IntersectionIntensity;
                float _IntersectionAlpha;

                float _Cull;
            CBUFFER_END

            float ProceduralEnergyNoise(float3 positionWS)
            {
                float3 p = positionWS * _NoiseScale;
                float t = _Time.y * _NoiseSpeed;

                float n1 = sin(p.x * 1.73 + p.y * 2.11 + t);
                float n2 = sin(p.z * 2.37 - p.y * 1.19 - t * 1.31);
                float n3 = sin((p.x + p.z) * 1.41 + t * 0.73);

                return saturate(0.5 + (n1 + n2 + n3) / 6.0);
            }

            float EdgeWaveNoise(float3 positionOS)
            {
                float3 dir = normalize(positionOS);
                float t = _Time.y * _EdgeWaveSpeed;

                float w1 = sin(dir.x * _EdgeWaveScale * 2.1 + t);
                float w2 = sin(dir.y * _EdgeWaveScale * 2.7 - t * 1.3);
                float w3 = sin(dir.z * _EdgeWaveScale * 1.8 + t * 0.8);
                float w4 = sin((dir.x + dir.z) * _EdgeWaveScale * 1.5 - t * 1.1);

                float wave = (w1 + w2 + w3 + w4) * 0.25;
                wave = sign(wave) * pow(abs(wave), _EdgeWaveSharpness);
                return wave;
            }

            float VertexWave(float3 positionOS)
            {
                float3 dir = normalize(positionOS);
                float t = _Time.y * _VertexWaveSpeed;

                float w =
                    sin(dir.x * _VertexWaveScale * 2.0 + t) +
                    sin(dir.y * _VertexWaveScale * 2.4 - t * 1.2) +
                    sin(dir.z * _VertexWaveScale * 1.7 + t * 0.9);

                return w / 3.0;
            }

            float QuantizeToon(float value, float steps)
            {
                value = saturate(value);
                if (steps < 1.5)
                    return value;

                return floor(value * steps + 0.0001) / steps;
            }

            float CalculateIntersection(float4 screenPos, float3 positionWS)
            {
                if (_UseDepthIntersection < 0.5)
                    return 0.0;

                float2 screenUV = screenPos.xy / max(screenPos.w, 0.00001);
                float rawSceneDepth = SampleSceneDepth(screenUV);
                float sceneEyeDepth = LinearEyeDepth(rawSceneDepth, _ZBufferParams);
                float fragmentEyeDepth = -TransformWorldToView(positionWS).z;

                float depthDifference = max(sceneEyeDepth - fragmentEyeDepth, 0.0);
                return saturate(1.0 - depthDifference / max(_IntersectionDistance, 0.00001));
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;

                float wave = VertexWave(input.positionOS.xyz);
                float3 displacedOS = input.positionOS.xyz + input.normalOS * wave * _VertexWaveAmount;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(displacedOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.positionOS = displacedOS;
                output.screenPos = ComputeScreenPos(positionInputs.positionCS);

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 normalWS = SafeNormalize(input.normalWS);
                float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);

                float viewNormal = saturate(abs(dot(normalWS, viewDirectionWS)));
                float rimCoordinate = 1.0 - viewNormal;

                float edgeWave = EdgeWaveNoise(input.positionOS);
                float edgeMask = smoothstep(0.55, 1.0, rimCoordinate);
                float distortedRimCoordinate = rimCoordinate + edgeWave * _EdgeWaveStrength * edgeMask;

                float rimThreshold = 1.0 - _RimWidth;
                float rim = smoothstep(
                    rimThreshold - _RimSoftness,
                    rimThreshold + _RimSoftness,
                    distortedRimCoordinate
                );

                float edgeFlicker = 1.0 + edgeWave * _EdgeWaveFlicker * edgeMask;
                rim = saturate(rim * edgeFlicker);

                float noise = ProceduralEnergyNoise(input.positionWS);
                float rimNoise = 1.0 + (noise * 2.0 - 1.0) * _NoiseStrength;
                rim = saturate(rim * rimNoise);
                rim = QuantizeToon(rim, _ToonSteps);

                float radius = max(abs(_ObjectRadius), 0.0001);
                float normalizedHeight = clamp(input.positionOS.y / radius, -1.0, 1.0);

                float ringPhase =
                    (normalizedHeight * 0.5 + 0.5) * _RingCount +
                    _Time.y * _RingSpeed +
                    _RingOffset +
                    (noise * 2.0 - 1.0) * _RingDistortion;

                float ringDistance = abs(frac(ringPhase) - 0.5);
                float ring = 1.0 - smoothstep(
                    _RingWidth,
                    _RingWidth + _RingSoftness,
                    ringDistance
                );

                float poleFade = 1.0 - smoothstep(0.78, 1.0, abs(normalizedHeight));
                ring *= poleFade;
                ring *= 1.0 + edgeWave * 0.15 * edgeMask;
                ring = saturate(ring);

                float pulse = lerp(
                    1.0,
                    0.5 + 0.5 * sin(_Time.y * _PulseSpeed),
                    _PulseAmount
                );

                float intersection = CalculateIntersection(input.screenPos, input.positionWS);

                float centerMask = pow(viewNormal, 1.5);
                float innerNoise = saturate((noise - 0.35) * 1.55) * centerMask * _InnerNoiseIntensity;

                float bodyAlpha = _BaseAlpha + centerMask * _CenterAlpha;

                float alpha = saturate(
                    bodyAlpha +
                    rim * _RimAlpha +
                    ring * _RingAlpha +
                    intersection * _IntersectionAlpha
                );

                float3 bodyColor = lerp(_InnerColor.rgb, _BaseColor.rgb, centerMask);

                float3 bodyContribution = bodyColor * bodyAlpha;
                float3 rimContribution = _RimColor.rgb * rim * _RimIntensity * pulse;
                float3 ringContribution = _RingColor.rgb * ring * _RingIntensity * pulse;
                float3 intersectionContribution = _IntersectionColor.rgb * intersection * _IntersectionIntensity;
                float3 innerContribution = _InnerColor.rgb * innerNoise * pulse;

                float3 finalColor = (
                    bodyContribution +
                    rimContribution +
                    ringContribution +
                    intersectionContribution +
                    innerContribution
                ) * _OverallBrightness;

                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }

    FallBack Off
}
