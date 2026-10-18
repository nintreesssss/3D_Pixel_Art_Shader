Shader "Custom/StylizedMagicRuneAtlas"
{
    Properties
    {
        [Header(Rune Texture and Atlas)]
        [MainTexture] _RuneTex ("Rune Mask Or Atlas", 2D) = "white" {}
        [Toggle] _UseAlpha ("Use Texture Alpha", Float) = 1
        [Toggle] _InvertMask ("Invert Mask", Float) = 0
        _Threshold ("Mask Threshold", Range(0, 1)) = 0.5
        _Softness ("Mask Softness", Range(0.001, 0.25)) = 0.03
        _Contrast ("Mask Contrast", Range(0.25, 8)) = 3.0

        [Header(Atlas Sampling)]
        [Toggle] _UseAtlas ("Use Atlas", Float) = 1
        _AtlasCols ("Atlas Columns", Range(1, 16)) = 4
        _AtlasRows ("Atlas Rows", Range(1, 16)) = 4
        _RuneIndex ("Rune Index", Range(0, 255)) = 0
        _CellPadding ("Cell Padding", Range(0, 0.45)) = 0.06
        _RuneScaleInCell ("Rune Scale In Cell", Range(0.2, 1.5)) = 0.92

        [Header(Color And Glow)]
        [HDR] _RuneColor ("Rune Color", Color) = (0.10, 0.75, 1.00, 1.0)
        [HDR] _FlowColor ("Flow Highlight Color", Color) = (0.75, 1.00, 1.00, 1.0)
        _Brightness ("Brightness", Range(0, 12)) = 3.0
        _Opacity ("Opacity", Range(0, 1)) = 1.0
        _HaloWidth ("Halo Width UV", Range(0, 0.08)) = 0.012
        _HaloStrength ("Halo Strength", Range(0, 8)) = 1.5

        [Header(Pulse)]
        _PulseSpeed ("Pulse Speed", Range(0, 10)) = 1.2
        _PulseAmount ("Pulse Amount", Range(0, 1)) = 0.25

        [Header(Flow Sweep)]
        _FlowSpeed ("Flow Speed", Range(-5, 5)) = 0.35
        _FlowWidth ("Flow Width", Range(0.01, 0.5)) = 0.12
        _FlowStrength ("Flow Strength", Range(0, 8)) = 1.6
        _FlowAngle ("Flow Angle", Range(-180, 180)) = 20

        [Header(Organic Distortion)]
        _DistortStrength ("Distortion Strength", Range(0, 0.08)) = 0.006
        _DistortScale ("Distortion Scale", Range(0.1, 30)) = 7.0
        _DistortSpeed ("Distortion Speed", Range(-5, 5)) = 0.35
        _UVScroll ("UV Scroll XY", Vector) = (0, 0, 0, 0)

        [Header(Flicker)]
        _FlickerAmount ("Flicker Amount", Range(0, 1)) = 0.08
        _FlickerSpeed ("Flicker Speed", Range(0, 30)) = 7.0

        [Header(Hover)]
        _HoverDistance ("Hover Distance", Range(0, 0.05)) = 0.002
        _HoverSpeed ("Hover Speed", Range(0, 10)) = 0.8
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
            Name "RuneUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Blend One One
            ZWrite Off
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_RuneTex);
            SAMPLER(sampler_RuneTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _RuneTex_ST;
                float4 _RuneColor;
                float4 _FlowColor;
                float4 _UVScroll;

                float _UseAlpha;
                float _InvertMask;
                float _Threshold;
                float _Softness;
                float _Contrast;

                float _UseAtlas;
                float _AtlasCols;
                float _AtlasRows;
                float _RuneIndex;
                float _CellPadding;
                float _RuneScaleInCell;

                float _Brightness;
                float _Opacity;
                float _HaloWidth;
                float _HaloStrength;

                float _PulseSpeed;
                float _PulseAmount;

                float _FlowSpeed;
                float _FlowWidth;
                float _FlowStrength;
                float _FlowAngle;

                float _DistortStrength;
                float _DistortScale;
                float _DistortSpeed;

                float _FlickerAmount;
                float _FlickerSpeed;

                float _HoverDistance;
                float _HoverSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);

                float a = Hash21(i);
                float b = Hash21(i + float2(1.0, 0.0));
                float c = Hash21(i + float2(0.0, 1.0));
                float d = Hash21(i + float2(1.0, 1.0));

                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float2 GetSampleUV(float2 meshUV)
            {
                float2 uv = meshUV;

                if (_UseAtlas > 0.5)
                {
                    float cols = max(1.0, round(_AtlasCols));
                    float rows = max(1.0, round(_AtlasRows));
                    float maxIndex = cols * rows - 1.0;
                    float idx = clamp(floor(_RuneIndex + 0.5), 0.0, maxIndex);

                    float col = fmod(idx, cols);
                    float rowFromTop = floor(idx / cols);
                    float row = rows - 1.0 - rowFromTop;

                    float2 cellUV = meshUV - 0.5;
                    cellUV /= max(_RuneScaleInCell, 0.0001);
                    cellUV += 0.5;
                    cellUV = lerp(_CellPadding.xx, (1.0 - _CellPadding).xx, cellUV);
                    cellUV = saturate(cellUV);

                    uv = (float2(col, row) + cellUV) / float2(cols, rows);
                }

                return uv;
            }

            float SampleRuneMask(float2 uv)
            {
                float4 tex = SAMPLE_TEXTURE2D(_RuneTex, sampler_RuneTex, uv);
                float luminance = dot(tex.rgb, float3(0.299, 0.587, 0.114));
                float mask = lerp(luminance, tex.a, saturate(_UseAlpha));
                mask = lerp(mask, 1.0 - mask, saturate(_InvertMask));
                mask = saturate((mask - 0.5) * _Contrast + 0.5);
                return mask;
            }

            float SmoothMask(float rawMask)
            {
                float softness = max(_Softness, 0.0001);
                return smoothstep(_Threshold - softness, _Threshold + softness, rawMask);
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                float3 positionOS = IN.positionOS.xyz;
                float3 normalOS = normalize(IN.normalOS);

                float hover = sin(_Time.y * _HoverSpeed * 6.2831853) * _HoverDistance;
                positionOS += normalOS * hover;

                OUT.positionCS = TransformObjectToHClip(positionOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _RuneTex);
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float t = _Time.y;
                float2 baseUV = IN.uv + _UVScroll.xy * t;

                float2 noiseUV = baseUV * _DistortScale;
                noiseUV += float2(t * _DistortSpeed, -t * _DistortSpeed * 0.73);
                float n1 = ValueNoise(noiseUV);
                float n2 = ValueNoise(noiseUV + float2(17.17, 41.73));
                baseUV += (float2(n1, n2) - 0.5) * 2.0 * _DistortStrength;

                float2 uv = GetSampleUV(baseUV);

                float raw = SampleRuneMask(uv);
                float core = SmoothMask(raw);

                float w = _HaloWidth;
                float outerRaw = raw;
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2( w,  0))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2(-w,  0))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2( 0,  w))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2( 0, -w))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2( w,  w))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2(-w,  w))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2( w, -w))));
                outerRaw = max(outerRaw, SampleRuneMask(GetSampleUV(baseUV + float2(-w, -w))));

                float outer = SmoothMask(outerRaw);
                float halo = saturate(outer - core);

                float pulseWave = 0.5 + 0.5 * sin(t * _PulseSpeed * 6.2831853);
                float pulse = lerp(1.0, 0.65 + 0.70 * pulseWave, _PulseAmount);

                float flickerWave = 0.5 + 0.5 * (
                    sin(t * _FlickerSpeed * 1.73 + 0.7) *
                    sin(t * _FlickerSpeed * 0.91 + 2.1)
                );
                float flicker = lerp(1.0, lerp(0.82, 1.08, flickerWave), _FlickerAmount);

                float angle = radians(_FlowAngle);
                float2 flowDir = float2(cos(angle), sin(angle));
                float coord = dot(IN.uv - 0.5, flowDir) + 0.5;
                float sweepPos = frac(t * _FlowSpeed);
                float sweepDist = abs(frac(coord - sweepPos + 0.5) - 0.5);
                float flow = 1.0 - smoothstep(_FlowWidth * 0.55, _FlowWidth, sweepDist);
                flow *= core;

                float3 baseGlow = _RuneColor.rgb * core;
                float3 haloGlow = _RuneColor.rgb * halo * _HaloStrength;
                float3 flowGlow = _FlowColor.rgb * flow * _FlowStrength;

                float3 rgb = (baseGlow + haloGlow + flowGlow) * _Brightness;
                rgb *= pulse * flicker * _Opacity;

                float alpha = saturate((core + halo * _HaloStrength) * _Opacity);
                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }

    FallBack Off
}
