using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SocialPlatforms;

namespace PostProcess.Runtime.Volume {
    public class BloomVolume : VolumeComponent {
        public BoolParameter IsEnabled = new BoolParameter(false);
        [Range(0, 10)]
        public IntParameter iterations = new IntParameter(3);
        [Range(0.2f, 3.0f)]
        public FloatParameter blurSpread = new FloatParameter(0.6f);
        [Range(1, 8)]
        public IntParameter downSample = new IntParameter(2);
        [Range(0.0f, 4.0f)]
        public FloatParameter luminanceThreshold = new FloatParameter(1.0f);
    }
}
