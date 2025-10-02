Shader "Custom/Bloom" {
    Properties {
        _MainTex("Base(RGB)", 2D) = "white" {}
        _LuminanceThreshold("Luminance Threshold", Float) = 1.0
        _BlurRange("Blur Range", Float) = 1.0
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "BlurFunction.hlsl"
    #include "BloomFunction.hlsl"
    ENDHLSL
    
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Cull Off
        ZWrite Off
        ZTest Always
        
        Pass {
            Name "BloomExtract"
            HLSLPROGRAM
            #pragma vertex ExtractBrightVert
            #pragma fragment ExtractBrightFrag
            ENDHLSL
        }
        
        Pass {
            Name "BloomCombine"
            HLSLPROGRAM
            #pragma vertex BloomCombineVert
            #pragma fragment BloomCombineFrag
            ENDHLSL
        }
    }
}
