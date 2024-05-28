classdef nirsLayout
    properties
        parent          
        link           table % s-d pairs
        posSrc
        posDet
    end
    methods
        function obj = nirsLayout(parent)
            if nargin > 0
                obj.parent = parent;
                obj.posDet = obj.parent.probe.detectorPos2D;
                obj.posSrc = obj.parent.probe.sourcePos2D;
                obj.link = obj.getlinkdefault;
            end
        end
        function link = getlinkdefault(obj)
            if ~isempty(obj.parent.data)
                mTable = obj.parent.data(1).mTable;
            else
                mTable = tableFromMeaslist(obj.parent.acquired.data.measurementList);
            end
            link = mTable(mTable.type == mTable.type(1), ["source" "detector" "id"]);
            link.incl = ones(size(link,1),1);
        end
        function link = getLinkFromMlActAuto(~, mlActTable)
            mlActTable = array2table(int32(mlActTable{1}),'VariableNames',["source" "detector" "incl" "type"]);
            mlActTable.id = arrayfun(@(x,y)int32(sum(mlActTable.source < x) + sum(mlActTable.source == x & mlActTable.detector < y)),mlActTable.source, mlActTable.detector)/max(mlActTable.type)+1;

            if any(mlActTable.type ~= mlActTable.type(1))
                mlActTable = varfun(@all, mlActTable, InputVariables="incl", GroupingVariables=["source" "detector" "id"]);
                mlActTable.GroupCount = [];
                mlActTable.Properties.VariableNames(end) = "incl";
            end
            link = mlActTable;
        end

    end
end