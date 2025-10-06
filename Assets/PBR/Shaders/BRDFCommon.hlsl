float DistributionGGX(float3 NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

float GeometrySchlickGGX(float cosTheta, float roughness) {
    float nom = cosTheta;
    
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float denom = cosTheta * (1.0 - k) + k;
    return (nom / denom + 1e-5f);
}

float GeometrySmith(float NdotV, float NdotL, float roughness) {
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

float3 FresnelTerm(float3 F0, float cosA) {
    half t = pow(1.0 - cosA, 5.0);
    return F0 + (1.0 - F0) * t;
}

float3 DirectPBR(float nl, float nv, float nh, float hv, float3 albedo, float metalness, float roughness, float3 f0, float3 lightColor) {
    float dTerm = DistributionGGX(nh, roughness);
    float gTerm = GeometrySmith(nl, nv, roughness);
    float3 fTerm = FresnelTerm(f0, hv);

    //0.001是为了避免除0
    float3 specular = dTerm * gTerm * fTerm / (4.0 * max(nv * nl, 0.001));
    //我们按照能量守恒的关系，首先计算镜面反射部分，它的值等于入射光线被反射的能量所占的百分比
    float3 kS = fTerm;
    //然后折射光部分就可以直接由镜面反射部分计算得出
    float3 kD = 1.0 - kS;
    //金属材质没有漫反射, 所以kD要乘以(1-metalness)
    kD *= 1.0 - metalness;
    //除pi是为了能量守恒，但Unity也没有除pi，应该是觉得除pi后太暗，所以我们也先不除
    float3 diffuse = kD * albedo; // *INV_PI;
    float3 Lo = (diffuse + specular) * nl * lightColor;

    return Lo;
}