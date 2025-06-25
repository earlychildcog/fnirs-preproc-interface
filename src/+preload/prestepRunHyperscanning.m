function acquired = prestepRunHyperscanning(acquired)
% here you can put code to be executed during the FIRST loading of the ORIGINAL snirf files
% you can remove markers you are not interested in, shorten the recording, make fixes etc
% that you would not want to do on your snirf files

%% fix layout
% thresslow = -200;
% advance = 160;
% acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) = acquired.probe.sourcePos2D(acquired.probe.sourcePos2D < thresslow) + advance;
% acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) = acquired.probe.sourcePos3D(acquired.probe.sourcePos3D < thresslow) + advance;
% acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) = acquired.probe.detectorPos2D(acquired.probe.detectorPos2D < thresslow) + advance;
% acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) = acquired.probe.detectorPos3D(acquired.probe.detectorPos3D < thresslow) + advance;
fix_probe(acquired);
%% downsample
fs_new = 10;
acquired.data = downsample_(acquired.data);
acquired.aux = arrayfun(@downsample_, acquired.aux);

%% functions
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

    function fix_probe(S)
        % fix how the array aesthetically looks like

        xDet = S.probe.detectorPos2D(:,1);
        yDet = S.probe.detectorPos2D(:,2);
        xSrc = S.probe.sourcePos2D(:,1);
        ySrc = S.probe.sourcePos2D(:,2);




        % find each part of the cap
        idRightDet = yDet < -200;
        idRightSrc = ySrc < -200;
        idLeftDet = yDet > -30;
        idLeftSrc = ySrc > -30;
        idFrontalDet = ~idLeftDet & ~idRightDet;
        idFrontalSrc = ~idLeftSrc & ~idRightSrc;

        % reflect the right part
        xDet(idRightDet) = -xDet(idRightDet);
        xSrc(idRightSrc) = -xSrc(idRightSrc);
        % rotate the frontals
        xDet(idFrontalDet) = -xDet(idFrontalDet);
        xSrc(idFrontalSrc) = -xSrc(idFrontalSrc);
        yDet(idFrontalDet) = -yDet(idFrontalDet);
        ySrc(idFrontalSrc) = -ySrc(idFrontalSrc);
        % translate
        mov_right_x = -min([xDet(idRightDet); xSrc(idRightSrc)]) +40;
        mov_right_y = -max([yDet(idRightDet); ySrc(idRightSrc)]) -10 -25;
        mov_left_x = -max([yDet(idLeftDet); ySrc(idLeftSrc)]) -40;
        mov_left_y = -max([yDet(idLeftDet); ySrc(idLeftSrc)]) -10;
        mov_frontal_x = -mean([xDet(idFrontalDet); xSrc(idFrontalSrc)]) +0;
        mov_frontal_y = -min([yDet(idFrontalDet); ySrc(idFrontalSrc)]) +10;
        %
        yDet(idRightDet) =  yDet(idRightDet) + mov_right_y;
        ySrc(idRightSrc) =  ySrc(idRightSrc) + mov_right_y;
        xDet(idRightDet) =  xDet(idRightDet) + mov_right_x;
        xSrc(idRightSrc) =  xSrc(idRightSrc) + mov_right_x;
        yDet(idLeftDet) =   yDet(idLeftDet)  + mov_left_y;
        ySrc(idLeftSrc) =   ySrc(idLeftSrc)  + mov_left_y;
        xDet(idLeftDet) =   xDet(idLeftDet)  + mov_left_x;
        xSrc(idLeftSrc) =   xSrc(idLeftSrc)  + mov_left_x;
        yDet(idFrontalDet) = yDet(idFrontalDet) + mov_frontal_y;
        ySrc(idFrontalSrc) = ySrc(idFrontalSrc) + mov_frontal_y;
        xDet(idFrontalDet) = xDet(idFrontalDet) + mov_frontal_x;
        xSrc(idFrontalSrc) = xSrc(idFrontalSrc) + mov_frontal_x;

        % yDet = -yDet;
        % ySrc = -ySrc;
        S.probe.detectorPos2D(:,1) = xDet;
        S.probe.detectorPos2D(:,2) = yDet;
        S.probe.sourcePos2D(:,1) = xSrc;
        S.probe.sourcePos2D(:,2) = ySrc;

        S.probe.detectorPos3D(:,1) = xDet;
        S.probe.detectorPos3D(:,2) = yDet;
        S.probe.sourcePos3D(:,1) = xSrc;
        S.probe.sourcePos3D(:,2) = ySrc;
    end
end