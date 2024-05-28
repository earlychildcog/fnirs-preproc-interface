function deselectAll(obj, event, guinirs)
arrayfun(@(ln)set(ln, 'Color', [ln.Color 0.2]),guinirs.guiLayout.linesChannels)
pause(0.00001) % increases rendering speed a lot in my macbook

guinirs.channelsToPlot = [];
guinirs.guiLayout.link(:,4) = 0;
guinirs.guiSteps.updateVisible;
pause(0.00001)





arrayfun(@(ln)toggleuserselected(ln,0),guinirs.guiLayout.linesChannels)
arrayfun(@(ln)toggleuserselected(ln,0),guinirs.guiSteps.lines)

end

function toggleuserselected(lnObj, value)
lnObj.UserData.selected = value;
end
