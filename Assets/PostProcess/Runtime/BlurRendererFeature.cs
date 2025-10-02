using System;
using PostProcess.Runtime.Passes;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace PostProcess.Runtime {
    public class BlurRendererFeature : ScriptableRendererFeature {
        [Serializable]
        public class Settings {
            public Shader Shader;
        }
        public Settings settings;
        
        private BlurRenderPass _blurRenderPass;
        
        public override void Create() {
            this.name = "Blur Renderer Feature";
            _blurRenderPass = new BlurRenderPass(RenderPassEvent.BeforeRenderingPostProcessing, settings.Shader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
            _blurRenderPass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(_blurRenderPass);
        }
    }
}