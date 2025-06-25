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
            % remove hbt if dc
            if ~isempty(obj.measurementList) && startsWith(obj.measurementList(1).dataTypeLabel, 'Hb','IgnoreCase',true)
                hbt = strcmpi({obj.measurementList.dataTypeLabel}, 'HbT');
                obj.measurementList(hbt) = [];
                obj.dataTimeSeries(:,hbt) = [];
                obj.mTable(hbt,:) = [];
            end
        end
    end
end