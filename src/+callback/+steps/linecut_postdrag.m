function linecut_postdrag(obj)

guinirs = obj.UserData;
pos = obj.Value;
id = find(strcmp(obj.Tag, {'cut_beg' 'cut_end'}),1);
if isempty(id)
    error('error dragging object')
end

% move lines in the other tabs
set(guinirs.guiSteps.lines_cut(id, :), 'value', pos)
guinirs.meta.accepted_time_range(id) = pos;
end