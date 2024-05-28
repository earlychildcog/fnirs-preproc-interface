function remove(obj, event, guinirs)
guinirs.meta.stim(obj.UserData(1)).data(obj.UserData(2), :) = [];
if isempty(guinirs.meta.stim(obj.UserData(1)).data)
    guinirs.meta.stim(obj.UserData(1)) = [];
end
guinirs.guiSteps.updateStim
end