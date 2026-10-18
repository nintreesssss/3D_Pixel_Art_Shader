using UnityEngine;
using UnityEngine.Rendering.Universal;

/// <summary>
/// Generates a moving stylized cloud mask from a Perlin/noise texture and feeds it
/// to a URP Directional Light as a realtime light cookie.
///
/// Unity 6 / URP.
/// </summary>
[ExecuteAlways]
[DisallowMultipleComponent]
public class StylizedCloudShadowController : MonoBehaviour
{
    [Header("Required")]
    [Tooltip("Your main/sun Directional Light.")]
    public Light targetDirectionalLight;

    [Tooltip("Your tileable grayscale Perlin/noise texture.")]
    public Texture2D perlinNoise;

    [Tooltip("Assign Custom/StylizedCloudCookieGenerator. If empty, the script tries Shader.Find().")]
    public Shader generatorShader;

    [Header("Cookie")]
    [Range(128, 2048)]
    public int cookieResolution = 512;

    [Tooltip("World-space size of one directional-light cookie tile.")]
    public Vector2 cookieWorldSize = new Vector2(55f, 55f);

    [Tooltip("World-space offset of the directional-light cookie.")]
    public Vector2 cookieOffset = Vector2.zero;

    [Header("Cloud Shape")]
    [Min(0.001f)] public float primaryScale = 1.15f;
    [Min(0.001f)] public float secondaryScale = 2.35f;

    [Range(0f, 1f)]
    public float secondaryBlend = 0.35f;

    [Range(0f, 0.5f)]
    public float warpStrength = 0.10f;

    [Range(0f, 1f)]
    public float threshold = 0.52f;

    [Range(0.001f, 0.35f)]
    public float edgeSoftness = 0.075f;

    [Range(0.25f, 4f)]
    public float contrast = 1.15f;

    public bool invertNoise = false;

    [Header("Cloud Motion")]
    [Tooltip("UV movement per second. Keep these values small.")]
    public Vector2 primarySpeed = new Vector2(0.015f, 0.008f);

    [Tooltip("Second layer should usually move in a different direction.")]
    public Vector2 secondarySpeed = new Vector2(-0.008f, 0.012f);

    [Header("Gather / Scatter")]
    [Tooltip("How much the cloud coverage slowly expands and breaks apart.")]
    [Range(0f, 0.35f)]
    public float gatherScatterAmount = 0.09f;

    [Tooltip("Cycles per second. 0.04 = one gather/scatter cycle about every 25 seconds.")]
    [Range(0f, 1f)]
    public float gatherScatterSpeed = 0.04f;

    [Header("Lighting")]
    [Tooltip("0 = no cloud shadow, 1 = nearly black cloud shadow. For stylized scenes 0.3-0.55 is a good range.")]
    [Range(0f, 0.95f)]
    public float shadowStrength = 0.45f;

    [Header("Preview")]
    [Tooltip("Also update the cookie while not in Play Mode.")]
    public bool previewInEditMode = true;

    private Material _generatorMaterial;
    private RenderTexture _cookieTexture;
    private int _currentResolution;

    private Light _cachedLight;
    private Texture _previousCookie;
    private Vector2 _previousCookieSize;
    private Vector2 _previousCookieOffset;

    private static readonly int NoiseTexID = Shader.PropertyToID("_NoiseTex");
    private static readonly int ScaleAID = Shader.PropertyToID("_ScaleA");
    private static readonly int ScaleBID = Shader.PropertyToID("_ScaleB");
    private static readonly int SpeedAID = Shader.PropertyToID("_SpeedA");
    private static readonly int SpeedBID = Shader.PropertyToID("_SpeedB");
    private static readonly int SecondaryBlendID = Shader.PropertyToID("_SecondaryBlend");
    private static readonly int WarpStrengthID = Shader.PropertyToID("_WarpStrength");
    private static readonly int ThresholdID = Shader.PropertyToID("_Threshold");
    private static readonly int SoftnessID = Shader.PropertyToID("_Softness");
    private static readonly int ContrastID = Shader.PropertyToID("_Contrast");
    private static readonly int InvertNoiseID = Shader.PropertyToID("_InvertNoise");
    private static readonly int DissolveAmountID = Shader.PropertyToID("_DissolveAmount");
    private static readonly int DissolveSpeedID = Shader.PropertyToID("_DissolveSpeed");
    private static readonly int ShadowStrengthID = Shader.PropertyToID("_ShadowStrength");
    private static readonly int CloudTimeID = Shader.PropertyToID("_CloudTime");

    private void OnEnable()
    {
        EnsureLightCache();
        EnsureResources();
        RenderCookie();
    }

    private void Update()
    {
        if (!Application.isPlaying && !previewInEditMode)
            return;

        EnsureLightCache();
        EnsureResources();
        RenderCookie();
    }

    private void OnValidate()
    {
        cookieResolution = Mathf.Clamp(cookieResolution, 128, 2048);
        cookieWorldSize.x = Mathf.Max(0.01f, cookieWorldSize.x);
        cookieWorldSize.y = Mathf.Max(0.01f, cookieWorldSize.y);
        primaryScale = Mathf.Max(0.001f, primaryScale);
        secondaryScale = Mathf.Max(0.001f, secondaryScale);

        // Resources are recreated lazily on the next editor/play Update.
    }

