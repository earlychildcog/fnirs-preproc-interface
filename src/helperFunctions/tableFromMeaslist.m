function M = tableFromMeaslist(meas)

source = [meas.sourceIndex]';
detector = [meas.detectorIndex]';
if isempty(meas(1).dataTypeLabel) && (meas(1).wavelengthIndex ~= 0)
    type = [meas.wavelengthIndex]';
    typeLabel = "w" + type;
    % datatype = "raw";
elseif ~isempty(meas(1).dataTypeLabel) && (meas(1).wavelengthIndex ~= 0)
    type = [meas.wavelengthIndex]';
    typeLabel = string({meas.dataTypeLabel}') + type;
    % datatype = "dod";
else
    typeLabel = string({meas.dataTypeLabel}');
    type = strcmpi(typeLabel,"hbo") + 2*strcmpi(typeLabel,"hbr") + 3*strcmpi(typeLabel,"hbt");
    % datatype = "dc";
end
M = table(source,detector,type,typeLabel);
M.id = arrayfun(@(x,y)int32(sum(M.source < x) + sum(M.source == x & M.detector < y)),M.source, M.detector)/max(type)+1;
% [M, I] = sortrows(M);
% M.id = ceil(int32(1:size(M,1))'/max(type));
% M = M(I,:);
end