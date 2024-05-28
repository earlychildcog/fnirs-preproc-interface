function step = stepConstructor()

step = struct;

k = 1;
step(k).name = 'check channels';
step(k).function = @hmrR_PruneChannels;
step(k).input.dRange = [0.01 10^7];
step(k).input.SNRthresh = 1;
step(k).input.SDrange = [0 50];


k = k + 1;
step(k).name = 'raw2dod';
step(k).function = @hmrR_Intensity2OD;

k = k + 1;
step(k).name = 'pass filter 1';
step(k).function = @hmrR_BandpassFilt;
step(k).input.hpf = 0;
step(k).input.lpf = 0;

k = k + 1;
step(k).name = 'artifact detection (spline)';
step(k).function = @hmrR_MotionArtifactByChannel;
step(k).input.tMotion = 0;
step(k).input.tMask = 0;
step(k).input.STDEVthresh = 13.5;
step(k).input.AMPthresh = 0.4;

k = k + 1;
step(k).name = 'spline';
step(k).function = @hmrR_MotionCorrectSpline;
step(k).input.p = 0.99;

k = k + 1;
step(k).name = 'pass filter 2';
step(k).function = @hmrR_BandpassFilt;
step(k).input.hpf = 0;
step(k).input.lpf = 0;

k = k + 1;
step(k).name = 'wavelet';
step(k).function = @hmrR_MotionCorrectWavelet;
step(k).input.iqr = -1.5;


k = k + 1;
step(k).name = 'pass filter 3';
step(k).function = @hmrR_BandpassFilt;
step(k).input.hpf = 0;
step(k).input.lpf = 0;



k = k + 1;
step(k).name = 'artifact detection';
step(k).function = @hmrR_MotionArtifact;
step(k).input.tMotion = 0; 
step(k).input.tMask = 0; 
step(k).input.STDEVthresh = 20; 
step(k).input.AMPthresh = 1;


k = k + 1;
step(k).name = 'artifact detection - channels';
step(k).function = @hmrR_MotionArtifactByChannel;
step(k).input.tMotion = 0;
step(k).input.tMask = 0;
step(k).input.STDEVthresh = 13.5;
step(k).input.AMPthresh = 0.4;

k = k + 1;
step(k).name = 'OD2Conc';
step(k).function = @hmrR_OD2Conc;
step(k).input.ppf = [5.1 5.1];














