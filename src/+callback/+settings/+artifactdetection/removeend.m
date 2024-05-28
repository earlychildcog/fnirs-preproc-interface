function removeend(obj, event, guinirs)

% if zoom is on, disable it
if get(zoom,'Enable')
    guinirs.disablezoom;
end

% arrayfun(@(ln)set(), guinirs.guiSteps.lines_cut(2,:))

