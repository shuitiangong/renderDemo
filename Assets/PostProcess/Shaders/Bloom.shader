Shader "Custom/Bloom" {
    Properties {
        _MainTex("Base(RGB)", 2D) = "white" {}
        _LuminanceThreshold("Luminance Threshold", Float) = 1.0
        _BlurRange("Blur Range", Float) = 1.0
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "BloomFunction.hlsl"
    ENDHLSL
    
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Cull Off
        ZWrite Off
        ZTest Always
        
        //0
        Pass {
            Name "BloomExtract"
            HLSLPROGRAM
            #pragma vertex ExtractBrightVert
            #pragma fragment ExtractBrightFrag
            ENDHLSL
        }
        
        //1
        Pass {
            Name "BloomCombine"
            HLSLPROGRAM
            #pragma vertex BloomCombineVert
            #pragma fragment BloomCombineFrag
            ENDHLSL
        }

        //2
        Pass {
            Name "GaussianBlur"
            HLSLPROGRAM
            #pragma vertex GaussianBlurVert
            #pragma fragment GaussianBlurFrag
            ENDHLSL
        }

        //3
        Pass {
            Name "GaussianBlurHorizontal"
            HLSLPROGRAM
            #pragma vertex GaussianBlurHorizontalVert
            #pragma fragment GaussianBlurHorizontalFrag
            ENDHLSL
        }
        
        //4
        Pass {
            Name "GaussianBlurVertical"
            HLSLPROGRAM
            #pragma vertex GaussianBlurVerticalVert
            #pragma fragment GaussianBlurVerticalFrag
            ENDHLSL
        }
        
        //5
        Pass {
            Name "KawaseBlur"
            HLSLPROGRAM
            #pragma vertex KawaseBlurVert
            #pragma fragment KawaseBlurFrag
            ENDHLSL
        }
        
        //6
        Pass {
            Name "DualBlurDownSample"
            HLSLPROGRAM
            #pragma vertex DualBlurDownVert
            #pragma fragment DualBlurDownFrag
            ENDHLSL
        }

        //7
        Pass {
            Name "DualBlurUpSample"
            HLSLPROGRAM
            #pragma vertex DualBlurUpVert
            #pragma fragment DualBlurUpFrag
            ENDHLSL
        }

        //8
        Pass {
            Name "GaussianBlurUp"
            HLSLPROGRAM
            #pragma vertex GaussianBlurUpVert
            #pragma fragment GaussianBlurUpFrag
            ENDHLSL
        }

    }
}
