using GlobalSnowEffect;
using PostProcess.Runtime.Volume;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.XR;

namespace PostProcess.Runtime.Passes {
    public class BloomRenderPass : ScriptableRenderPass {
        private string _renderTag = "Bloom Effects";
        private Material _bloomMaterial;
        private Material _blurMaterial;
        private RenderTargetIdentifier _curRenderTarget;
        private RenderTextureDescriptor _curDescriptor;
        private BloomVolume _bloomVolume;
        private readonly int _luminanceThreshold = Shader.PropertyToID("_LuminanceThreshold");
        private readonly int _blurRange = Shader.PropertyToID("_BlurRange");
        private readonly int _blurTex = Shader.PropertyToID("_Bloom");
        private bool _swap = false;
        private readonly int _tempTargetID1 = Shader.PropertyToID("_TempBloomBuffer1");
        private readonly int _tempTargetID2 = Shader.PropertyToID("_TempBloomBuffer2");
        private void Swap() => _swap = !_swap;
        private RenderTargetIdentifier GetFrontBuffer() => _swap ? _tempTargetID2 : _tempTargetID1;
        private RenderTargetIdentifier GetBackBuffer() => _swap ? _tempTargetID1 : _tempTargetID2;
        
        public BloomRenderPass(RenderPassEvent evt, Shader blurShader, Shader bloomShader) {
            renderPassEvent = evt;
            if (blurShader == null || bloomShader == null) {
                Debug.LogError("Blur Shader Or Bloom Shader is null.");
                return;
            }
            _bloomMaterial = CoreUtils.CreateEngineMaterial(bloomShader);
            _blurMaterial = CoreUtils.CreateEngineMaterial(blurShader);
        }
        
        public void Setup(in RenderTargetIdentifier currentTarget) {
            this._curRenderTarget = currentTarget;
        }
        
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor) {
            base.Configure(cmd, cameraTextureDescriptor);
            this._curDescriptor = cameraTextureDescriptor;
            this._curDescriptor.depthBufferBits = 0;
            this._curDescriptor.msaaSamples = 1;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
            var stack = VolumeManager.instance.stack;
            _bloomVolume = stack.GetComponent<PostProcess.Runtime.Volume.BloomVolume>();
            if (_bloomVolume == null || !_bloomVolume.active) {
                if (_bloomVolume == null) {
                    Debug.LogError("Bloom Volume is null.");
                }
            }
            if (!_bloomVolume.IsEnabled.value) return;
            var cmd = CommandBufferPool.Get(_renderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        private void Render(CommandBuffer cmd, ref RenderingData renderingData) {
            RenderTargetIdentifier source = this._curRenderTarget;
            int downSample = _bloomVolume.downSample.value;
            int tw = this._curDescriptor.width / downSample;
            int th = this._curDescriptor.height / downSample;
            cmd.GetTemporaryRT(_tempTargetID1, tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
            cmd.GetTemporaryRT(_tempTargetID2, tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
            _bloomMaterial.SetFloat(_luminanceThreshold, _bloomVolume.luminanceThreshold.value);
            int iterations = _bloomVolume.iterations.value;
            float blurRange = _bloomVolume.blurSpread.value;
            
            //亮度提取
            cmd.Blit(source, GetFrontBuffer(), _bloomMaterial, 0);
            //模糊
            for (int i = 0; i < iterations; ++i) {
                _blurMaterial.SetFloat(_blurRange, 1.0f + i * blurRange);
                cmd.Blit(GetFrontBuffer(), GetBackBuffer(), _blurMaterial, 0);
                Swap();
            }
            
            //将模糊后的图像和原图叠加在一起
            cmd.SetGlobalTexture(_blurTex, GetBackBuffer());
            cmd.Blit(source, GetFrontBuffer(), _bloomMaterial, 1);
            //Blit回去
            cmd.Blit(GetFrontBuffer(), source);
            cmd.ReleaseTemporaryRT(_tempTargetID1);
            cmd.ReleaseTemporaryRT(_tempTargetID2);
        }
    }
}
