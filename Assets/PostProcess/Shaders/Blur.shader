Shader "Custom/Blur" {
    Properties {
        _MainTex("基础贴图", 2D) = "white" {}
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "BlurFunction.hlsl"
    ENDHLSL
    
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Cull Off
        ZWrite Off
        ZTest Always
        
        //0
        Pass {
            Name "GaussianBlur"
            HLSLPROGRAM
            #pragma vertex GaussianBlurVert
            #pragma fragment GaussianBlurFrag
            ENDHLSL
        }

        //1
        Pass {
            Name "GaussianBlurHorizontal"
            HLSLPROGRAM
            #pragma vertex GaussianBlurHorizontalVert
            #pragma fragment GaussianBlurHorizontalFrag
            ENDHLSL
        }
        
        //2
        Pass {
            Name "GaussianBlurVertical"
            HLSLPROGRAM
            #pragma vertex GaussianBlurVerticalVert
            #pragma fragment GaussianBlurVerticalFrag
            ENDHLSL
        }
        
        //3
        Pass {
            Name "KawaseBlur"
            HLSLPROGRAM
            #pragma vertex KawaseBlurVert
            #pragma fragment KawaseBlurFrag
            ENDHLSL
        }
        
        //4
        Pass {
            Name "DualBlurDownSample"
            HLSLPROGRAM
            #pragma vertex DualBlurDownVert
            #pragma fragment DualBlurDownFrag
            ENDHLSL
        }

        //5
        Pass {
            Name "DualBlurUpSample"
            HLSLPROGRAM
            #pragma vertex DualBlurUpVert
            #pragma fragment DualBlurUpFrag
            ENDHLSL
        }
    }
}