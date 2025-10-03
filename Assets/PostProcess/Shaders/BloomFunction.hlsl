sampler2D _Bloom;
sampler2D _AddTex;

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainTex_TexelSize;


float _LuminanceThreshold;
float _BlurRange;
float _RTDownSampling;


struct appdata {
    float4 vertex: POSITION;
    float2 uv: TEXCOORD0;
};

struct v2f_GaussianBlur {
    float4 vertex: SV_POSITION;
    float2 uv[9]: TEXCOORD0;
};

struct v2f_DualGaussianBlur {
    float4 vertex: SV_POSITION;
    float2 uv[3]: TEXCOORD0;
};

struct v2f_KawaseBlur {
    float4 vertex: SV_POSITION;
    float2 uv[4]: TEXCOORD0;
};

struct v2f_DualBlurDown {
    float4 vertex: POSITION;
    float2 uv[5]: TEXCOORD0;
};

struct v2f_DualBlurUp {
    float4 vertex: SV_POSITION;
    float2 uv[8]: TEXCOORD0;
};

struct v2f_Bloom {
    float4 pos: POSITION;
    float2 uv: TEXCOORD0;
};

float4 luminance(float4 color) {
    return 0.2124 * color.r + 0.7154 * color.g + 0.0722 * color.b;
}

v2f_Bloom ExtractBrightVert(appdata v) {
    v2f_Bloom o;
    o.pos = TransformObjectToHClip(v.vertex.xyz);
    o.uv = v.uv;
    return o;
}

float4 ExtractBrightFrag(v2f_Bloom i) : SV_Target {
    float4 color = tex2D(_MainTex, i.uv);
    float lum = luminance(color);
    float val = clamp(lum - _LuminanceThreshold, 0.0, 1.0);

    color.rgb *= val;
    return color;
}

v2f_Bloom BloomCombineVert(appdata v) {
    v2f_Bloom o;
    o.pos = TransformObjectToHClip(v.vertex.xyz);
    o.uv = v.uv;
    return o;
}

float3 ACESToneMapping(float3 color, float adapted_lum)
{
    const float A = 2.51f;
    const float B = 0.03f;
    const float C = 2.43f;
    const float D = 0.59f;
    const float E = 0.14f;

    color *= adapted_lum;
    return (color * (A * color + B)) / (color * (C * color + D) + E);
}

float4 BloomCombineFrag(v2f_Bloom i) : SV_Target {
    float4 original = tex2D(_MainTex, i.uv);
    float3 bloom = tex2D(_Bloom, i.uv) * 0.12f;
    bloom = ACESToneMapping(bloom.rgb, 1.0);
    original.rgb += bloom;
    return original;
}

