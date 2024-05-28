function togglechannelinclusion(obj, event, guinirs)
pause(0.01)
if event.Indices(2) < 4
    obj.Data(event.Indices(1), end) = 1 - obj.Data(event.Indices(1), end);
    callback.settings.channels.updateinclcolumn(obj,event,guinirs)
    % pause(0.1)
    jUIScrollPane = findjobj(obj);
    jUITable = jUIScrollPane.getViewport.getView;
    jUITable.changeSelection(event.Indices(1),4, false, false);
else
    % disp(1)
end
end