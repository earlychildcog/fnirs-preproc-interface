function stepRun(guinirs, iStep, current_only)
arguments
    guinirs
    iStep = 1           % step to start from --experimental
    current_only = false
end

steps = guinirs.steps;
acquired = guinirs.acquired;
assert(~isempty(acquired.data) || iStep > 1, "where is the data")
probe = guinirs.probe;

turnon = 1;

mlActMan = [];
tIncMan = [];

% mlActAuto{1} = ones(size(acquired.data.time));
mlActAuto = [];
data = acquired.data;
data = trim_data(data, guinirs.meta.accepted_time_range);       % trim data if applicable

% tInc = {ones(size(acquired.data.time))};
% tInc0 = {ones(size(acquired.data.time))};
while iStep <= length(steps)
    % hmrR_PruneChannels
    if iStep == 1
        mlActAuto0 = hmrR_PruneChannels(data, probe, mlActMan, tIncMan, steps(iStep).input.dRange, steps(iStep).input.SNRthresh, steps(iStep).input.SDrange);
        guinirs.layout.link = guinirs.layout.getLinkFromMlActAuto(mlActAuto0);
        guinirs.addProc(data, iStep, steps(iStep).name);
        mlActAuto = [];     % we do not want homer functions to take the result of automatic channel detection too seriously for now

        % hmrR_Intensity2OD
    elseif iStep == 2
        data = hmrR_Intensity2OD(data);
        guinirs.addProc(data, iStep, steps(iStep).name);

        % hmrR_BandpassFilt

    elseif iStep == 3
        data = hmrR_BandpassFilt(data, steps(iStep).input.hpf, steps(iStep).input.lpf);
        guinirs.addProc(data, iStep, steps(iStep).name);

        % hmrR_MotionArtifactByChannel
    elseif iStep == 4
        [~, tIncAutoCh] = hmrR_MotionArtifactByChannel(data, probe, mlActMan, mlActAuto, tIncMan, steps(iStep).input.tMotion, steps(iStep).input.tMask, steps(iStep).input.STDEVthresh, steps(iStep).input.AMPthresh);
        guinirs.addProc(data, iStep, steps(iStep).name, tIncAutoCh = tIncAutoCh);

        % hmrR_MotionCorrectSpline
    elseif iStep == 5
        data = hmrR_MotionCorrectSpline(data, mlActAuto, tIncAutoCh, steps(iStep).input.p, turnon);
        guinirs.addProc(data, iStep, steps(iStep).name, tIncAutoCh = tIncAutoCh);

        % high pass
    elseif iStep == 6
        data = hmrR_BandpassFilt(data, steps(iStep).input.hpf, steps(iStep).input.lpf);
        guinirs.addProc(data, iStep, steps(iStep).name);

        % hmrR_MotionCorrectWavelet
    elseif iStep == 7
        tic
        [~] = evalc('data =  hmrR_MotionCorrectWavelet_parallel(data, mlActMan, mlActAuto, steps(iStep).input.iqr, turnon);');
        toc
        guinirs.addProc(data, iStep, steps(iStep).name);

        % hmrR_BandpassFilt
    elseif iStep == 8
        data = hmrR_BandpassFilt(data, steps(iStep).input.hpf, steps(iStep).input.lpf);
        guinirs.addProc(data, iStep, steps(iStep).name);

    %     % hmrR_MotionArtifact
    % elseif iStep == 9
    %     if exist('mlActAuto0','var')
    %         mlActAuto_ = mlActAuto0;
    %     else
    %         mlActAuto_ = mlActAuto;
    %     end
    %     tIncAuto = hmrR_MotionArtifact(data, probe, mlActMan, mlActAuto_, tIncMan, steps(iStep).input.tMotion, steps(iStep).input.tMask, steps(iStep).input.STDEVthresh, steps(iStep).input.AMPthresh);
    %     guinirs.addProc(data, iStep, steps(iStep).name, tIncAuto = tIncAuto);
    %     guinirs.exclusions.auto.tIncAuto = tIncAuto;
    % 
    %     % hmrR_MotionArtifactByChannel
    % elseif iStep == 10
    %     [~ ,tIncAutoCh] = hmrR_MotionArtifactByChannel(data,probe,mlActMan,mlActAuto,tIncMan, steps(iStep).input.tMotion, steps(iStep).input.tMask, steps(iStep).input.STDEVthresh, steps(iStep).input.AMPthresh);
    %     guinirs.addProc(data, iStep, steps(iStep).name, tIncAutoCh = tIncAutoCh);
    % 
        % hmrR_OD2Conc
    elseif iStep == 9
        data = hmrR_OD2Conc(data, probe, steps(iStep).input.ppf);
        guinirs.addProc(data, iStep, steps(iStep).name);
    end

    iStep = iStep + 1;
    if current_only     % experimental
        guinirs.data(iStep:end) = guinirsDataClass; % remove data processing for the next
        break
    end
end


guinirs.flagComputed = true;
guinirs.subjTable.processed(guinirs.subjTable.filename == string(guinirs.filename)) = true;
