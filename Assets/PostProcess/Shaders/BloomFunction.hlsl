sampler2D _Bloom;
float4 _Bloom_ST;

float _LuminanceThreshold;

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
    
    return color * val;
}

v2f_Bloom BloomCombineVert(appdata v) {
    v2f_Bloom o;
    o.pos = TransformObjectToHClip(v.vertex.xyz);
    o.uv = v.uv;
    return o;
}

float4 BloomCombineFrag(v2f_Bloom i) : SV_Target {
    float4 original = tex2D(_MainTex, i.uv);
    float4 bloom = tex2D(_Bloom, i.uv);
    return original + bloom;
}
