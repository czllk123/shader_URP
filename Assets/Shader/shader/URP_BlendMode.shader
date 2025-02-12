Shader "URP/BlendMode" //Shader路径名
{
    Properties //材质面板参数
    {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc ("混合源乘子", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst ("混合目标乘子", int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("混合算符", int) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent" // 调整渲染顺序
            "RenderType"="Transparent" // 对应改为Cutout
            "ForceNoShadowCasting"="True" // 关闭阴影投射
            "IgnoreProjector"="True" // 不响应投射器
        }
        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="UniversalForward"
            }
            BlendOp [_BlendOp] // 可自定义混合算符
            Blend [_BlendSrc] [_BlendDst] // 可自定义混合模式

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial) //缓冲区
            uniform float4 _MainTex_ST;
            uniform half _Opacity;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // 输入结构
            struct VertexInput
            {
                float4 vertex : POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
            };

            // 输出结构
            struct VertexOutput
            {
                float4 pos : SV_POSITION; // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0; // UV信息 采样贴图用
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex); // 顶点位置 OS>CS
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex); // UV信息 支持TilingOffset
                return o;
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0); // 采样贴图 RGB颜色 A透贴不必须
                half3 finalRGB = var_MainTex.rgb;
                half opacity = var_MainTex.a * _Opacity;
                return half4(finalRGB * opacity, opacity); // 返回值
            }
            ENDHLSL
        }
    }
}