    private void EnsureLightCache()
    {
        if (_cachedLight == targetDirectionalLight)
            return;

        RestorePreviousLight();
        _cachedLight = targetDirectionalLight;

        if (_cachedLight == null)
            return;

        _previousCookie = _cachedLight.cookie;

        UniversalAdditionalLightData additionalData = _cachedLight.GetUniversalAdditionalLightData();
        _previousCookieSize = additionalData.lightCookieSize;
        _previousCookieOffset = additionalData.lightCookieOffset;
    }

    private void EnsureResources()
    {
        if (generatorShader == null)
            generatorShader = Shader.Find("Custom/StylizedCloudCookieGenerator");

        if (generatorShader != null && (_generatorMaterial == null || _generatorMaterial.shader != generatorShader))
        {
            DestroyObject(_generatorMaterial);
            _generatorMaterial = new Material(generatorShader)
            {
                name = "Stylized Cloud Cookie Generator (Runtime)",
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        if (_cookieTexture == null || _currentResolution != cookieResolution)
        {
            DestroyCookieTexture();

            _cookieTexture = new RenderTexture(
                cookieResolution,
                cookieResolution,
                0,
                RenderTextureFormat.ARGB32,
                RenderTextureReadWrite.Linear)
            {
                name = "Stylized Cloud Cookie (Runtime)",
                wrapMode = TextureWrapMode.Repeat,
                filterMode = FilterMode.Bilinear,
                useMipMap = false,
                autoGenerateMips = false,
                hideFlags = HideFlags.HideAndDontSave
            };

            _cookieTexture.Create();
            _currentResolution = cookieResolution;
        }
    }

    private void RenderCookie()
    {
        if (targetDirectionalLight == null ||
            targetDirectionalLight.type != LightType.Directional ||
            perlinNoise == null ||
            _generatorMaterial == null ||
            _cookieTexture == null)
        {
            return;
        }

        _generatorMaterial.SetTexture(NoiseTexID, perlinNoise);
        _generatorMaterial.SetFloat(ScaleAID, primaryScale);
        _generatorMaterial.SetFloat(ScaleBID, secondaryScale);
        _generatorMaterial.SetVector(SpeedAID, new Vector4(primarySpeed.x, primarySpeed.y, 0f, 0f));
        _generatorMaterial.SetVector(SpeedBID, new Vector4(secondarySpeed.x, secondarySpeed.y, 0f, 0f));
        _generatorMaterial.SetFloat(SecondaryBlendID, secondaryBlend);
        _generatorMaterial.SetFloat(WarpStrengthID, warpStrength);
        _generatorMaterial.SetFloat(ThresholdID, threshold);
        _generatorMaterial.SetFloat(SoftnessID, edgeSoftness);
        _generatorMaterial.SetFloat(ContrastID, contrast);
        _generatorMaterial.SetFloat(InvertNoiseID, invertNoise ? 1f : 0f);
        _generatorMaterial.SetFloat(DissolveAmountID, gatherScatterAmount);
        _generatorMaterial.SetFloat(DissolveSpeedID, gatherScatterSpeed);
        _generatorMaterial.SetFloat(ShadowStrengthID, shadowStrength);

        // realtimeSinceStartup also changes in Edit Mode, so Scene View can preview the motion.
        _generatorMaterial.SetFloat(CloudTimeID, Time.realtimeSinceStartup);

        Graphics.Blit(Texture2D.whiteTexture, _cookieTexture, _generatorMaterial, 0);

        targetDirectionalLight.cookie = _cookieTexture;

        UniversalAdditionalLightData additionalData = targetDirectionalLight.GetUniversalAdditionalLightData();
        additionalData.lightCookieSize = cookieWorldSize;
        additionalData.lightCookieOffset = cookieOffset;
    }

    private void OnDisable()
    {
        RestorePreviousLight();
        DestroyCookieTexture();
        DestroyObject(_generatorMaterial);
        _generatorMaterial = null;
    }

    private void RestorePreviousLight()
    {
        if (_cachedLight == null)
            return;

        // Restore only if this component is still driving the cookie.
        if (_cachedLight.cookie == _cookieTexture)
            _cachedLight.cookie = _previousCookie;

        UniversalAdditionalLightData additionalData = _cachedLight.GetUniversalAdditionalLightData();
        additionalData.lightCookieSize = _previousCookieSize;
        additionalData.lightCookieOffset = _previousCookieOffset;

        _cachedLight = null;
    }

    private void DestroyCookieTexture()
    {
        if (_cookieTexture == null)
            return;

        if (_cookieTexture.IsCreated())
            _cookieTexture.Release();

        DestroyObject(_cookieTexture);
        _cookieTexture = null;
        _currentResolution = 0;
    }

    private static void DestroyObject(Object obj)
    {
        if (obj == null)
            return;

        if (Application.isPlaying)
            Object.Destroy(obj);
        else
            Object.DestroyImmediate(obj);
    }
}
