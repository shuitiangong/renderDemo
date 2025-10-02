using System;
using UnityEngine.Rendering;

namespace PostProcess.Runtime.Volume {
    [Serializable]
    public enum BlurType {
        GaussianBlur = 0,
        GaussianBlur_Fast = 1,
        KawaseBlur = 2,
        DualBlur = 3
    }
    
    public class BlurVolume : VolumeComponent {
        public BoolParameter IsEnabled = new BoolParameter(false);
        public BlurType blurType = BlurType.GaussianBlur;
        public IntParameter BlurTimes = new ClampedIntParameter(1, 0, 10);
        public FloatParameter BlurRange = new ClampedFloatParameter(1.0f, 0.0f, 10.0f);
        public IntParameter RTDownSampling = new ClampedIntParameter(1, 1, 4);
        public IntParameter BlurAlgorithm = new IntParameter((int)BlurType.GaussianBlur);
    }
}