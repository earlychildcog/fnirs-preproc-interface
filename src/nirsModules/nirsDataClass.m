classdef nirsDataClass
    properties
        dataTimeSeries      double
        time                double
        measurementList     MeasListClass
        mTable              table % to replace measurementList eventually
        tInc
        tIncCh
    end
    methods
        function obj = nirsDataClass(dataClassHomer, tInc, tIncCh)
            arguments
                dataClassHomer DataClass = DataClass
                tInc = []
                tIncCh = []
            end
            obj.dataTimeSeries = single(dataClassHomer.dataTimeSeries);
            obj.time = single(dataClassHomer.time);
            obj.measurementList = dataClassHomer.measurementList;
            obj.mTable = tableFromMeaslist(dataClassHomer.measurementList);
            obj.tInc = tInc;
            obj.tIncCh = tIncCh;
            obj = obj.downsample_(1);
            % remove hbt if dc
            if ~isempty(obj.measurementList) && startsWith(obj.measurementList(1).dataTypeLabel, 'Hb','IgnoreCase',true)
                hbt = strcmpi({obj.measurementList.dataTypeLabel}, 'HbT');
                obj.measurementList(hbt) = [];
                obj.dataTimeSeries(:,hbt) = [];
                obj.mTable(hbt,:) = [];
            end
        end
        function obj = downsample_(obj, fs_new)
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
            
            if ~isempty(obj.tInc), obj.tInc = downsample(obj.tInc, ds_factor); end
            if ~isempty(obj.tIncCh), obj.tIncCh = downsample(obj.tIncCh, ds_factor); end
        end
    end
end