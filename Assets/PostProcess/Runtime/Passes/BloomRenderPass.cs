using GlobalSnowEffect;
using PostProcess.Runtime.Volume;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PostProcess.Runtime.Passes {
    public class BloomRenderPass : ScriptableRenderPass {
        private string _renderTag = "Bloom Effects";
        private Material _bloomMaterial;
        private Material _blurMaterial;
        private Material _postMaterial;
        private RenderTargetIdentifier _curRenderTarget;
        private RenderTextureDescriptor _curDescriptor;
        private BloomVolume _bloomVolume;
        private readonly int _luminanceThreshold = Shader.PropertyToID("_LuminanceThreshold");
        private readonly int _blurRange = Shader.PropertyToID("_BlurRange");
        private readonly int _blurTex = Shader.PropertyToID("_Bloom");
        private readonly int _addTex = Shader.PropertyToID("_AddTex");
        private readonly int _uberTex = Shader.PropertyToID("_UberTex");
        private int[] _downSampleRT;
        private int[] _upSampleRT;
        
        public BloomRenderPass(RenderPassEvent evt, Shader blurShader, Shader bloomShader) {
            renderPassEvent = evt;
            if (blurShader == null || bloomShader == null) {
                Debug.LogError("Blur Shader Or Bloom Shader is null.");
                return;
            }
            _bloomMaterial = CoreUtils.CreateEngineMaterial(bloomShader);
            _blurMaterial = CoreUtils.CreateEngineMaterial(blurShader);
            _postMaterial = CoreUtils.CreateEngineMaterial("Shaders/post");
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
            _bloomMaterial.SetFloat(_luminanceThreshold, _bloomVolume.luminanceThreshold.value);
            int iterations = _bloomVolume.iterations.value;
            float blurRange = _bloomVolume.blurSpread.value;

            _downSampleRT = new int[iterations];
            _upSampleRT = new int[iterations];
            _bloomMaterial.SetFloat(_blurRange, blurRange);
            
            int tw = this._curDescriptor.width / downSample;
            int th = this._curDescriptor.height / downSample;
            for (int i = 0; i < iterations; ++i) {
                _downSampleRT[i] = Shader.PropertyToID("_DownSample" + i);
                _upSampleRT[i] = Shader.PropertyToID("_UpSample" + i);
                    
                cmd.GetTemporaryRT(_downSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBFloat);
                cmd.GetTemporaryRT(_upSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBFloat);
                tw = Mathf.Max(tw >> 1, 1);
                th = Mathf.Max(th >> 1, 1);
            }
            //亮度提取
            cmd.Blit(source, _downSampleRT[0], _bloomMaterial, 6);
            //下采样
            for (int i = 1; i < iterations; ++i) {
                cmd.Blit(_downSampleRT[i-1], _downSampleRT[i], _bloomMaterial, 6);
            }
            //上采样
            cmd.Blit(_downSampleRT[iterations-1], _upSampleRT[iterations-2], _bloomMaterial, 6);
            for (int i = iterations-3; i >= 0; --i) {
                cmd.SetGlobalTexture(_addTex, _downSampleRT[i+1]);
                cmd.Blit(_upSampleRT[i+1], _upSampleRT[i], _bloomMaterial, 7);
            }
            //
            // cmd.SetGlobalTexture(_addTex,_downSampleRT[iterations-1]);
            // cmd.Blit(_downSampleRT[iterations-2], _upSampleRT[iterations-2], _bloomMaterial, 8);
            //
            // for (int i = iterations-3; i >= 0; --i) {
            //     cmd.SetGlobalTexture(_addTex, _upSampleRT[i+1]);
            //     cmd.Blit(_downSampleRT[i], _upSampleRT[i], _bloomMaterial, 8);
            // }
            
            //叠加原图
            cmd.GetTemporaryRT(_uberTex, this._curDescriptor.width, this._curDescriptor.height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBFloat);
            cmd.SetGlobalTexture(_blurTex, _upSampleRT[0]);
            //_uberTex主要是为了降采样不影响原图质量
            cmd.Blit(source, _uberTex, _bloomMaterial, 1);
            //Blit回去
            cmd.Blit(_uberTex, source);
            
            for (int i = 0; i < iterations; ++i) {
                cmd.ReleaseTemporaryRT(_downSampleRT[i]);
                cmd.ReleaseTemporaryRT(_upSampleRT[i]);
            }
            cmd.ReleaseTemporaryRT(_uberTex);
        }
    }
}