v2f_GaussianBlur GaussianBlurVert(appdata v) {
    v2f_GaussianBlur o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    o.uv[0] = v.uv;
    o.uv[1] = v.uv + float2(-1,-1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[2] = v.uv + float2(-1, 1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[3] = v.uv + float2(1, -1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[4] = v.uv + float2(1,  1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[5] = v.uv + float2(-1, 0) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[6] = v.uv + float2(0, -1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[7] = v.uv + float2(1,  0) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[8] = v.uv + float2(0,  1) * _MainTex_TexelSize.xy * _BlurRange;

    return o;
}

float4 GaussianBlurFrag(v2f_GaussianBlur i): SV_TARGET {
    float4 col = 0;
    col += tex2D(_MainTex, i.uv[0]) * 0.1478f;
    col += tex2D(_MainTex, i.uv[1]) * 0.0947f;
    col += tex2D(_MainTex, i.uv[2]) * 0.0947f;
    col += tex2D(_MainTex, i.uv[3]) * 0.0947f;
    col += tex2D(_MainTex, i.uv[4]) * 0.0947f;
    col += tex2D(_MainTex, i.uv[5]) * 0.1183f;
    col += tex2D(_MainTex, i.uv[6]) * 0.1183f;
    col += tex2D(_MainTex, i.uv[7]) * 0.1183f;
    col += tex2D(_MainTex, i.uv[8]) * 0.1183f;
    
    return col;
}

v2f_Bloom GaussianBlurUpVert(appdata v) {
    v2f_Bloom o;
    o.pos = TransformObjectToHClip(v.vertex.xyz);
    o.uv = v.uv;

    return o;
}

float4 GaussianBlurUpFrag(v2f_Bloom i): SV_TARGET {
    float4 col = 0;
    float2 offset = _MainTex_TexelSize.xy * _BlurRange;
    
    col += tex2D(_MainTex, i.uv) * 0.1478f;
    col += tex2D(_MainTex, i.uv + float2(-1,-1) * offset) * 0.0947f;
    col += tex2D(_MainTex, i.uv + float2(-1, 1) * offset) * 0.0947f;
    col += tex2D(_MainTex, i.uv + float2(1, -1) * offset) * 0.0947f;
    col += tex2D(_MainTex, i.uv + float2(1, 1) * offset) * 0.0947f;
    col += tex2D(_MainTex, i.uv + float2(-1, 0) * offset) * 0.1183f;
    col += tex2D(_MainTex, i.uv + float2(0, -1) * offset) * 0.1183f;
    col += tex2D(_MainTex, i.uv + float2(1, 0) * offset) * 0.1183f;
    col += tex2D(_MainTex, i.uv + float2(0, 1) * offset) * 0.1183f;
    
    col += tex2D(_AddTex, i.uv);
    return col;
}

v2f_DualGaussianBlur GaussianBlurHorizontalVert(appdata v) {
    v2f_DualGaussianBlur o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    o.uv[0] = v.uv;
    o.uv[1] = v.uv + float2(-1, 0) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[2] = v.uv + float2(1,  0)  * _MainTex_TexelSize.xy * _BlurRange;

    return o;
}

float4 GaussianBlurHorizontalFrag(v2f_DualGaussianBlur i): SV_TARGET {
    float4 col = 0;
    col += tex2D(_MainTex, i.uv[0]) * 0.3078f;
    col += tex2D(_MainTex, i.uv[1]) * 0.3844f;
    col += tex2D(_MainTex, i.uv[2]) * 0.3078f;

    return col;
}

v2f_DualGaussianBlur GaussianBlurVerticalVert(appdata v) {
    v2f_DualGaussianBlur o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    o.uv[0] = v.uv;
    o.uv[1] = v.uv + float2(0, -1) * _MainTex_TexelSize.xy * _BlurRange;
    o.uv[2] = v.uv + float2(0,  1) * _MainTex_TexelSize.xy * _BlurRange;

    return o;
}

float4 GaussianBlurVerticalFrag(v2f_DualGaussianBlur i): SV_TARGET {
    float4 col = 0;
    col += tex2D(_MainTex, i.uv[0]) * 0.3078f;
    col += tex2D(_MainTex, i.uv[1]) * 0.3844f;
    col += tex2D(_MainTex, i.uv[2]) * 0.3078f;

    return col;
}

v2f_KawaseBlur KawaseBlurVert(appdata v) {
    v2f_KawaseBlur o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    float offset = (_BlurRange + 0.5) * 0.1;
    o.uv[0] = v.uv + float2(-offset,-offset) * _MainTex_TexelSize.xy;
    o.uv[1] = v.uv + float2(-offset, offset) * _MainTex_TexelSize.xy;
    o.uv[2] = v.uv + float2(offset, -offset) * _MainTex_TexelSize.xy;
    o.uv[3] = v.uv + float2(offset,  offset) * _MainTex_TexelSize.xy;

    return o;
}

float4 KawaseBlurFrag(v2f_KawaseBlur i): SV_TARGET {
    float4 col = 0;
    col += tex2D(_MainTex, i.uv[0]);
    col += tex2D(_MainTex, i.uv[1]);
    col += tex2D(_MainTex, i.uv[2]);
    col += tex2D(_MainTex, i.uv[3]);
    return col * 0.25f;
}

v2f_DualBlurDown DualBlurDownVert(appdata v) {
    v2f_DualBlurDown o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    
    float2 offset = (1 + _BlurRange) * _MainTex_TexelSize.xy * 0.5;
    o.uv[0] = v.uv;
    o.uv[1] = v.uv + float2(-1, -1) * offset;
    o.uv[2] = v.uv + float2(1,  -1) * offset;
    o.uv[3] = v.uv + float2(-1,  1) * offset;
    o.uv[4] = v.uv + float2(1,   1) * offset;

    return o;
}

float4 DualBlurDownFrag(v2f_DualBlurDown i): SV_TARGET {
    float4 col = 0;

    col += tex2D(_MainTex, i.uv[0]) * 4;
    col += tex2D(_MainTex, i.uv[1]);
    col += tex2D(_MainTex, i.uv[2]);
    col += tex2D(_MainTex, i.uv[3]);
    col += tex2D(_MainTex, i.uv[4]);

    return col * 0.125f;
}

v2f_Bloom DualBlurUpVert(appdata v) {
    v2f_Bloom o;
    o.pos = TransformObjectToHClip(v.vertex.xyz);
    o.uv = v.uv;

    return o;
}

float4 DualBlurUpFrag(v2f_Bloom i): SV_TARGET {
    float4 col = 0;

    float2 offset = (1 + _BlurRange) * _MainTex_TexelSize.xy * 0.5;
    col += tex2D(_MainTex, i.uv + float2(-1, -1) * offset) * 2;
    col += tex2D(_MainTex, i.uv + float2(-1,  1) * offset) * 2;
    col += tex2D(_MainTex, i.uv + float2(1,  -1) * offset) * 2;
    col += tex2D(_MainTex, i.uv + float2(1,  1) * offset) * 2;
    col += tex2D(_MainTex, i.uv + float2(-2,  0) * offset);
    col += tex2D(_MainTex, i.uv + float2(0,  -2) * offset);
    col += tex2D(_MainTex, i.uv + float2(2,  0) * offset);
    col += tex2D(_MainTex, i.uv + float2(0,  2) * offset);
    col *= 0.0833f;
    
    col += tex2D(_AddTex, i.uv);
    return col;
}