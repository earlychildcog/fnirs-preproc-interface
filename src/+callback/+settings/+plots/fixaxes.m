function fixaxes(obj, event, guinirs)



if obj.Value == obj.Max
    set([squeeze(guinirs.guiSteps.lines(1,1,:)).Parent], 'YLimMode','manual');
else
    set([squeeze(guinirs.guiSteps.lines(1,1,:)).Parent], 'YLimMode','auto');
end

end