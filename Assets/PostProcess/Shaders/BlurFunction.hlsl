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

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainTex_TexelSize;

float _BlurRange;
float _RTDownSampling;

float blurRange;
float blurRange_x;
float blurRange_y;


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

v2f_DualBlurUp DualBlurUpVert(appdata v) {
    v2f_DualBlurUp o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    
    float2 offset = (1 + _BlurRange) * _MainTex_TexelSize.xy * 0.5;
    o.uv[0] = v.uv + float2(-1, -1) * offset;
    o.uv[1] = v.uv + float2(-1,  1) * offset;
    o.uv[2] = v.uv + float2(1,  -1) * offset;
    o.uv[3] = v.uv + float2(1,   1) * offset;
    o.uv[4] = v.uv + float2(-2,  0) * offset;
    o.uv[5] = v.uv + float2(0,  -2) * offset;
    o.uv[6] = v.uv + float2(2,   0) * offset;
    o.uv[7] = v.uv + float2(0,   2) * offset;

    return o;
}

float4 DualBlurUpFrag(v2f_DualBlurUp i): SV_TARGET {
    float4 col = 0;

    col += tex2D(_MainTex, i.uv[0]) * 2;
    col += tex2D(_MainTex, i.uv[1]) * 2;
    col += tex2D(_MainTex, i.uv[2]) * 2;
    col += tex2D(_MainTex, i.uv[3]) * 2;
    col += tex2D(_MainTex, i.uv[4]);
    col += tex2D(_MainTex, i.uv[5]);
    col += tex2D(_MainTex, i.uv[6]);
    col += tex2D(_MainTex, i.uv[7]);

    return col * 0.0833;
}