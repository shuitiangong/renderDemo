using PostProcess.Runtime.Volume;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PostProcess.Runtime.Passes {
    public class BlurRenderPass : ScriptableRenderPass {
        private string _renderTag = "Blur Effects";
        private Material _blurMaterial;
        private int[] _downSampleRT;
        private int[] _upSampleRT;
        private RenderTargetIdentifier _curRenderTarget;
        private RenderTextureDescriptor _curDescriptor;
        private readonly int _tempTarget1ID = Shader.PropertyToID("_TempBlurBuffer1");
        private readonly int _tempTarget2ID = Shader.PropertyToID("_TempBlurBuffer2");
        private readonly int _blurRange = Shader.PropertyToID("_BlurRange");
        private BlurVolume _blurVolume;
        
        public BlurRenderPass(RenderPassEvent evt, Shader shader) {
            renderPassEvent = evt;
            if (shader == null) {
                Debug.LogError("Blur Shader is null.");
                return;
            }
            _blurMaterial = CoreUtils.CreateEngineMaterial(shader.name);  
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
            if (_blurMaterial == null) {
                Debug.LogError("Blur Material is null.");
                return; 
            }
            
            var stack = VolumeManager.instance.stack;
            _blurVolume = stack.GetComponent<PostProcess.Runtime.Volume.BlurVolume>();
            if (_blurVolume == null || !_blurVolume.active) {
                if (_blurVolume == null) {
                    Debug.LogError("Blur Volume is null.");    
                }
                return;
            }
            
            if (!_blurVolume.IsEnabled.value) return;
            var cmd = CommandBufferPool.Get(_renderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        private void Render(CommandBuffer cmd, ref RenderingData renderingData) {
            ref var cameraData = ref renderingData.cameraData;
            var source = _curRenderTarget;
            int itTimes = _blurVolume.BlurTimes.value;
            int downSample = _blurVolume.RTDownSampling.value;
            int width = this._curDescriptor.width / downSample;
            int height = this._curDescriptor.height / downSample;

            BlurType algorithm = (BlurType)_blurVolume.BlurAlgorithm.value;

            if (algorithm == BlurType.GaussianBlur) {
                int destination = _tempTarget1ID;
                cmd.GetTemporaryRT(destination, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

                _blurMaterial.SetFloat(_blurRange, _blurVolume.BlurRange.value);
                for (int i = 0; i < _blurVolume.BlurTimes.value; ++i) {
                    cmd.Blit(source, destination, _blurMaterial, 0);
                    cmd.Blit(destination, source, _blurMaterial, 0);
                }
            }
            else if (algorithm == BlurType.GaussianBlur_Fast) {
                int destination = _tempTarget1ID;
                cmd.GetTemporaryRT(destination, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                
                _blurMaterial.SetFloat(_blurRange, _blurVolume.BlurRange.value);
                for (int i = 0; i < _blurVolume.BlurTimes.value; ++i) {
                    cmd.Blit(source, destination, _blurMaterial, 1);
                    cmd.Blit(destination, source, _blurMaterial, 2);
                }
                cmd.ReleaseTemporaryRT(destination);
            }
            else if (algorithm == BlurType.KawaseBlur) {
                int destination1 = _tempTarget1ID;
                cmd.GetTemporaryRT(destination1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                int destination2 = _tempTarget2ID;
                cmd.GetTemporaryRT(destination2, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                
                bool swap = false;
                int GetFrontID() => swap ? destination2 : destination1;
                int GetBackID() => swap ? destination1 : destination2;
                cmd.Blit(source, GetFrontID());

                for (int i = 0; i < itTimes; ++i) {
                    _blurMaterial.SetFloat(_blurRange, 1.0f*i + _blurVolume.BlurRange.value);
                    cmd.Blit(GetFrontID(), GetBackID(), _blurMaterial, 3);
                    swap = !swap;
                }
                _blurMaterial.SetFloat(_blurRange, 1.0f*itTimes + _blurVolume.BlurRange.value);
                cmd.Blit(GetBackID(), source, _blurMaterial, 3);      
                cmd.ReleaseTemporaryRT(destination1);
                cmd.ReleaseTemporaryRT(destination2);
            }
            else if (algorithm == BlurType.DualBlur) {
                int destination = _tempTarget1ID;
                cmd.GetTemporaryRT(destination, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                _blurMaterial.SetFloat(_blurRange, _blurVolume.BlurRange.value);

                cmd.Blit(source, destination);
                
                _downSampleRT = new int[itTimes];
                _upSampleRT = new int[itTimes];
                int tw = width;
                int th = height;
                
                for (int i = 0; i < itTimes; ++i) {
                    _downSampleRT[i] = Shader.PropertyToID("_DownSample" + i);
                    _upSampleRT[i] = Shader.PropertyToID("_UpSample" + i);
                    
                    cmd.GetTemporaryRT(_downSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                    cmd.GetTemporaryRT(_upSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                    tw = Mathf.Max(tw >> 1, 1);
                    th = Mathf.Max(th >> 1, 1);
                    cmd.Blit(destination, _downSampleRT[i], _blurMaterial, 4);
                    destination = _downSampleRT[i];
                }
                
                for (int i = itTimes-1; i >= 0; --i) {
                    cmd.Blit(destination, _upSampleRT[i], _blurMaterial, 5);
                    destination = _upSampleRT[i];
                }
                
                cmd.Blit(destination, source);
                
                for (int i = 0; i < itTimes; ++i) {
                    cmd.ReleaseTemporaryRT(_downSampleRT[i]);
                    cmd.ReleaseTemporaryRT(_upSampleRT[i]);
                }
                cmd.ReleaseTemporaryRT(_tempTarget1ID);
            }
        }
    }
}