function acquired = prestepRun(acquired)
% here you can put code to be executed during the FIRST loading of the ORIGINAL snirf files
% you can remove markers you are not interested in, shorten the recording, make fixes etc
% that you would not want to do on your snirf files

%% fix layout
thresslow = -200;
advance = 160;
acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) = acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) + advance;
acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) = acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) + advance;
acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) = acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) + advance;
acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) = acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) + advance;

%% downsample
fs_new = 10;
acquired.data = downsample_(acquired.data);
acquired.aux = arrayfun(@downsample_, acquired.aux);

    function obj = downsample_(obj)
        % Calculate current sampling rate and downsampling factor
        current_fs = 1 / mean(diff(obj.time));
        ds_factor = round(current_fs / fs_new);

        if current_fs <= fs_new + 0.01
            fprintf('No downsampling needed (%.1f Hz <= %.1f Hz)\n', current_fs, fs_new);
            return;
        end

        fprintf('Downsampling from %.1f to %.1f Hz (factor %d)\n', current_fs, current_fs/ds_factor, ds_factor);

        % Downsample all data
        obj.dataTimeSeries = downsample(obj.dataTimeSeries, ds_factor);
        obj.time = downsample(obj.time, ds_factor);

        if (isfield(obj, 'tInc') || isprop(obj, 'tInc')) && ~isempty(obj.tInc), obj.tInc = downsample(obj.tInc, ds_factor); end
        if (isfield(obj, 'tIncCh') || isprop(obj, 'tIncCh')) && ~isempty(obj.tIncCh), obj.tIncCh = downsample(obj.tIncCh, ds_factor); end
    end
end