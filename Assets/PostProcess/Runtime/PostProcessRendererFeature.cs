using System;
using PostProcess.Runtime.Passes;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

namespace PostProcess.Runtime {
    public class PostProcessRendererFeature : ScriptableRendererFeature {
        [Serializable]
        public class Settings {
            public Shader blurShader;
            public Shader bloomShader;
        }
        public Settings settings;
        
        private BlurRenderPass _blurRenderPass;
        private BloomRenderPass _bloomRenderPass;
        
        public override void Create() {
            this.name = "PostProcess Renderer Feature";
            _blurRenderPass = new BlurRenderPass(RenderPassEvent.BeforeRenderingPostProcessing, settings.blurShader);
            _bloomRenderPass = new BloomRenderPass(RenderPassEvent.AfterRenderingPostProcessing, settings.blurShader, settings.bloomShader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
            _blurRenderPass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(_blurRenderPass);
            _bloomRenderPass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(_bloomRenderPass);
        }
    }
}