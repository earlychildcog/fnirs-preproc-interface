classdef nirsMeta
    % collecting some metadata like artifacts etc
    properties
        parent
        accepted_time_range = [0 Inf]    
        stim        StimClass
        included            string {mustBeMember(included,["na" "rejected" "ambiguous" "accepted"])} = "na"
    end
    methods
        function obj = nirsMeta(parent)
            obj.parent = parent;
        end
    end
end